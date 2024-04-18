
# re-run all chpwd and precmd hooks and tell p10k to refresh the prompt
refresh-prompt() {
  local f
  for f in chpwd "${chpwd_functions[@]}" precmd "${precmd_functions[@]}"; do
    [[ "${+functions[$f]}" == 0 ]] || "$f" &>/dev/null || true
  done
  command -v p10k &>/dev/null && {
    p10k display -r
  }
}
