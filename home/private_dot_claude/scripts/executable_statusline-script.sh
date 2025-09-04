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

# Function to find JIRA ticket using external script
find_jira_ticket() {
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local jira_script="$script_dir/find-jira-ticket.sh"
    
    # Check if the external script exists
    if [[ -x "$jira_script" ]]; then
        "$jira_script" "$transcript_path" "$current_dir"
    else
        # Fallback: empty result if script not found
        echo ""
    fi
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