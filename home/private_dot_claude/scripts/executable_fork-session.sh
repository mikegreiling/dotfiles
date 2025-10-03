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

# Search for matching files in todos and history directories
MATCHES=$(find ~/.claude/todos ~/.claude/history -type f -name "*${HEX_SUBSTRING}*.json" 2>/dev/null || true)

if [[ -z "$MATCHES" ]]; then
  echo "Error: No session files found containing '${HEX_SUBSTRING}'"
  exit 1
fi

# Count matches
MATCH_COUNT=$(echo "$MATCHES" | wc -l | tr -d ' ')

if [[ "$MATCH_COUNT" -gt 1 ]]; then
  echo "Error: Multiple sessions found matching '${HEX_SUBSTRING}':"
  echo "$MATCHES"
  echo ""
  echo "Please provide a longer substring to uniquely identify the session"
  exit 1
fi

# Extract session ID from filename
MATCHED_FILE="$MATCHES"
FILENAME=$(basename "$MATCHED_FILE")

# Extract UUID pattern (8-4-4-4-12 format)
if [[ "$FILENAME" =~ ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}) ]]; then
  SESSION_ID="${BASH_REMATCH[1]}"
  echo "Found session: $SESSION_ID"
  echo "Resuming with claude..."
  exec $COMMAND --resume "$SESSION_ID"
else
  echo "Error: Could not extract session ID from filename: $FILENAME"
  exit 1
fi
