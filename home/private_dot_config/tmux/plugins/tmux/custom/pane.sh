show_pane() {
  local index icon color text

  index=$1
  icon=$(get_tmux_option "@catppuccin_pane_icon" "")
  color=$(get_tmux_option "@catppuccin_pane_color" "$thm_orange")
  text=$(get_tmux_option "@catppuccin_pane_text" "#{=8:@meta.claude.session_id}#{?#{==:#{@meta.claude.status},running},[▶],#{?#{==:#{@meta.claude.status},stopped},[⏸],#{?#{&&:#{@meta.claude.session_id},#{!@meta.claude.status}},[■],#{?@meta.claude.status,[?],}}}}")

  # Output raw conditional format - shown only when @meta.claude.session_id exists
  # Manually style to match Catppuccin without using build_status_module
  echo "#{?@meta.claude.session_id,#[fg=$color] $icon #[fg=default]$text ,}"
}
