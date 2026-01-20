#!/bin/sh
# Claude Code notification hook - shows sticky macOS notifications with click-to-activate

input=$(cat)

# Exit early if not in tmux or terminal-notifier not available
[ -z "$TMUX" ] && exit 0
command -v terminal-notifier &>/dev/null || exit 0

# Parse notification details from JSON input
session_id=$(echo "$input" | jq -r ".session_id // \"claude\"")
notif_type=$(echo "$input" | jq -r ".notification_type // \"stop\"")
message=$(echo "$input" | jq -r ".message // \"\"")

# Create truncated session ID for title (first 8 chars)
session_short=$(echo "$session_id" | cut -c1-8)

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

# Determine notification message (use payload message if available, otherwise fallback)
notif_message="$message"
if [ -z "$notif_message" ] || [ "$notif_message" = "Claude Code needs your attention" ]; then
  case "$notif_type" in
    idle_prompt) notif_message="Session idle - awaiting input";;
    permission_prompt) notif_message="Input requested";;
    elicitation_dialog) notif_message="Input requested";;
    stop) notif_message="Session stopped";;
    *) notif_message="Notification from Claude";;
  esac
fi

# Check for custom icon
icon_path="$HOME/.claude/assets/claude-logo.png"
icon_flag=""
if [ -f "$icon_path" ]; then
  icon_flag="-appIcon $icon_path"
fi

# Send notification based on type
# Note: We don't background terminal-notifier (no &) because -execute needs to register with macOS
if [ -n "$terminal_app" ]; then
  terminal-notifier -title "Claude Code ($session_short)" -message "$notif_message" -sound Glass -group "$session_id" $icon_flag -execute "osascript -e 'tell application \"$terminal_app\" to activate'" >/dev/null 2>&1
else
  # Fallback without click-to-activate if terminal detection fails
  terminal-notifier -title "Claude Code ($session_short)" -message "$notif_message" -sound Glass -group "$session_id" $icon_flag >/dev/null 2>&1
fi
