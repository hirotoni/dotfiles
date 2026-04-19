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

brew bundle --file="$DOTFILES_DIR/Brewfile"

backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

case "$TARGET" in
  zsh)
    for target in .zshrc .zshenv .zsh; do
      if [[ -e "$HOME/$target" && ! -L "$HOME/$target" ]]; then
        mkdir -p "$backup_dir"
        mv "$HOME/$target" "$backup_dir/"
      fi
    done
    stow -d "$DOTFILES_DIR" -t "$HOME" --ignore='.DS_Store' zsh
    echo "Done! Run 'exec zsh' to reload."
    ;;
  nvim)
    if [[ -e "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
      mkdir -p "$backup_dir"
      mv "$HOME/.config/nvim" "$backup_dir/"
    fi
    stow -d "$DOTFILES_DIR" -t "$HOME" --ignore='.DS_Store' nvim
    echo "Done!"
    ;;
  cmux)
    if [[ -e "$HOME/.config/cmux" && ! -L "$HOME/.config/cmux" ]]; then
      mkdir -p "$backup_dir"
      mv "$HOME/.config/cmux" "$backup_dir/"
    fi
    if [[ -e "$HOME/.hammerspoon" && ! -L "$HOME/.hammerspoon" ]]; then
      mkdir -p "$backup_dir"
      mv "$HOME/.hammerspoon" "$backup_dir/"
    fi
    stow -d "$DOTFILES_DIR" -t "$HOME" --ignore='.DS_Store' cmux
    echo "Done!"
    ;;
esac

(cd "$DOTFILES_DIR" && pre-commit install)
