#!/bin/sh
# SessionStart hook - sets up tmux notification auto-dismiss and checks dependencies

# Check if terminal-notifier is installed
if ! command -v terminal-notifier &>/dev/null; then
  # Output JSON - SessionStart adds stdout to Claude's context for visibility
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ""
  },
  "suppressOutput": true,
  "systemMessage": "\n⚠️ terminal-notifier is not installed. Visual notifications are disabled.\n\nTo install: brew install terminal-notifier\nTo disable this message, uninstall the macos-system-notifications plugin."
}
EOF
  exit 0
fi

# If not in tmux, exit early (notifications will still work, just no auto-dismiss on pane focus)
[ -z "$TMUX" ] && exit 0

# Set up tmux hook for auto-dismissing notifications on pane selection
# This is idempotent - multiple sessions can set it without conflicts
# The 13731138 is a pseudo random unique index which ensures that this hook does not clobber other hooks
tmux set-hook -g after-select-pane[13731138] 'run-shell "session_id=\$(tmux show-options -pv @meta.claude.session_id 2>/dev/null); [ -n \"\$session_id\" ] && command -v terminal-notifier &>/dev/null && terminal-notifier -remove \"\$session_id\" &>/dev/null || true"' 2>/dev/null || true
