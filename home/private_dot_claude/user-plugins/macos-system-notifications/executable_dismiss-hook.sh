#!/bin/sh
# Dismiss notification hook - removes notifications for the current session

input=$(cat)

# Exit early if terminal-notifier not available
command -v terminal-notifier &>/dev/null || exit 0

# Parse session ID from JSON input
session_id=$(echo "$input" | jq -r ".session_id // \"\"")

# Dismiss notification for this session
[ -n "$session_id" ] && terminal-notifier -remove "$session_id" >/dev/null 2>&1 || true
