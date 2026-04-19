## command history with peco
setopt hist_ignore_all_dups
function peco-r(){
    BUFFER=$(history -n 1 | tail -r | peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-r; bindkey '^r' peco-r

# cd find with peco
function peco-cd () {
    # .gitなどは除外してディレクトリのみを検索
    local selected_dir=$(find . -maxdepth 4 -type d -not -path '*/.*' 2>/dev/null | peco)
    if [ -n "$selected_dir" ]; then
        cd "$selected_dir"
    fi
}
alias pd='peco-cd'

# enable directory history (cdr)
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
function peco-cdr() {
    local selected_dir=$(cdr -l | awk '{print $2}' | peco --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        # expand tilde (~) to full path
        BUFFER="cd ${selected_dir/\~/$HOME}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-cdr; bindkey '^g' peco-cdr

## branch checkout with peco
alias gb='git branch --sort=-authordate | cut -c 3- | peco | xargs git checkout' 