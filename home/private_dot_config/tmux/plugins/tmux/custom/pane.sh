show_pane() {
  local index icon color text session_id lifecycle_icon

  index=$1
  icon=$(get_tmux_option "@catppuccin_pane_icon" "")
  color=$(get_tmux_option "@catppuccin_pane_color" "$thm_orange")

  # Build dynamic text with truncated session ID and lifecycle icon
  session_id=$(tmux display-message -p "#{@claude_session}")
  if [ -n "$session_id" ]; then
    # Truncate session_id to first 8 characters
    session_id=${session_id:0:8}

    # Determine lifecycle icon based on @claude_session_set_on value
    lifecycle_on=$(tmux display-message -p "#{@claude_session_set_on}")
    case "$lifecycle_on" in
      "SessionStart") lifecycle_icon=" ▶" ;;
      "SessionEnd") lifecycle_icon=" ■" ;;
      "Stop") lifecycle_icon=" ⬣" ;;
      *) lifecycle_icon="" ;;
    esac

    text="$session_id$lifecycle_icon"
  else
    text=" "
  fi

  # Output styled format only when @claude_session exists
  # Manually style to match Catppuccin without using build_status_module
  if [ -n "$session_id" ]; then
    echo "#[fg=$color] $icon #[fg=default]$text "
  else
    echo ""
  fi
}
