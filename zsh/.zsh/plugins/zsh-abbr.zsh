_abbr_plugin="$HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh"
if [[ ! -r "$_abbr_plugin" ]]; then
  unset _abbr_plugin
  return
fi
source "$_abbr_plugin"
unset _abbr_plugin

ABBR_LOG_AVAILABLE_ABBREVIATION_AFTER=1

# zsh-abbr 6.5.2 の abbr は、-S でも呼ぶたびに job queue の pop で外部コマンド
# rm を起動し、1 件あたり約 3ms かかる。そこで abbr -S と同じ形式（キーと展開を
# ${(qqq)...} で囲む。zsh-abbr.zsh の _abbr:util_add を参照）で、セッション略語の
# 連想配列に直接入れる。警告や拒否が要る場合（同名コマンドがある、定義済み等）と、
# zsh-abbr の内部が変わって配列が無い場合は、abbr -S にそのまま任せる。
session_abbr() {
  local def name expansion
  for def in "$@"; do
    name=${def%%=*}
    expansion=${def#*=}
    if [[ ${(t)ABBR_REGULAR_SESSION_ABBREVIATIONS} != association* ||
          -z $name || -z $expansion || $name == $def ||
          -n ${ABBR_REGULAR_SESSION_ABBREVIATIONS[${(qqq)name}]} ]] ||
       (( $+commands[$name] && ! $+aliases[$name] )); then
      abbr -S --quieter "$def"
      continue
    fi
    ABBR_REGULAR_SESSION_ABBREVIATIONS[${(qqq)name}]=${(qqq)expansion}
  done
}

session_abbr lg='lazygit'
