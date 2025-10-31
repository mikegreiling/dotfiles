
# re-run all chpwd and precmd hooks and tell p10k to refresh the prompt
# https://github.com/oxcl/.dotfiles/blob/79317b7cfa/home/.config/zsh/custom/p10k_custom.plugin.zsh#L4-L10
refresh-prompt() {
  local f
  for f in chpwd "${chpwd_functions[@]}" precmd "${precmd_functions[@]}"; do
    [[ "${+functions[$f]}" == 0 ]] || "$f" &>/dev/null || true
  done
  command -v p10k &>/dev/null && {
    p10k display -r
  }
}

# Display tmux user options (@meta.claude.*) for all panes in current window
printmeta() {
  local current_pane="$TMUX_PANE"

  tmux list-panes -F "#{pane_id}:#{pane_title}" | while IFS=: read -r pane_id pane_title; do
    local is_current=""
    if [ "$pane_id" = "$current_pane" ]; then
      is_current=" (CURRENT)"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Pane: $pane_id$is_current"
    echo "Label: $pane_title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local user_opts=$(tmux show-options -p -t "$pane_id" 2>/dev/null | grep "^@")
    if [ -n "$user_opts" ]; then
      echo "$user_opts"
    else
      echo "(no user options set)"
    fi
    echo ""
  done
}
