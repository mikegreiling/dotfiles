#!/bin/bash

# Claude Code Status Line Script
# Displays: Model | JIRA Ticket | Project | Path | Git Info
#
# RECENT IMPROVEMENTS:
# - Removed emoji output from all components
# - Fixed path normalization to show ~/path instead of /Users/mike/path
# - Smart JIRA detection focusing on user prompts with frequency ranking
# - Handles both string and array content formats in transcripts
# - Falls back to git branch JIRA detection when user prompts have none

# Read input JSON from stdin
input=$(cat)

# Extract data from JSON input
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')
transcript_path=$(echo "$input" | jq -r '.transcript_path')



# Color definitions
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
PURPLE='\033[35m'
CYAN='\033[36m'
RED='\033[31m'

# Function to find JIRA ticket with smart user-prompt focused detection
# Priority:
# 1. Most frequent JIRA pattern from user prompts
# 2. Most recent JIRA pattern from user prompts (if tied frequency)
# 3. JIRA pattern from git branch (fallback)
find_jira_ticket() {
    local jira_pattern='(SPR|MULA|TBD|ZRO|WRH|GLOB|BUGS)-[0-9]{1,5}'
    
    # First, try to extract JIRA patterns from user prompts in transcript
    if [[ -f "$transcript_path" ]]; then
        local user_jira_patterns=""
        
        # Parse transcript and extract user message content
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            
            # Check if this line is a user message
            if echo "$line" | jq -e 'select(.type == "user")' >/dev/null 2>&1; then
                local text_content=""
                
                # Handle both string and array content formats
                if echo "$line" | jq -e '.message.content | type == "string"' >/dev/null 2>&1; then
                    text_content=$(echo "$line" | jq -r '.message.content' 2>/dev/null)
                elif echo "$line" | jq -e '.message.content | type == "array"' >/dev/null 2>&1; then
                    text_content=$(echo "$line" | jq -r '
                        .message.content[]? 
                        | select(.type == "text") 
                        | .text
                    ' 2>/dev/null | tr '\n' ' ')
                fi
                
                # Skip tool results, system messages, and bash command input/output
                if [[ -n "$text_content" ]] && ! [[ "$text_content" =~ ^[\<\[]?tool_(use_)?result|^\[Request\ interrupted|^Caveat:.*local\ commands|^\<(local-command|command-|bash-).*\>|^\(no\ content\)$ ]]; then
                    user_jira_patterns+="$text_content "
                fi
            fi
        done < "$transcript_path"
        
        # Find most frequent JIRA pattern from user messages
        if [[ -n "$user_jira_patterns" ]]; then
            local most_frequent=$(echo "$user_jira_patterns" | grep -oE "$jira_pattern" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
            if [[ -n "$most_frequent" ]]; then
                echo "$most_frequent"
                return
            fi
        fi
    fi
    
    # Fallback: Check current git branch
    if git -C "$current_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch=$(git -C "$current_dir" symbolic-ref --quiet --short HEAD 2>/dev/null)
        if [[ -n "$branch" ]]; then
            local ticket=$(echo "$branch" | grep -oE "$jira_pattern" | head -1)
            if [[ -n "$ticket" ]]; then
                echo "$ticket"
                return
            fi
        fi
    fi
    
    # No ticket found
    echo ""
}

# Function to determine current project
get_project_info() {
    local home_dir="$HOME"
    local bstock_projects="$home_dir/Projects/bstock-projects"
    local projects_dir="$home_dir/Projects"
    
    # Check if exactly in bstock-projects root
    if [[ "$current_dir" == "$bstock_projects" ]]; then
        echo "PROJECT:"
        echo "PATH:~/Projects/bstock-projects"
    # Check if in bstock-projects subdirectory
    elif [[ "$current_dir" == "$bstock_projects"/* ]]; then
        # Extract project name (next subdirectory after bstock-projects)
        local relative_path="${current_dir#$bstock_projects/}"
        if [[ "$relative_path" != "$current_dir" && "$relative_path" != "" ]]; then
            local project_name=$(echo "$relative_path" | cut -d'/' -f1)
            local project_path="${relative_path#$project_name}"
            project_path="${project_path#/}"  # Remove leading slash
            echo "PROJECT:$project_name"
            echo "PATH:$project_path"
        else
            # In bstock-projects root - no project  
            echo "PROJECT:"
            echo "PATH:~/Projects/bstock-projects"
        fi
    # Check if in other Projects subdirectory
    elif [[ "$current_dir" == "$projects_dir"/* ]]; then
        local relative_path="${current_dir#$projects_dir/}"
        if [[ "$relative_path" != "$current_dir" && "$relative_path" != "" ]]; then
            local first_dir=$(echo "$relative_path" | cut -d'/' -f1)
            if [[ "$first_dir" != "bstock-projects" ]]; then
                local project_name="$first_dir"
                local project_path="${relative_path#$project_name}"
                project_path="${project_path#/}"  # Remove leading slash
                echo "PROJECT:$project_name"
                echo "PATH:$project_path"
            else
                # This shouldn't happen based on logic above, but fallback
                echo "PROJECT:"
                echo "PATH:${current_dir/#$home_dir/~}"
            fi
        else
            # In Projects root
            echo "PROJECT:"
            echo "PATH:~/Projects"
        fi
    # Check if in home directory (fix path normalization)
    elif [[ "$current_dir" == "$home_dir"/* ]]; then
        echo "PROJECT:"
        echo "PATH:${current_dir/#$home_dir/~}"
    elif [[ "$current_dir" == "$home_dir" ]]; then
        # Exactly in home directory
        echo "PROJECT:"
        echo "PATH:~"
    else
        # Outside home directory
        echo "PROJECT:"
        echo "PATH:$current_dir"
    fi
}

# Function to get git information
get_git_info() {
    if ! git -C "$current_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo ""
        return
    fi
    
    # Get branch name
    local branch=$(git -C "$current_dir" symbolic-ref --quiet --short HEAD 2>/dev/null || git -C "$current_dir" rev-parse --short HEAD 2>/dev/null || echo '(unknown)')
    
    # Get status indicators
    local status=""
    
    # Staged changes
    if ! git -C "$current_dir" diff --quiet --ignore-submodules --cached 2>/dev/null; then
        status+="+"
    fi
    
    # Unstaged changes
    if ! git -C "$current_dir" diff-files --quiet --ignore-submodules -- 2>/dev/null; then
        status+="!"
    fi
    
    # Untracked files
    if [[ -n "$(git -C "$current_dir" ls-files --others --exclude-standard 2>/dev/null)" ]]; then
        status+="?"
    fi
    
    # Get ahead/behind info
    local remote_info=""
    local upstream=$(git -C "$current_dir" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        local ahead_behind=$(git -C "$current_dir" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null)
        if [[ -n "$ahead_behind" ]]; then
            local ahead=$(echo "$ahead_behind" | cut -f1)
            local behind=$(echo "$ahead_behind" | cut -f2)
            
            if [[ "$ahead" -gt 0 ]]; then
                remote_info+="↑$ahead"
            fi
            if [[ "$behind" -gt 0 ]]; then
                remote_info+="↓$behind"
            fi
        fi
    fi
    
    # Combine status and remote info
    local full_status=""
    if [[ -n "$status" || -n "$remote_info" ]]; then
        full_status=" ["
        [[ -n "$status" ]] && full_status+="$status"
        [[ -n "$status" && -n "$remote_info" ]] && full_status+="|"
        [[ -n "$remote_info" ]] && full_status+="$remote_info"
        full_status+="]"
    fi
    
    echo "$branch$full_status"
}

# Get all information
jira_ticket=$(find_jira_ticket)
project_info=$(get_project_info)
project_name=$(echo "$project_info" | grep "PROJECT:" | cut -d':' -f2)
path_info=$(echo "$project_info" | grep "PATH:" | cut -d':' -f2)
git_info=$(get_git_info)

# Build status line components
components=()

# Model (always present) - removed emoji
components+=("${BLUE}${model_name}${RESET}")

# JIRA Ticket (if present) - removed emoji  
if [[ -n "$jira_ticket" ]]; then
    components+=("${YELLOW}${jira_ticket}${RESET}")
fi

# Project (if present) - removed emoji
if [[ -n "$project_name" ]]; then
    components+=("${GREEN}${project_name}${RESET}")
fi

# Path (always present, but contextual) - removed emoji
if [[ -n "$path_info" ]]; then
    components+=("${CYAN}${path_info}${RESET}")
fi

# Git info (if in git repo) - removed emoji
if [[ -n "$git_info" ]]; then
    components+=("${PURPLE}${git_info}${RESET}")
fi

# Join components with separator
separator="${DIM} │ ${RESET}"
status_line=""
for i in "${!components[@]}"; do
    if [[ $i -gt 0 ]]; then
        status_line+="$separator"
    fi
    status_line+="${components[i]}"
done


# Output the final status line
printf "%b\n" "$status_line"