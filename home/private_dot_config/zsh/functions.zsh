
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
