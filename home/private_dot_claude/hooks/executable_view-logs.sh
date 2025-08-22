#!/bin/bash
#
# Claude Code Agent Log Viewer
# 
# This script provides an easy way to view and analyze agent debugging logs
# Usage: ./view-logs.sh [options] [session_id]
#

set -euo pipefail

LOGS_DIR="$HOME/.claude/logs/sessions"
SCRIPT_NAME="$(basename "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Default options
SHOW_RECENT=5
TAIL_LINES=50
FOLLOW=false
AGENT_FILTER=""
TOOL_FILTER=""
SHOW_METADATA=false
VERBOSE=false

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [options] [session_id]

View Claude Code agent debugging logs with filtering and formatting options.

OPTIONS:
    -h, --help          Show this help message
    -r, --recent N      Show N most recent sessions (default: 5)
    -t, --tail N        Show last N lines of each log (default: 50, 0 for all)
    -f, --follow        Follow log output (tail -f mode)
    -a, --agent NAME    Filter by agent name (e.g., git-rebase-resolver)
    -T, --tool NAME     Filter by tool name (e.g., Task, Bash, Edit)
    -m, --metadata      Show session metadata
    -v, --verbose       Show verbose output including raw input
    -l, --list          List all available sessions

EXAMPLES:
    $SCRIPT_NAME                          # Show recent sessions overview
    $SCRIPT_NAME session_abc123           # View specific session
    $SCRIPT_NAME -a git-rebase-resolver   # Show sessions using git-rebase-resolver
    $SCRIPT_NAME -f session_abc123        # Follow a specific session
    $SCRIPT_NAME -T Task -r 10            # Show Task tool usage in last 10 sessions
    $SCRIPT_NAME -l                       # List all sessions
EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# List all available sessions
list_sessions() {
    if [[ ! -d "$LOGS_DIR" ]]; then
        log_error "No logs directory found at $LOGS_DIR"
        return 1
    fi
    
    echo -e "${CYAN}Available Sessions:${NC}"
    echo "==================="
    
    find "$LOGS_DIR" -name "metadata.json" -type f | sort -r | while read -r metadata_file; do
        session_dir="$(dirname "$metadata_file")"
        session_id="$(basename "$session_dir")"
        date_dir="$(basename "$(dirname "$session_dir")")"
        
        if [[ -f "$metadata_file" ]]; then
            created_at=$(jq -r '.created_at // "unknown"' "$metadata_file" 2>/dev/null || echo "unknown")
            agents_used=$(jq -r '.agents_used[]? // empty' "$metadata_file" 2>/dev/null | paste -sd ',' - || echo "none")
            tools_count=$(jq -r '.tools_called | length' "$metadata_file" 2>/dev/null || echo "0")
            
            printf "${GREEN}%s${NC} ${GRAY}(%s)${NC}\n" "$session_id" "$date_dir"
            printf "  Created: %s\n" "$created_at"
            printf "  Agents: %s\n" "$agents_used"
            printf "  Tools called: %s\n" "$tools_count"
            echo
        fi
    done
}

# Get recent sessions
get_recent_sessions() {
    local count=${1:-$SHOW_RECENT}
    find "$LOGS_DIR" -name "metadata.json" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | \
        sort -rn | head -n "$count" | cut -d' ' -f2- | \
        while read -r metadata_file; do
            dirname "$metadata_file"
        done
}

