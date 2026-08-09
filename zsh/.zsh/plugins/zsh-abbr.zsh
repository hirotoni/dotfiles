_abbr_plugin="$HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh"
if [[ ! -r "$_abbr_plugin" ]]; then
  unset _abbr_plugin
  return
fi
source "$_abbr_plugin"
unset _abbr_plugin

ABBR_LOG_AVAILABLE_ABBREVIATION_AFTER=1

# lazygit
abbr -S --quieter lg='lazygit'
