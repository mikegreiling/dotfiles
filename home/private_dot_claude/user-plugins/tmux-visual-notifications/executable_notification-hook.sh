#!/bin/sh
# Claude Code notification hook - shows sticky macOS notifications with click-to-activate

input=$(cat)

# Exit early if not in tmux or terminal-notifier not available
[ -z "$TMUX" ] && exit 0
command -v terminal-notifier &>/dev/null || exit 0

# Parse notification details from JSON input
session_id=$(echo "$input" | jq -r ".session_id // \"claude\"")
notif_type=$(echo "$input" | jq -r ".notification_type // \"stop\"")

# Detect which terminal emulator is running this tmux session
detect_terminal() {
  local pid=$(tmux display-message -p "#{client_pid}" 2>/dev/null)
  while [ "$pid" -gt 1 ] 2>/dev/null; do
    local comm=$(ps -o comm= -p "$pid" 2>/dev/null | tr "[:upper:]" "[:lower:]")
    case "$comm" in
      *ghostty*) echo "Ghostty"; return;;
      *iterm*) echo "iTerm"; return;;
      *kitty*) echo "kitty"; return;;
      *terminal*) echo "Terminal"; return;;
      *warp*) echo "Warp"; return;;
    esac
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d " ")
  done
}

terminal_app=$(detect_terminal)

# Send notification based on type
# Note: We don't background terminal-notifier (no &) because -execute needs to register with macOS
if [ -n "$terminal_app" ]; then
  case "$notif_type" in
    idle_prompt)
      terminal-notifier -title "Claude Code" -message "Session idle - awaiting input" -sound Glass -group "$session_id" -execute "osascript -e 'tell application \"$terminal_app\" to activate'" >/dev/null 2>&1
      ;;
    permission_prompt)
      terminal-notifier -title "Claude Code" -message "Input requested" -sound Glass -group "$session_id" -execute "osascript -e 'tell application \"$terminal_app\" to activate'" >/dev/null 2>&1
      ;;
    elicitation_dialog)
      terminal-notifier -title "Claude Code" -message "Input requested" -sound Glass -group "$session_id" -execute "osascript -e 'tell application \"$terminal_app\" to activate'" >/dev/null 2>&1
      ;;
    stop)
      terminal-notifier -title "Claude Code" -message "Session stopped" -sound Glass -group "$session_id" -execute "osascript -e 'tell application \"$terminal_app\" to activate'" >/dev/null 2>&1
      ;;
  esac
else
  # Fallback without click-to-activate if terminal detection fails
  case "$notif_type" in
    idle_prompt)
      terminal-notifier -title "Claude Code" -message "Session idle - awaiting input" -sound Glass -group "$session_id" >/dev/null 2>&1
      ;;
    permission_prompt)
      terminal-notifier -title "Claude Code" -message "Input requested" -sound Glass -group "$session_id" >/dev/null 2>&1
      ;;
    elicitation_dialog)
      terminal-notifier -title "Claude Code" -message "Input requested" -sound Glass -group "$session_id" >/dev/null 2>&1
      ;;
    stop)
      terminal-notifier -title "Claude Code" -message "Session stopped" -sound Glass -group "$session_id" >/dev/null 2>&1
      ;;
  esac
fi
