# ---------- Homebrew ----------
# クリーンな macOS では brew が PATH に無い（Homebrew は shellenv の追記を
# 利用者に任せており、その追記はこの dotfiles の管理外）。plugins と prompt は
# $HOMEBREW_PREFIX 配下を source するので、ここで自力で解決しておく。
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  _brew=$(command -v brew 2>/dev/null)
  [[ -x "$_brew" ]] || _brew=/opt/homebrew/bin/brew # Apple Silicon
  [[ -x "$_brew" ]] || _brew=/usr/local/bin/brew    # Intel
  # shellenv は HOMEBREW_PREFIX に加えて PATH / MANPATH も設定する
  [[ -x "$_brew" ]] && eval "$("$_brew" shellenv)"
  unset _brew
fi

if [[ -z "$HOMEBREW_PREFIX" ]]; then
  print -u2 "dotfiles: Homebrew が見つからないため zsh プラグイン（abbr / autosuggestions / syntax-highlighting / git-prompt）を読み込みません。https://brew.sh で導入し、'exec zsh' で再読み込みしてください。"
fi

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
# zsh-completions（Homebrew）は brew shellenv が足す fpath
# ($HOMEBREW_PREFIX/share/zsh/site-functions) に含まれない配布先を持つため、
# ここで個別に足す。compinit より前に追加する必要がある。
[[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]] && fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
# -C は dump のフレッシュネス確認自体を省略するため、fpath に追加した
# zsh-completions が ~/.zcompdump に反映されなくなる。-u のみ残す。
autoload -Uz compinit && compinit -u

# ---------- anyenv ----------
# `anyenv install --init` を済ませていないマシンでは `anyenv init -` が
# 「definition root が無い」と警告して exit 1 する。起動のたびに警告を並べない
# よう、成功したときだけ eval する。anyenv を使うマシンでは一度だけ
# `anyenv install --init` を実行すること。
if command -v anyenv >/dev/null 2>&1; then
  if _anyenv_init=$(anyenv init - 2>/dev/null); then
    eval "$_anyenv_init"
  fi
  unset _anyenv_init
fi