# Format and display log content with syntax highlighting
display_log() {
    local log_file="$1"
    local tail_lines="$2"
    
    if [[ ! -f "$log_file" ]]; then
        return 0
    fi
    
    local content
    if [[ "$tail_lines" -eq 0 ]]; then
        content="$(cat "$log_file")"
    else
        content="$(tail -n "$tail_lines" "$log_file")"
    fi
    
    # Apply filters
    if [[ -n "$TOOL_FILTER" ]]; then
        content="$(echo "$content" | grep -A 20 -B 5 "TOOL: $TOOL_FILTER" || true)"
    fi
    
    # Syntax highlighting
    echo "$content" | while IFS= read -r line; do
        case "$line" in
            "="*"=")
                echo -e "${PURPLE}$line${NC}"
                ;;
            "TIMESTAMP:"*)
                echo -e "${CYAN}$line${NC}"
                ;;
            "HOOK_TYPE:"*|"SESSION_ID:"*|"WORKING_DIR:"*)
                echo -e "${BLUE}$line${NC}"
                ;;
            "TOOL:"*|"SUB_AGENT:"*|"TASK_DESC:"*)
                echo -e "${GREEN}$line${NC}"
                ;;
            "AGENT_PROMPT:"|"TOOL_INPUT:"|"TOOL_OUTPUT:"|"ERROR:")
                echo -e "${YELLOW}$line${NC}"
                ;;
            "-"*"-")
                echo -e "${GRAY}$line${NC}"
                ;;
            *)
                echo "$line"
                ;;
        esac
    done
}

# Display session overview
show_session() {
    local session_dir="$1"
    local session_id="$(basename "$session_dir")"
    local date_dir="$(basename "$(dirname "$session_dir")")"
    
    echo -e "${PURPLE}Session: $session_id${NC} ${GRAY}($date_dir)${NC}"
    echo "$(printf '=%.0s' {1..80})"
    
    # Show metadata if requested
    if [[ "$SHOW_METADATA" = true && -f "$session_dir/metadata.json" ]]; then
        echo -e "${CYAN}Metadata:${NC}"
        jq '.' "$session_dir/metadata.json" 2>/dev/null || echo "Invalid metadata"
        echo
    fi
    
    # Show logs from each file
    for log_file in "$session_dir"/*.log; do
        if [[ -f "$log_file" ]]; then
            local log_name="$(basename "$log_file" .log)"
            
            # Apply agent filter
            if [[ -n "$AGENT_FILTER" ]]; then
                # For agent filtering, show both agent-specific log AND main log
                # (since sub-agent tool calls go to main.log)
                if [[ "$log_name" != *"$AGENT_FILTER"* && "$log_name" != "main" ]]; then
                    continue
                fi
            fi
            
            echo -e "${GREEN}Log: $log_name${NC}"
            echo "$(printf -- '-%.0s' {1..40})"
            
            if [[ "$FOLLOW" = true ]]; then
                tail -f "$log_file" | while IFS= read -r line; do
                    display_log <(echo "$line") 1
                done
            else
                display_log "$log_file" "$TAIL_LINES"
            fi
            echo
        fi
    done
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -r|--recent)
            SHOW_RECENT="$2"
            shift 2
            ;;
        -t|--tail)
            TAIL_LINES="$2"
            shift 2
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -a|--agent)
            AGENT_FILTER="$2"
            shift 2
            ;;
        -T|--tool)
            TOOL_FILTER="$2"
            shift 2
            ;;
        -m|--metadata)
            SHOW_METADATA=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            export CLAUDE_DEBUG_VERBOSE=1
            shift
            ;;
        -l|--list)
            list_sessions
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            SESSION_ID="$1"
            shift
            ;;
    esac
done

# Main logic
if [[ ! -d "$LOGS_DIR" ]]; then
    log_error "No logs directory found at $LOGS_DIR"
    exit 1
fi

if [[ -n "${SESSION_ID:-}" ]]; then
    # Show specific session
    session_dirs=($(find "$LOGS_DIR" -name "$SESSION_ID" -type d))
    
    if [[ ${#session_dirs[@]} -eq 0 ]]; then
        log_error "Session $SESSION_ID not found"
        exit 1
    fi
    
    for session_dir in "${session_dirs[@]}"; do
        show_session "$session_dir"
        echo
    done
else
    # Show recent sessions
    log_info "Showing $SHOW_RECENT most recent sessions"
    echo
    
    get_recent_sessions "$SHOW_RECENT" | while read -r session_dir; do
        show_session "$session_dir"
        echo
    done
fi