#!/bin/bash

# JIRA Ticket Detection Script for ccstatusline
# Reads JSON from stdin and extracts JIRA ticket
# Usage: echo '{"transcript_path":"/path/to/file", "workspace":{"current_dir":"/path"}}' | ./get-jira-ticket.sh

# Read JSON from stdin and extract transcript path and current_dir
json_input=$(cat)
transcript_path=$(echo "$json_input" | jq -r '.transcript_path')
current_dir=$(echo "$json_input" | jq -r '.workspace.current_dir')

# Check if jq extraction succeeded
if [[ "$transcript_path" == "null" || "$current_dir" == "null" ]]; then
    echo ""
    exit 0
fi

# Check if transcript file exists and is readable
if [[ ! -f "$transcript_path" || ! -r "$transcript_path" ]]; then
    echo ""
    exit 0
fi

# Check if transcript file is empty or has minimal content
# (new sessions might have just started writing)
if [[ ! -s "$transcript_path" ]]; then
    # File is empty - try a brief delay and check again
    sleep 0.2
    if [[ ! -s "$transcript_path" ]]; then
        echo ""
        exit 0
    fi
fi

# Use the existing find-jira-ticket.sh script with error handling
result=$(~/.claude/scripts/find-jira-ticket.sh "$transcript_path" "$current_dir" 2>/dev/null)
exit_code=$?

# Handle script failures gracefully
if [[ $exit_code -ne 0 || -z "$result" ]]; then
    echo ""
    exit 0
fi

echo "$result"