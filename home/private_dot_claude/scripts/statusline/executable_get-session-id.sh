#!/bin/bash

# Session ID Extraction Script for ccstatusline
# Reads JSON from stdin and outputs first 8 characters of session_id
# Usage: echo '{"session_id":"93de0619-332d-4d9c-9397-64ef060d4906"}' | ./get-session-id.sh

json_input=$(cat)
session_id=$(echo "$json_input" | jq -r '.session_id')

# Check if jq extraction succeeded
if [[ "$session_id" == "null" || -z "$session_id" ]]; then
    echo ""
    exit 0
fi

# Truncate to first 8 characters
echo "${session_id:0:8}"