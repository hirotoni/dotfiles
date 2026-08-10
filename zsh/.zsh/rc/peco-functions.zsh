setopt hist_ignore_all_dups
function peco-r(){
    BUFFER=$(history -n 1 | tail -r | peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-r; bindkey '^r' peco-r

function peco-cd () {
    local selected_dir=$(find . -maxdepth 4 -type d -not -path '*/.*' 2>/dev/null | peco)
    if [ -n "$selected_dir" ]; then
        cd "$selected_dir"
    fi
}
alias pd='peco-cd'

autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
function peco-cdr() {
    local selected_dir=$(cdr -l | awk '{print $2}' | peco --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir/\~/$HOME}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-cdr; bindkey '^g' peco-cdr

alias gb='git branch --sort=-authordate | cut -c 3- | peco | xargs git checkout' 