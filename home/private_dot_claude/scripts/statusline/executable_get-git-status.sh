#!/bin/bash

# Git Status Script for ccstatusline
# Reads JSON from stdin and outputs git branch with status indicators
# Usage: echo '{"workspace":{"current_dir":"/path/to/dir"}}' | ./get-git-status.sh

json_input=$(cat)
current_dir=$(echo "$json_input" | jq -r '.workspace.current_dir')

# Check if jq extraction succeeded
if [[ "$current_dir" == "null" ]]; then
    echo ""
    exit 0
fi

# Extract git info logic from original statusline-script.sh
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

git_info=$(get_git_info)
echo "$git_info"