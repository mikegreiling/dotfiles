show_pane() {
  local index icon color text

  index=$1
  icon=$(get_tmux_option "@catppuccin_pane_icon" "")
  color=$(get_tmux_option "@catppuccin_pane_color" "$thm_orange")
  text=$(get_tmux_option "@catppuccin_pane_text" "#{=8:@claude_session}#{?#{==:#{@claude_session_set_on},SessionStart}, ▶,}#{?#{==:#{@claude_session_set_on},SessionEnd}, ■,}#{?#{==:#{@claude_session_set_on},Stop}, ⬣,}")

  # Output raw conditional format - shown only when @claude_session exists
  # Manually style to match Catppuccin without using build_status_module
  echo "#{?@claude_session,#[fg=$color] $icon #[fg=default]$text ,}"
}
