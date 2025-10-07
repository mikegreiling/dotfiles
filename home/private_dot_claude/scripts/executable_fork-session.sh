#!/usr/bin/env bash

# fork-session.sh
# Find and resume a Claude session by partial session ID

set -euo pipefail

# Determine which command to use
CLAUDE_BIN="$HOME/.claude/local/claude"
if [[ "${1:-}" == "--mcp" ]]; then
  COMMAND="$CLAUDE_BIN --strict-mcp-config --mcp-config $HOME/.claude/.mcp-bstock-chores.json"
  shift
else
  COMMAND="$CLAUDE_BIN --strict-mcp-config"
fi

# Check for hex substring argument
if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") [--mcp] <8-char-hex-substring>"
  echo "  --mcp: Use MCP configuration"
  exit 1
fi

HEX_SUBSTRING="$1"

# Validate hex substring (at least 8 characters, only hex digits)
if [[ ! "$HEX_SUBSTRING" =~ ^[0-9a-f]{8,}$ ]]; then
  echo "Error: Argument must be at least 8 hexadecimal characters"
  exit 1
fi

# Function to extract session ID from filename
extract_session_id() {
  local filename="$1"
  # Extract the first UUID (8-4-4-4-12 format) from the filename
  # This handles both .jsonl files and -agent- suffixed todo files
  if [[ "$filename" =~ ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}) ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}

# Step 1: Search project transcript files first (authoritative source)
PROJECT_MATCHES=$(find ~/.claude/projects -type f -name "*${HEX_SUBSTRING}*.jsonl" 2>/dev/null || true)

if [[ -n "$PROJECT_MATCHES" ]]; then
  # Extract unique session IDs from project files
  declare -A UNIQUE_SESSIONS
  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      SESSION_ID=$(extract_session_id "$(basename "$file")")
      if [[ -n "$SESSION_ID" ]]; then
        UNIQUE_SESSIONS["$SESSION_ID"]=1
      fi
    fi
  done <<< "$PROJECT_MATCHES"
else
  # Step 2: Fallback to todo files for newly-started sessions
  TODO_MATCHES=$(find ~/.claude/todos -type f -name "*${HEX_SUBSTRING}*.json" 2>/dev/null || true)

  if [[ -z "$TODO_MATCHES" ]]; then
    echo "Error: No session files found containing '${HEX_SUBSTRING}'"
    exit 1
  fi

  # Extract unique session IDs from todo files (ignoring -agent- suffixes)
  declare -A UNIQUE_SESSIONS
  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      SESSION_ID=$(extract_session_id "$(basename "$file")")
      if [[ -n "$SESSION_ID" ]]; then
        UNIQUE_SESSIONS["$SESSION_ID"]=1
      fi
    fi
  done <<< "$TODO_MATCHES"
fi

# Check how many unique sessions we found
SESSION_COUNT=${#UNIQUE_SESSIONS[@]}

if [[ $SESSION_COUNT -eq 0 ]]; then
  echo "Error: No valid session IDs could be extracted from matching files"
  exit 1
elif [[ $SESSION_COUNT -gt 1 ]]; then
  echo "Error: Multiple unique sessions found matching '${HEX_SUBSTRING}':"
  for session in "${!UNIQUE_SESSIONS[@]}"; do
    echo "  - $session"
  done
  echo ""
  echo "Please provide a longer substring to uniquely identify the session"
  exit 1
fi

# Get the single session ID
for SESSION_ID in "${!UNIQUE_SESSIONS[@]}"; do
  echo "Found session: $SESSION_ID"
  echo "Resuming with claude..."
  exec $COMMAND --resume "$SESSION_ID"
done
