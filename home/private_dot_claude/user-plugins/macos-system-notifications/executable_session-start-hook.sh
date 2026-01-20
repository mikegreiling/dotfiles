#!/bin/sh
# SessionStart hook - sets up tmux notification auto-dismiss and checks dependencies

# Check if terminal-notifier is installed
if ! command -v terminal-notifier &>/dev/null; then
  echo "Warning: terminal-notifier not installed. Visual notifications disabled." >&2
  echo "Install with: brew install terminal-notifier" >&2
  exit 0
fi

# If not in tmux, exit early (notifications will still work, just no auto-dismiss on pane focus)
[ -z "$TMUX" ] && exit 0

# Set up tmux hook for auto-dismissing notifications on pane selection
# This is idempotent - multiple sessions can set it without conflicts
tmux set-hook -g after-select-pane 'run-shell "session_id=\$(tmux show-options -pv @meta.claude.session_id 2>/dev/null); [ -n \"\$session_id\" ] && command -v terminal-notifier &>/dev/null && terminal-notifier -remove \"\$session_id\" &>/dev/null || true"' 2>/dev/null || true
