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
# 探索先候補は zsh/.zshrc と共有するため homebrew-prefixes.txt に集約している。
if ! command -v brew >/dev/null 2>&1 && [[ -r "$DOTFILES_DIR/homebrew-prefixes.txt" ]]; then
  while read -r brew_bin; do
    case "$brew_bin" in
      '' | '#'*) continue ;;
    esac
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      break
    fi
  done <"$DOTFILES_DIR/homebrew-prefixes.txt"
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

# Homebrew の mermaid-cli は puppeteer が使う chrome-headless-shell を同梱しない
# （formula の test が mmdc の "Could not find chrome-headless-shell" を期待している）。
# mmdc が実行時に探すビルドと一致させるため、npx ではなく formula 同梱の
# puppeteer で取得する。取得済みなら何もせずに終わり、brew upgrade で同梱
# puppeteer が上がった後に再実行すれば新しいビルドを取得する。chromium cask は
# 2026-09 に Gatekeeper 非適合で disabled になったので使えない。
# mermaid 図は nvim の描画にしか使わないので、失敗しても他の target の導入は止めない。
puppeteer_cli="$(brew --prefix mermaid-cli)/libexec/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/.bin/puppeteer"
if [[ ! -x "$puppeteer_cli" ]]; then
  cat >&2 <<EOS
Warning: puppeteer bundled with mermaid-cli not found at:
  $puppeteer_cli
The mermaid-cli formula layout may have changed. mmdc cannot render without chrome-headless-shell.
EOS
elif ! "$puppeteer_cli" browsers install chrome-headless-shell; then
  echo "Warning: could not install chrome-headless-shell. mmdc cannot render until '$puppeteer_cli browsers install chrome-headless-shell' succeeds." >&2
fi

backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backed_up=0
config_placed=0

# 退避は stow より前に走る。トラップが無いと、stow が衝突で失敗した時点で
# set -e が即 exit し、利用者は設定がどこへ移されたか知らないまま取り残される。
# config_placed=1 は stow 成功後にのみ立つ。stow より後の手順（pre-commit
# install 等）が失敗しても、退避した元ファイルへの書き戻しは既に張られた
# シンボリックリンクを壊すだけなので、案内を出さない。
report_backup_dir() {
  local status=$?
  if [[ $status -ne 0 && $backed_up -eq 1 && $config_placed -eq 0 ]]; then
    echo "Install failed. Your original files are in: $backup_dir" >&2
  fi
}
trap report_backup_dir EXIT

# acd710b より前の install.sh は ~/.config を作らずに stow していたため、~/.config
# ごとリポジトリの <pkg>/.config を指すリンクに畳まれたマシンが残っている。その状態
# では下の mkdir -p も退避も stow も素通りし、畳みが解けない。退避より前に解くのは、
# 畳み中に作業ツリーへ書かれた管理外の ~/.config/<x> を退避ループが「~/.config に
# ある実体」と見なして退避先へ動かさないようにするため。
for folded_config in "$DOTFILES_DIR"/*/.config; do
  if [[ ! -L "$HOME/.config" || ! "$HOME/.config" -ef "$folded_config" ]]; then
    continue
  fi
  folded_pkg="$(basename "$(dirname "$folded_config")")"

  # stow は git の追跡状態を見ずにパッケージ内のものをすべてリンクする。管理外の
  # 項目を作業ツリーに残すと、畳みを解いても ~/.config/<x> がリポジトリを指し続ける。
  # 読めないディレクトリの glob は黙って空になるので、列挙の前に確かめる。
  if [[ ! -r "$folded_config" || ! -x "$folded_config" ]]; then
    echo "Error: $HOME/.config is a link to $folded_config, which cannot be listed. Nothing was changed." >&2
    exit 1
  fi
  shopt -s nullglob dotglob
  entries=("$folded_config"/*)
  shopt -u nullglob dotglob
  unmanaged=()
  # bash 3.2 の set -u は空配列の "${a[@]}" を未定義変数として扱う。
  for entry in ${entries[@]+"${entries[@]}"}; do
    name="$(basename "$entry")"
    if ! tracked="$(git -C "$DOTFILES_DIR" ls-files -- ":(literal)$folded_pkg/.config/$name")"; then
      cat >&2 <<EOS
Error: $HOME/.config is a link into this repository ($folded_config),
but git could not tell which files under it are tracked. Nothing was changed.
EOS
      exit 1
    fi
    if [[ -z "$tracked" ]]; then
      unmanaged+=("$name")
    fi
  done

  if ! rm "$HOME/.config"; then
    echo "Error: could not remove the link $HOME/.config -> $folded_config. Nothing was changed." >&2
    exit 1
  fi
  if ! mkdir "$HOME/.config"; then
    cat >&2 <<EOS
Error: removed the link $HOME/.config but could not create a directory there.
Restore the link with:
  ln -s "$folded_config" "$HOME/.config"
EOS
    exit 1
  fi
  echo "Unfolded: $HOME/.config was a link to $folded_config; it is now a directory."

  failed_moves=()
  for name in ${unmanaged[@]+"${unmanaged[@]}"}; do
    if mv "$folded_config/$name" "$HOME/.config/$name"; then
      echo "Moved unmanaged file out of the repository: $folded_config/$name -> $HOME/.config/$name"
    else
      failed_moves+=("$name")
    fi
  done
  if [[ ${#failed_moves[@]} -gt 0 ]]; then
    echo "Error: $HOME/.config was unfolded, but these files written by other tools could not be moved out of the repository. Move them yourself:" >&2
    for name in "${failed_moves[@]}"; do
      echo "  mv \"$folded_config/$name\" \"$HOME/.config/$name\"" >&2
    done
    if [[ "$folded_pkg" != "$TARGET" ]]; then
      echo "Then run '$0 $folded_pkg' and '$0 $TARGET'." >&2
    else
      echo "Then re-run this script." >&2
    fi
    exit 1
  fi

  # リンクを外すと、畳まれていた側のパッケージの ~/.config/<x> も消える。
  if [[ "$folded_pkg" != "$TARGET" ]] && ! stow -d "$DOTFILES_DIR" -t "$HOME" --ignore='.DS_Store' "$folded_pkg"; then
    cat >&2 <<EOS
Error: $HOME/.config was unfolded, but stow could not re-link $folded_pkg.
Move or remove each path it listed above under $HOME, then run '$0 $folded_pkg' and '$0 $TARGET'.
EOS
    exit 1
  fi
  break
done

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

# stow はリンク先にディレクトリが無いとディレクトリごと 1 本のリンクに畳む。
# ~/.config が無いまま stow すると ~/.config 自体がリポジトリを指し、管理外の
# ツールが書く設定や資格情報まで作業ツリーに入る。先に実ディレクトリを作る。
if [[ -d "$DOTFILES_DIR/$TARGET/.config" ]]; then
  mkdir -p "$HOME/.config"
fi

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
config_placed=1

if ! (cd "$DOTFILES_DIR" && pre-commit install); then
  echo "Warning: dotfiles config for $TARGET is in place, but pre-commit hook installation failed. Re-run '(cd \"$DOTFILES_DIR\" && pre-commit install)' yourself." >&2
  exit 1
fi

if [[ "$TARGET" == "zsh" ]]; then
  echo "Done! Run 'exec zsh' to reload."
else
  echo "Done!"
fi
