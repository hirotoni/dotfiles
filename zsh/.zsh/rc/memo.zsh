# session_abbr は plugins/zsh-abbr.zsh が定義する。Homebrew 未導入だと未定義になる
(( $+functions[session_abbr] )) || return

session_abbr mmt="memov2 todos new"
session_abbr mmtw="memov2 todos weekly"

session_abbr mmmw="memov2 memos weekly"
session_abbr mmmi="memov2 memos index"
session_abbr mmmb="memov2 memos browse"
session_abbr mmm="memov2 memos create"
session_abbr mmmr="memov2 memos rename"
