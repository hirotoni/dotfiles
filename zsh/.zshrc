# ---------- brew prefix キャッシュ ----------
export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"

# ---------- plugins ----------
if [[ -d ~/.zsh/plugins ]]; then
  for f in ~/.zsh/plugins/*.zsh(N); do source "$f"; done
fi

# ---------- rc ----------
if [[ -d ~/.zsh/rc ]]; then
  for f in ~/.zsh/rc/*.zsh(N); do source "$f"; done
fi

# ---------- local（マシン固有、Git管理外） ----------
[[ -f ~/.zsh/local.zsh ]] && source ~/.zsh/local.zsh

# ---------- completion ----------
autoload -Uz compinit && compinit -u -C

# ---------- anyenv ----------
command -v anyenv >/dev/null 2>&1 && eval "$(anyenv init -)"
