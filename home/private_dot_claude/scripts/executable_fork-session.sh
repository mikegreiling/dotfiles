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
  echo "Usage: $(basename "$0") [--mcp] <hex-substring>"
  echo "  --mcp: Use MCP configuration"
  exit 1
fi

HEX_SUBSTRING="$1"

# Validate hex substring (at least 4 characters, hex digits with optional dashes)
if [[ ! "$HEX_SUBSTRING" =~ ^[0-9a-f-]{4,}$ ]]; then
  echo "Error: Argument must be at least 4 hexadecimal characters (dashes allowed)"
  exit 1
fi

# Ensure it contains at least 4 actual hex digits (not just dashes)
HEX_ONLY=$(echo "$HEX_SUBSTRING" | tr -d '-')
if [[ ${#HEX_ONLY} -lt 4 ]]; then
  echo "Error: Argument must contain at least 4 hexadecimal characters"
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

SESSION_IDS=""
if [[ -n "$PROJECT_MATCHES" ]]; then
  # Extract session IDs from project files
  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      SESSION_ID=$(extract_session_id "$(basename "$file")")
      if [[ -n "$SESSION_ID" ]]; then
        SESSION_IDS="${SESSION_IDS}${SESSION_ID}"$'\n'
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

  # Extract session IDs from todo files (ignoring -agent- suffixes)
  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      SESSION_ID=$(extract_session_id "$(basename "$file")")
      if [[ -n "$SESSION_ID" ]]; then
        SESSION_IDS="${SESSION_IDS}${SESSION_ID}"$'\n'
      fi
    fi
  done <<< "$TODO_MATCHES"
fi

# Get unique session IDs and count them
UNIQUE_SESSIONS=$(echo "$SESSION_IDS" | grep -v '^$' | sort -u)
SESSION_COUNT=$(echo "$UNIQUE_SESSIONS" | grep -c '^')

if [[ $SESSION_COUNT -eq 0 ]]; then
  echo "Error: No valid session IDs could be extracted from matching files"
  exit 1
elif [[ $SESSION_COUNT -gt 1 ]]; then
  echo "Error: Multiple unique sessions found matching '${HEX_SUBSTRING}':"
  echo "$UNIQUE_SESSIONS" | sed 's/^/  - /'
  echo ""
  echo "Please provide a longer substring to uniquely identify the session"
  exit 1
fi

# Resume the single session
SESSION_ID="$UNIQUE_SESSIONS"
echo "Found session: $SESSION_ID"
echo "Resuming with claude..."
exec $COMMAND --resume "$SESSION_ID"
