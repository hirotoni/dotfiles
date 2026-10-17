#!/usr/bin/env bash
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
unit_dir="$repo_root/nvim/.config/nvim"

# --config-path is explicit so the result does not depend on where a given
# stylua version looks for its config. `stylua --help` documents the default
# as the current directory (the repo root under pre-commit, which has no
# .stylua.toml); 2.6.0 actually searches upward from each file, but a version
# that follows the help text would apply the defaults (tabs, 120 columns).
stylua --check --config-path "$unit_dir/.stylua.toml" "$@"
rc=$?
if [ "$rc" -eq 1 ]; then
  cat >&2 <<EOF
整形が .stylua.toml と合わないファイルがある（上の「Diff in」の行）。
直すには repo ルートで: stylua --config-path nvim/.config/nvim/.stylua.toml <上のパス>
整形の修正は他の変更と別のコミットにする。
EOF
fi
exit "$rc"
