#!/bin/bash
# analyze-git-branch.sh
# Universal git branch analysis tool for cleanup and maintenance workflows
# 
# This tool provides comprehensive analysis of git branches without modifying
# the working directory or making any network requests. It focuses purely on 
# data collection from local git history.
#
# Prerequisites: 
# - Run `git fetch --prune` to ensure remote tracking is up-to-date
# - Tool works offline and makes no network requests
# - Safe to run in any git repository state
#
# Usage: ./analyze-git-branch.sh [options] <branch1> [branch2] [branch3] ...
#        ./analyze-git-branch.sh --all
#
# Options:
#   -p, --project-dir PATH    Git project directory (default: current directory)
#   -t, --target-branch NAME  Target branch (default: auto-detect main/master)
#   -f, --format FORMAT       Output format: json|summary (default: json)
#   -h, --help               Show usage information
#   --all                    Analyze all branches except protected ones

set -euo pipefail

# Default values
PROJECT_DIR="$(pwd)"
TARGET_BRANCH=""
OUTPUT_FORMAT="json"
ANALYZE_ALL=false
BRANCHES=()

# ANSI color codes for summary output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m' 
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Usage information
usage() {
    cat << EOF
analyze-git-branch.sh - Universal git branch analysis tool

USAGE:
    $0 [options] <branch1> [branch2] [branch3] ...
    $0 --all

OPTIONS:
    -p, --project-dir PATH    Git project directory (default: current directory)
    -t, --target-branch NAME  Target branch (default: auto-detect main/master) 
    -f, --format FORMAT       Output format: json|summary (default: json)
    -h, --help               Show this help message
    --all                    Analyze all branches except protected ones

EXAMPLES:
    $0 feature-branch
    $0 -t main feature-1 feature-2 old-work
    $0 --project-dir /path/to/repo --all
    $0 --format summary old-feature

PREREQUISITES:
    - Run 'git fetch --prune' before analysis for accurate remote tracking
    - Tool operates in read-only mode with no network requests
    - Works offline using local git history only

EOF
}

# Logging functions
log_error() {
    echo "ERROR: $1" >&2
}

log_warning() {
    echo "WARNING: $1" >&2
}

log_info() {
    echo "INFO: $1" >&2
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--project-dir)
                PROJECT_DIR="$2"
                shift 2
                ;;
            -t|--target-branch)
                TARGET_BRANCH="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                if [[ "$OUTPUT_FORMAT" != "json" && "$OUTPUT_FORMAT" != "summary" ]]; then
                    log_error "Invalid format: $OUTPUT_FORMAT. Must be 'json' or 'summary'"
                    exit 1
                fi
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --all)
                ANALYZE_ALL=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                BRANCHES+=("$1")
                shift
                ;;
        esac
    done
}

# Validate project directory and git repository
validate_environment() {
    if [[ ! -d "$PROJECT_DIR" ]]; then
        log_error "Project directory does not exist: $PROJECT_DIR"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not a git repository: $PROJECT_DIR"
        exit 1
    fi
}

# Auto-detect target branch (main with fallback to master)
detect_target_branch() {
    if [[ -n "$TARGET_BRANCH" ]]; then
        if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
            log_error "Specified target branch '$TARGET_BRANCH' does not exist"
            exit 1
        fi
        echo "$TARGET_BRANCH"
        return
    fi
    
    # Try main first, then master
    if git show-ref --verify --quiet "refs/heads/main"; then
        echo "main"
    elif git show-ref --verify --quiet "refs/heads/master"; then
        echo "master"
    else
        log_error "Cannot auto-detect target branch. Neither 'main' nor 'master' exist."
        log_error "Please specify target branch with -t/--target-branch option."
        exit 1
    fi
}

