#!/bin/bash

# Jira Ticket Detection Script
# Extracts JIRA ticket from Claude transcript file
# 
# Usage: ./find-jira-ticket.sh <transcript_file_path> [current_dir]
#
# Priority:
# 1. Most frequent JIRA pattern from user prompts
# 2. Most recent JIRA pattern from user prompts (if tied frequency)  
# 3. JIRA pattern from git branch (fallback, defaults to current working directory)

# Function to find JIRA ticket with smart user-prompt focused detection
find_jira_ticket() {
    local transcript_path="$1"
    local current_dir="$2"
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

# Main script logic
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <transcript_file_path> [current_dir]" >&2
    echo "  transcript_file_path: Path to Claude transcript file" >&2
    echo "  current_dir: Optional directory for git branch fallback (defaults to current working directory)" >&2
    exit 1
fi

transcript_path="$1"
current_dir="${2:-$(pwd)}"

# Check if transcript file exists
if [[ ! -f "$transcript_path" ]]; then
    echo "Error: Transcript file '$transcript_path' not found" >&2
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Find and output the JIRA ticket
ticket=$(find_jira_ticket "$transcript_path" "$current_dir")
echo "$ticket"