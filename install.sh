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

# 退避は stow より前に走る。トラップが無いと、stow が衝突で失敗した時点で
# set -e が即 exit し、利用者は設定がどこへ移されたか知らないまま取り残される。
report_backup_dir() {
  local status=$?
  if [[ $status -ne 0 && $backed_up -eq 1 ]]; then
    echo "Install failed. Your original files are in: $backup_dir" >&2
  fi
}
trap report_backup_dir EXIT

# 退避対象は、パッケージが $HOME に持ち込む最上位のパスを列挙する。葉のファイル
# 単位にすると、パッケージにファイルが増えたときに列挙漏れが再発する。
case "$TARGET" in
  zsh) backup_targets=(.zshrc .zshenv .zsh) ;;
  nvim) backup_targets=(.config/nvim) ;;
  cmux) backup_targets=(.config/cmux .config/ghostty .hammerspoon) ;;
esac

for target in "${backup_targets[@]}"; do
  home_path="$HOME/$target"

  # 素通りさせてよいのは既にこのリポジトリの実体を指すリンクだけ。-L は「リンクな
  # ら stow のもの」と決めつけてリンク切れや他所を指すリンクを見逃し、-e はリンク
  # 先を辿るのでリンク切れをそもそも検出できない。-ef なら実体で比べられる。
  if [[ ! -e "$home_path" && ! -L "$home_path" ]]; then
    continue
  fi
  if [[ "$home_path" -ef "$DOTFILES_DIR/$TARGET/$target" ]]; then
    continue
  fi

  if ! mkdir -p "$backup_dir" || ! mv "$home_path" "$backup_dir/"; then
    cat >&2 <<EOS
Error: could not move $home_path out of the way.
Move or remove it yourself, then re-run this script:
  mv "$home_path" "$home_path.bak"
EOS
    exit 1
  fi
  backed_up=1
  echo "Backed up: $home_path -> $backup_dir/$(basename "$target")"
done

# stow のパッケージ名として $TARGET をそのまま渡せるのは、リポジトリ直下の
# パッケージディレクトリ名が受け付ける target 名と一致しているため。
#
# 退避を抜けてもなお stow が衝突する経路は残る。stow の所有判定はリンク先の実体で
# はなく表記で行うため、同じリポジトリを別経路で指すリンクは所有外になる。stow は
# 衝突を並べて中止するだけなので、次に何をすればよいかをここで補う。
if ! stow -d "$DOTFILES_DIR" -t "$HOME" --ignore='.DS_Store' "$TARGET"; then
  cat >&2 <<EOS
Error: stow could not link $TARGET.
Move or remove each path it listed above under $HOME, then re-run this script.
EOS
  exit 1
fi

if [[ "$TARGET" == "zsh" ]]; then
  echo "Done! Run 'exec zsh' to reload."
else
  echo "Done!"
fi

(cd "$DOTFILES_DIR" && pre-commit install)
