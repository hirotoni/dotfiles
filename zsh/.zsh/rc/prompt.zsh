# zsh-git-prompt
alias python='python3'
autoload -Uz colors && colors
source "$HOMEBREW_PREFIX/opt/zsh-git-prompt/zshrc.sh"

git_prompt() {
  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ]; then
    PROMPT="%F{green}%n%f:%F{blue}%~%f $(git_super_status) "$'\n'"%# "
  else
    PROMPT="%F{green}%n%f:%F{blue}%~%f "$'\n'"%# "
  fi
  PROMPT='%{$fg[yellow]%}[%D{%y/%m/%d} %D{%H:%M:%S}] '$PROMPT
}

add_newline() {
  if [[ -z $PS1_NEWLINE_LOGIN ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}

precmd() {
  git_prompt
  add_newline
}

# group completion candidates
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''

setopt auto_cd