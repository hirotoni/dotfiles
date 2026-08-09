# abbr は plugins/zsh-abbr.zsh が読み込む。Homebrew 未導入だと未定義になる
command -v abbr >/dev/null 2>&1 || return

abbr -S --quieter mmt="memov2 todos new"
abbr -S --quieter mmtw="memov2 todos weekly"

abbr -S --quieter mmmw="memov2 memos weekly"
abbr -S --quieter mmmi="memov2 memos index"
abbr -S --quieter mmmb="memov2 memos browse"
abbr -S --quieter mmm="memov2 memos create"
abbr -S --quieter mmmr="memov2 memos rename"