# Get list of branches to analyze
get_branches_to_analyze() {
    local target_branch="$1"
    local protected_branches=("main" "master" "$target_branch")
    
    if [[ "$ANALYZE_ALL" == true ]]; then
        # Get all local branches except protected ones
        local all_branches
        all_branches=$(git branch --format="%(refname:short)")
        
        while IFS= read -r branch; do
            # Skip protected branches
            local skip=false
            for protected in "${protected_branches[@]}"; do
                if [[ "$branch" == "$protected" ]]; then
                    skip=true
                    break
                fi
            done
            
            if [[ "$skip" == false ]]; then
                BRANCHES+=("$branch")
            fi
        done <<< "$all_branches"
    fi
    
    # Validate that requested branches exist
    for branch in "${BRANCHES[@]}"; do
        if ! git show-ref --verify --quiet "refs/heads/$branch"; then
            log_error "Branch '$branch' does not exist"
            exit 1
        fi
        
        # Warn if analyzing a protected branch
        for protected in "${protected_branches[@]}"; do
            if [[ "$branch" == "$protected" ]]; then
                log_warning "Analyzing protected branch '$branch' - this may not be useful"
                break
            fi
        done
    done
    
    if [[ ${#BRANCHES[@]} -eq 0 ]]; then
        log_error "No branches to analyze"
        exit 1
    fi
}

# Get current branch (may be empty in detached HEAD state)
get_current_branch() {
    git branch --show-current || echo ""
}

# Analyze remote tracking information
analyze_remote_tracking() {
    local branch="$1"
    local has_remote_tracking=false
    local remote_branch_exists=false
    local tracking_status=""
    local remote_name=""
    local remote_branch_name=""
    
    # Check if branch has upstream tracking configured
    local upstream
    if upstream=$(git rev-parse --symbolic-full-name "$branch@{upstream}" 2>/dev/null); then
        has_remote_tracking=true
        remote_name=$(echo "$upstream" | sed 's|refs/remotes/||' | cut -d'/' -f1)
        remote_branch_name=$(echo "$upstream" | sed 's|refs/remotes/||')
        
        # Check if remote branch actually exists
        if git show-ref --verify --quiet "$upstream"; then
            remote_branch_exists=true
            
            # Determine tracking status
            local ahead behind
            ahead=$(git rev-list --count "$upstream..$branch" 2>/dev/null || echo "0")
            behind=$(git rev-list --count "$branch..$upstream" 2>/dev/null || echo "0")
            
            if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
                tracking_status="up-to-date"
            elif [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then
                tracking_status="ahead"
            elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then
                tracking_status="behind"  
            else
                tracking_status="diverged"
            fi
        else
            # Remote tracking exists but remote branch is gone
            remote_branch_exists=false
            tracking_status="gone"
        fi
    fi
    
    cat << EOF
    "remote_tracking": {
        "has_remote_tracking_branch": $has_remote_tracking,
        "remote_branch_exists": $remote_branch_exists,
        "tracking_status": "$tracking_status",
        "remote_name": "$remote_name",
        "remote_branch_name": "$remote_branch_name"
    }
EOF
}

# Extract MR/PR references from commit message
extract_mr_references() {
    local commit_message="$1"
    local references=()
    
    # GitLab MR patterns: !123, project/namespace!123, etc.
    while IFS= read -r ref; do
        [[ -n "$ref" ]] && references+=("\"$ref\"")
    done < <(echo "$commit_message" | grep -oE '(\w+/\w+)?!?[0-9]+' | grep '!')
    
    # GitHub PR patterns: #123, user/repo#123, etc.
    while IFS= read -r ref; do
        [[ -n "$ref" ]] && references+=("\"$ref\"")
    done < <(echo "$commit_message" | grep -oE '(\w+/\w+)?#[0-9]+' | head -5)
    
    # Output as JSON array
    if [[ ${#references[@]} -gt 0 ]]; then
        local IFS=','
        echo "[${references[*]}]"
    else
        echo "[]"
    fi
}

# Find merge evidence in target branch
find_merge_evidence() {
    local branch="$1"
    local target_branch="$2" 
    local merge_base="$3"
    
    local head_sha
    head_sha=$(git rev-parse "$branch")
    
    # Check if head SHA exists in target branch
    local head_in_target=false
    if git merge-base --is-ancestor "$branch" "$target_branch" 2>/dev/null; then
        head_in_target=true
    fi
    
    # Get merge-base date to limit search scope
    local merge_base_date
    merge_base_date=$(git log -1 --format="%aI" "$merge_base")
    
    # Find merge commits referencing this branch (after merge-base date)
    local merge_commits=()
    while IFS='|' read -r sha date subject; do
        [[ -z "$sha" ]] && continue
        
        local mr_refs
        mr_refs=$(extract_mr_references "$subject")
        
        merge_commits+=("{
            \"commit_sha\": \"$sha\",
            \"commit_date\": \"$date\", 
            \"commit_subject\": $(echo "$subject" | sed 's/"/\\"/g' | sed 's/.*/"&"/'),
            \"extracted_mr_references\": $mr_refs
        }")
    done < <(git log --since="$merge_base_date" --merges --grep="$branch" --format="%H|%aI|%s" "$target_branch" | head -5)
    
    # Find target commits mentioning branch name (potential squash merges)
    local branch_references=()
    while IFS='|' read -r sha date subject; do
        [[ -z "$sha" ]] && continue
        
        # Check if this looks like a squash commit
        local is_squash=false
        if echo "$subject" | grep -qi "squash\|^MAJOR:\|^MINOR:\|^PATCH:"; then
            is_squash=true
        fi
        
        local mr_refs
        mr_refs=$(extract_mr_references "$subject")
        
        branch_references+=("{
            \"commit_sha\": \"$sha\",
            \"commit_date\": \"$date\",
            \"commit_subject\": $(echo "$subject" | sed 's/"/\\"/g' | sed 's/.*/"&"/'),
            \"likely_squash_commit\": $is_squash,
            \"extracted_mr_references\": $mr_refs
        }")
    done < <(git log --since="$merge_base_date" --grep="$branch" --format="%H|%aI|%s" "$target_branch" | grep -v "^$" | head -3)
    
    # Format JSON output
    local merge_commits_json=""
    local branch_refs_json=""
    
    if [[ ${#merge_commits[@]} -gt 0 ]]; then
        local IFS=','
        merge_commits_json="${merge_commits[*]}"
    fi
    
    if [[ ${#branch_references[@]} -gt 0 ]]; then
        local IFS=','
        branch_refs_json="${branch_references[*]}"
    fi
    
    cat << EOF
    "merge_evidence": {
        "head_sha_exists_in_target": $head_in_target,
        "merge_commits_referencing_branch": [$merge_commits_json],
        "target_commits_mentioning_branch": [$branch_refs_json]
    }
EOF
}

# Analyze branch characteristics
analyze_characteristics() {
    local branch="$1"
    local target_branch="$2"
    local commits_behind="$3"
    local commits_ahead="$4" 
    local days_since_last="$5"
    local merge_base_days_ago="$6"
    local has_remote_tracking="$7"
    local remote_branch_exists="$8"
    local head_in_target="$9"
    local merge_commits_count="${10}"
    local branch_refs_count="${11}"
    
    # Analyze characteristics
    local no_remote_tracking=false
    local remote_branch_deleted=false
    local very_old_branch=false
    local very_stale=false
    local far_behind_target=false
    local no_unique_commits=false
    local recent_activity=false
    local clear_merge_evidence=false
    local dependency_update_pattern=false
    
    [[ "$has_remote_tracking" == "false" ]] && no_remote_tracking=true
    [[ "$has_remote_tracking" == "true" && "$remote_branch_exists" == "false" ]] && remote_branch_deleted=true
    [[ "$merge_base_days_ago" -gt 180 ]] && very_old_branch=true
    [[ "$days_since_last" -gt 90 ]] && very_stale=true
    [[ "$commits_behind" -gt 100 ]] && far_behind_target=true
    [[ "$commits_ahead" -eq 0 ]] && no_unique_commits=true
    [[ "$days_since_last" -lt 7 ]] && recent_activity=true
    [[ "$head_in_target" == "true" || "$merge_commits_count" -gt 0 || "$branch_refs_count" -gt 0 ]] && clear_merge_evidence=true
    
    # Check for dependency update patterns in commit messages
    local recent_commits
    recent_commits=$(git log --since="30 days ago" --format="%s" "$branch" | head -5)
    if echo "$recent_commits" | grep -qi "update.*dep\|bump.*version\|update.*package\|upgrade.*to"; then
        dependency_update_pattern=true
    fi
    
    cat << EOF
    "notable_characteristics": {
        "no_remote_tracking": $no_remote_tracking,
        "remote_branch_deleted": $remote_branch_deleted,
        "very_old_branch": $very_old_branch,
        "very_stale": $very_stale,
        "far_behind_target": $far_behind_target,
        "no_unique_commits": $no_unique_commits,
        "recent_activity": $recent_activity,
        "clear_merge_evidence": $clear_merge_evidence,
        "dependency_update_pattern": $dependency_update_pattern
    }
EOF
}

# Get commit authors information
get_author_info() {
    local branch="$1"
    local merge_base="$2"
    
    local first_author last_author
    first_author=$(git log --reverse --format="%an <%ae>" "$merge_base..$branch" | head -1)
    last_author=$(git log -1 --format="%an <%ae>" "$branch")
    
    # Get unique authors
    local unique_authors unique_count
    unique_authors=$(git log --format="%an <%ae>" "$merge_base..$branch" | sort -u)
    unique_count=$(echo "$unique_authors" | wc -l)
    
    # Format authors array for JSON
    local authors_json=()
    while IFS= read -r author; do
        [[ -n "$author" ]] && authors_json+=("\"$(echo "$author" | sed 's/"/\\"/g')\"")
    done <<< "$unique_authors"
    
    local authors_json_str=""
    if [[ ${#authors_json[@]} -gt 0 ]]; then
        local IFS=','
        authors_json_str="${authors_json[*]}"
    fi
    
    cat << EOF
    "authors": {
        "first_commit_author": "$(echo "$first_author" | sed 's/"/\\"/g')",
        "last_commit_author": "$(echo "$last_author" | sed 's/"/\\"/g')",
        "unique_author_count": $unique_count,
        "all_authors": [$authors_json_str]
    }
EOF
}

# Calculate days between two dates
days_between() {
    local date1="$1"
    local date2="$2"
    
    if command -v gdate >/dev/null 2>&1; then
        # Use GNU date if available (brew install coreutils on macOS)
        echo $(( ($(gdate -d "$date2" +%s) - $(gdate -d "$date1" +%s)) / 86400 ))
    else
        # Fallback for BSD date (macOS default)
        local epoch1 epoch2
        epoch1=$(date -jf "%Y-%m-%dT%H:%M:%S" "${date1%+*}" +%s 2>/dev/null || date -jf "%Y-%m-%d %H:%M:%S" "$date1" +%s 2>/dev/null || echo 0)
        epoch2=$(date -jf "%Y-%m-%dT%H:%M:%S" "${date2%+*}" +%s 2>/dev/null || date -jf "%Y-%m-%d %H:%M:%S" "$date2" +%s 2>/dev/null || date +%s)
        echo $(( (epoch2 - epoch1) / 86400 ))
    fi
}

# Analyze a single branch
analyze_branch() {
    local branch="$1"
    local target_branch="$2"
    local current_branch="$3"
    local analysis_date="$4"
    
    # Basic branch info
    local head_sha
    head_sha=$(git rev-parse "$branch")
    
    local is_current=false
    [[ "$branch" == "$current_branch" ]] && is_current=true
    
    # Find merge-base with target branch
    local merge_base
    if ! merge_base=$(git merge-base "$branch" "$target_branch" 2>/dev/null); then
        log_warning "Cannot find merge-base between '$branch' and '$target_branch' - skipping"
        return 1
    fi
    
    local merge_base_date
    merge_base_date=$(git log -1 --format="%aI" "$merge_base")
    
    local merge_base_days_ago
    merge_base_days_ago=$(days_between "$merge_base_date" "$analysis_date")
    
    # Commit timeline analysis
    local first_commit_date last_commit_date total_commits
    first_commit_date=$(git log --reverse --format="%aI" "$merge_base..$branch" | head -1)
    last_commit_date=$(git log -1 --format="%aI" "$branch")
    total_commits=$(git rev-list --count "$merge_base..$branch")
    
    # Handle case where branch has no commits beyond merge-base
    if [[ -z "$first_commit_date" ]]; then
        first_commit_date="$merge_base_date"
    fi
    
    local days_since_first days_since_last
    days_since_first=$(days_between "$first_commit_date" "$analysis_date")
    days_since_last=$(days_between "$last_commit_date" "$analysis_date")
    
    # Divergence analysis
    local commits_behind commits_ahead
    commits_behind=$(git rev-list --count "$branch..$target_branch")
    commits_ahead=$(git rev-list --count "$target_branch..$branch")
    
    # Remote tracking analysis
    local remote_info
    remote_info=$(analyze_remote_tracking "$branch")
    
    # Extract remote tracking values for characteristics analysis
    local has_remote_tracking remote_branch_exists
    has_remote_tracking=$(echo "$remote_info" | grep '"has_remote_tracking_branch"' | grep -o 'true\|false')
    remote_branch_exists=$(echo "$remote_info" | grep '"remote_branch_exists"' | grep -o 'true\|false')
    
    # Author information
    local author_info
    author_info=$(get_author_info "$branch" "$merge_base")
    
    # Merge evidence
    local merge_evidence
    merge_evidence=$(find_merge_evidence "$branch" "$target_branch" "$merge_base")
    
    # Extract merge evidence counts for characteristics
    local head_in_target merge_commits_count branch_refs_count
    head_in_target=$(echo "$merge_evidence" | grep '"head_sha_exists_in_target"' | grep -o 'true\|false')
    merge_commits_count=$(echo "$merge_evidence" | grep -o '"merge_commits_referencing_branch": \[.*\]' | grep -o '{[^}]*}' | wc -l)
    branch_refs_count=$(echo "$merge_evidence" | grep -o '"target_commits_mentioning_branch": \[.*\]' | grep -o '{[^}]*}' | wc -l)
    
    # Characteristics analysis  
    local characteristics
    characteristics=$(analyze_characteristics "$branch" "$target_branch" "$commits_behind" "$commits_ahead" "$days_since_last" "$merge_base_days_ago" "$has_remote_tracking" "$remote_branch_exists" "$head_in_target" "$merge_commits_count" "$branch_refs_count")
    
    # Output JSON for this branch
    cat << EOF
{
    "branch_name": "$branch",
    "analysis_date": "$analysis_date",
    "project_dir": "$PROJECT_DIR",
    "target_branch": "$target_branch",
    "head_sha": "$head_sha",
    "is_current_branch": $is_current,
    "merge_base": {
        "sha": "$merge_base",
        "date": "$merge_base_date",
        "days_ago": $merge_base_days_ago
    },
    "commit_timeline": {
        "first_commit_date": "$first_commit_date",
        "last_commit_date": "$last_commit_date",
        "total_commits": $total_commits,
        "days_since_first_commit": $days_since_first,
        "days_since_last_commit": $days_since_last
    },
    "divergence_from_target": {
        "commits_behind": $commits_behind,
        "commits_ahead": $commits_ahead
    },
$remote_info,
$author_info,
$merge_evidence,
$characteristics
}
EOF
}

# Output analysis in summary format
output_summary() {
    local branch="$1"
    local target_branch="$2"
    local current_branch="$3"
    local analysis_date="$4"
    
    echo -e "\n${BLUE}=== Branch: $branch ===${NC}"
    
    # Get basic info
    local head_sha merge_base commits_behind commits_ahead
    head_sha=$(git rev-parse "$branch" | cut -c1-8)
    
    if ! merge_base=$(git merge-base "$branch" "$target_branch" 2>/dev/null); then
        echo -e "${RED}Cannot find merge-base with $target_branch${NC}"
        return 1
    fi
    
    commits_behind=$(git rev-list --count "$branch..$target_branch")
    commits_ahead=$(git rev-list --count "$target_branch..$branch")
    
    # Status indicators
    [[ "$branch" == "$current_branch" ]] && echo -e "${YELLOW}→ Currently checked out${NC}"
    
    echo "SHA: $head_sha"
    echo "Commits: +$commits_ahead / -$commits_behind vs $target_branch"
    
    # Remote tracking status
    if git rev-parse --symbolic-full-name "$branch@{upstream}" >/dev/null 2>&1; then
        local upstream
        upstream=$(git rev-parse --symbolic-full-name "$branch@{upstream}")
        if git show-ref --verify --quiet "$upstream"; then
            echo -e "${GREEN}Remote: tracked ($upstream)${NC}"
        else
            echo -e "${RED}Remote: gone ($upstream)${NC}"
        fi
    else
        echo -e "${YELLOW}Remote: no tracking${NC}"
    fi
    
    # Check for merge evidence
    if git merge-base --is-ancestor "$branch" "$target_branch" 2>/dev/null; then
        echo -e "${GREEN}Status: Merged into $target_branch${NC}"
    else
        echo -e "${YELLOW}Status: Not merged${NC}"
    fi
    
    # Last commit info
    local last_commit_date days_ago
    last_commit_date=$(git log -1 --format="%aI" "$branch")
    days_ago=$(days_between "$last_commit_date" "$analysis_date")
    echo "Last commit: $days_ago days ago"
    
    # Recent commit message
    local last_subject
    last_subject=$(git log -1 --format="%s" "$branch" | cut -c1-60)
    echo "\"$last_subject\""
}

# Main analysis function
main() {
    local analysis_date
    analysis_date=$(date -Iseconds)
    
    # Parse arguments
    parse_args "$@"
    
    # Validate environment  
    validate_environment
    
    # Detect target branch
    local target_branch
    target_branch=$(detect_target_branch)
    
    # Get branches to analyze
    get_branches_to_analyze "$target_branch"
    
    # Get current branch
    local current_branch
    current_branch=$(get_current_branch)
    
    log_info "Analyzing ${#BRANCHES[@]} branches against target '$target_branch'"
    
    # Output format handling
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        echo "{"
        echo "  \"analysis_date\": \"$analysis_date\","
        echo "  \"project_dir\": \"$PROJECT_DIR\","
        echo "  \"target_branch\": \"$target_branch\","
        echo "  \"current_branch\": \"$current_branch\","
        echo "  \"branches\": ["
        
        local first_branch=true
        for branch in "${BRANCHES[@]}"; do
            [[ "$first_branch" == false ]] && echo ","
            first_branch=false
            
            if ! analyze_branch "$branch" "$target_branch" "$current_branch" "$analysis_date"; then
                # Skip failed analysis, but adjust JSON formatting
                first_branch=true
            fi
        done
        
        echo ""
        echo "  ]"
        echo "}"
    else
        # Summary format
        echo -e "${GREEN}Git Branch Analysis Summary${NC}"
        echo "Target branch: $target_branch"
        echo "Current branch: ${current_branch:-"(detached HEAD)"}"
        echo "Analysis date: $analysis_date"
        
        for branch in "${BRANCHES[@]}"; do
            output_summary "$branch" "$target_branch" "$current_branch" "$analysis_date"
        done
    fi
}

# Run main function with all arguments
main "$@"