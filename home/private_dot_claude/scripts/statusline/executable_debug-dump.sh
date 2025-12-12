#!/bin/bash

# Debug Dump Script for ccstatusline
# Reads JSON from stdin, extracts session_id, and dumps to /tmp for inspection
# Usage: echo '{"session_id":"abc123..."}' | ./debug-dump.sh

# Read JSON from stdin
json_input=$(cat)

# Extract session_id using jq
session_id=$(echo "$json_input" | jq -r '.session_id')

# Check if jq extraction succeeded
if [[ "$session_id" == "null" || -z "$session_id" ]]; then
    echo "[debug:no-session]"
    exit 0
fi

# Truncate session_id to first 8 characters for filename
session_hash="${session_id:0:8}"

# Create debug filename
debug_file="/tmp/${session_hash}-statusline-debug.json"

# Write the complete JSON payload to debug file (overwrites if exists)
echo "$json_input" | jq '.' > "$debug_file" 2>/dev/null

# Output debug indicator for statusline display
echo "[debug]"
