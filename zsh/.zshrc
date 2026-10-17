# ---------- Homebrew ----------
# クリーンな macOS では brew が PATH に無い（Homebrew は shellenv の追記を
# 利用者に任せており、その追記はこの dotfiles の管理外）。plugins と prompt は
# $HOMEBREW_PREFIX 配下を source するので、ここで自力で解決しておく。
# 探索先候補は install.sh と共有するため homebrew-prefixes.txt に集約している。
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  _brew=$(command -v brew 2>/dev/null)
  if [[ ! -x "$_brew" ]]; then
    # このファイル自身（stow で ~ にリンクされたシンボリックリンク）を :A で実体
    # パスに解決し、そこから 2 階層上がって dotfiles リポジトリのルートを求める。
    _dotfiles_dir=${${(%):-%N}:A:h:h}
    if [[ -r "$_dotfiles_dir/homebrew-prefixes.txt" ]]; then
      while read -r _brew_candidate; do
        case "$_brew_candidate" in
          ''|'#'*) continue ;;
        esac
        if [[ -x "$_brew_candidate" ]]; then
          _brew=$_brew_candidate
          break
        fi
      done < "$_dotfiles_dir/homebrew-prefixes.txt"
    fi
    unset _dotfiles_dir _brew_candidate
  fi
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
# `anyenv init -` が PATH や *ENV_ROOT を設定するのは $ANYENV_ROOT/envs 直下の
# env ごとだけで、env に依らず出すのは素通しの anyenv 関数と補完ファイルの
# source だけである。init は bash を何段も起動して遅いので、env が 1 つも無ければ
# 呼ばずに補完ファイルだけを読む。補完ファイルの場所は init と同じく、anyenv の
# 実体（libexec/anyenv）の 2 階層上から求める。env の判定は anyenv-envs と同じく、
# リンク先も含めて envs 直下のディレクトリを数える。
# `anyenv install --init` を済ませていないマシンでは `anyenv init -` が
# 「definition root が無い」と警告して exit 1 する。起動のたびに警告を並べない
# よう、成功したときだけ eval する。anyenv を使うマシンでは一度だけ
# `anyenv install --init` を実行すること。
if command -v anyenv >/dev/null 2>&1; then
  _anyenv_envs=(${ANYENV_ROOT:-$HOME/.anyenv}/envs/*(N-/))
  if (( $#_anyenv_envs )); then
    if _anyenv_init=$(anyenv init - 2>/dev/null); then
      eval "$_anyenv_init"
    fi
  else
    _anyenv_comp=${commands[anyenv]:A:h:h}/completions/anyenv.zsh
    [[ -r $_anyenv_comp ]] && source "$_anyenv_comp"
  fi
  unset _anyenv_envs _anyenv_init _anyenv_comp
fi
