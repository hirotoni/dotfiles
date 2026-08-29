#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
brewfile="$repo_root/Brewfile"
nvim_lua_dir="$repo_root/nvim/.config/nvim/lua"

# gofmt ships inside the "go" formula; there is no separate "gofmt" Brewfile entry.
# macOS ships bash 3.2 (no associative arrays), so this exception is a case
# statement instead of a lookup table.
package_for_binary() {
  case "$1" in
    gofmt) echo "go" ;;
    *) echo "$1" ;;
  esac
}

binaries=()

# formatters_by_ft's filetype keys (lua, go, javascript, ...) are bare
# identifiers, so this range only picks up the quoted formatter names on the
# right-hand side.
conform_file="$nvim_lua_dir/plugins/conform.lua"
if [[ -f "$conform_file" ]]; then
  while IFS= read -r name; do
    binaries+=("$name")
  done < <(sed -n '/formatters_by_ft = {/,/^  },/p' "$conform_file" | grep -oE '"[a-zA-Z0-9_-]+"' | tr -d '"')
fi

# telescope.lua names the external `fd` binary as find_command's first element.
telescope_file="$nvim_lua_dir/plugins/telescope.lua"
if [[ -f "$telescope_file" ]]; then
  fd_name=$(grep -oE 'find_command = \{ *"[a-zA-Z0-9_-]+"' "$telescope_file" | grep -oE '"[a-zA-Z0-9_-]+"' | tr -d '"' || true)
  [[ -n "$fd_name" ]] && binaries+=("$fd_name")
fi

# vim.fn.executable(...), vim.fn.system(...) and jobstart({ "x", ... }) are the
# idioms this config uses to invoke an external binary by name, so scanning for
# them (repo-wide, not per file) catches new call sites without needing an
# update here.
while IFS= read -r name; do
  binaries+=("$name")
done < <(grep -rhoE 'vim\.fn\.executable\("[a-zA-Z0-9_-]+"\)' "$nvim_lua_dir" | grep -oE '"[a-zA-Z0-9_-]+"' | tr -d '"')

while IFS= read -r name; do
  binaries+=("$name")
done < <(grep -rhoE 'vim\.fn\.system\("[a-zA-Z0-9_-]+"\)' "$nvim_lua_dir" | grep -oE '"[a-zA-Z0-9_-]+"' | tr -d '"')

while IFS= read -r name; do
  binaries+=("$name")
done < <(grep -rhoE 'jobstart\(\{ *"[a-zA-Z0-9_-]+"' "$nvim_lua_dir" | grep -oE '"[a-zA-Z0-9_-]+"' | tr -d '"')

# mapfile/readarray need bash 4+; macOS ships bash 3.2, so dedup via a loop.
sorted_binaries=()
while IFS= read -r name; do
  sorted_binaries+=("$name")
done < <(printf '%s\n' "${binaries[@]}" | sort -u)
binaries=("${sorted_binaries[@]}")

missing=()
for bin in "${binaries[@]}"; do
  package="$(package_for_binary "$bin")"
  # Matches a bare formula/cask ("fd") or a tap-qualified one
  # ("owner/tap/im-select"), not an unrelated name that merely ends with the
  # same letters.
  if ! grep -qE "\"([a-zA-Z0-9_.-]+/)*${package}\"" "$brewfile"; then
    missing+=("$bin (expected a Brewfile entry for \"$package\")")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "nvim config references binaries not declared in Brewfile:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

echo "All nvim-referenced binaries are declared in the Brewfile."
