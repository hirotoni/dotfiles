#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 <target>"
  echo "  targets: zsh, nvim, cmux"
  exit 1
}

[[ $# -eq 0 ]] && usage

TARGET="$1"
[[ "$TARGET" != "zsh" && "$TARGET" != "nvim" && "$TARGET" != "cmux" ]] && usage

# ---------- Homebrew ----------
# Homebrew を入れただけでは brew は PATH に無い（shellenv の追記は利用者任せで、
# この dotfiles の管理外）。README の手順だけで動くようここで解決する。
if ! command -v brew >/dev/null 2>&1; then
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      break
    fi
  done
fi

if ! command -v brew >/dev/null 2>&1; then
  cat >&2 <<'EOS'
Error: Homebrew not found.
Install it first, then re-run this script:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
See https://brew.sh for details.
EOS
  exit 1
fi

brew bundle --file="$DOTFILES_DIR/Brewfile"

backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backed_up=0

# 退避は stow より前に走るので、stow が衝突で失敗すると（set -e で即 exit）
# 退避先を知らせないまま終わる。退避先はフラット配置で移動元のパスを復元
# できないため、失敗時に退避先を再掲して利用者が自力で戻せるようにする。
report_backup_dir() {
  local status=$?
  if [[ $status -ne 0 && $backed_up -eq 1 ]]; then
    echo "Install failed. Your original files are in: $backup_dir" >&2
  fi
}
trap report_backup_dir EXIT

# 退避対象はパッケージが $HOME に持ち込む最上位のパス。stow のパッケージ名は
# 常に $TARGET と等しい。
case "$TARGET" in
  zsh) backup_targets=(.zshrc .zshenv .zsh) ;;
  nvim) backup_targets=(.config/nvim) ;;
  cmux) backup_targets=(.config/cmux .config/ghostty .hammerspoon) ;;
esac

for target in "${backup_targets[@]}"; do
  if [[ -e "$HOME/$target" && ! -L "$HOME/$target" ]]; then
    mkdir -p "$backup_dir"
    mv "$HOME/$target" "$backup_dir/"
    backed_up=1
    echo "Backed up: $HOME/$target -> $backup_dir/$(basename "$target")"
  fi
done

stow -d "$DOTFILES_DIR" -t "$HOME" --ignore='.DS_Store' "$TARGET"

if [[ "$TARGET" == "zsh" ]]; then
  echo "Done! Run 'exec zsh' to reload."
else
  echo "Done!"
fi

(cd "$DOTFILES_DIR" && pre-commit install)
