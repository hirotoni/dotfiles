abbr -S --quieter mmt="memov2 todos new"
abbr -S --quieter mmtw="memov2 todos weekly"
abbr -S --quieter mmmw="memov2 memos weekly"
abbr -S --quieter mmmi="memov2 memos index"
abbr -S --quieter mmmb="memov2 memos browse"

memo-search() {
  memov2 memos list --short | fzf \
    --disabled \
    --bind "change:reload:memov2 memos search --short {q}" \
  | cut -f2 | xargs memov2 memos open
}
abbr -S --quieter mmms="memo-search"

memo-rename() {
  memov2 memos list | fzf | cut -f2 | xargs memov2 memos rename
}
abbr -S --quieter mmmr="memo-rename"

memo-new-with-category() {
  memov2 memos new "$1" --category "$(memov2 memos categories | peco)"
}
abbr -S --quieter mmm="memo-new-with-category"
