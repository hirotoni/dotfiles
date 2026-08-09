#!/usr/bin/env bash
# Driver for running/driving this Neovim config inside tmux.
# Usage: driver.sh <command> [args]
#   check              headless config-load smoke check (no tmux needed)
#   syntax             loadfile() every .lua file in this unit (no tmux needed)
#   start [file]       launch nvim in a detached tmux session (120x35)
#   keys <keys...>     send tmux key names (e.g. C-n, Escape, Enter)
#   type <text>        send literal text (e.g. ':PackList' — follow with keys Enter)
#   snap [name]        capture the pane to $SNAPDIR/<name>.txt and print the path
#   text               print the current pane contents to stdout
#   stop               quit nvim and kill the tmux session
#   smoke              full start->interact->assert->stop flow
set -euo pipefail

SESSION=nvim-driver
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
UNIT=$(cd "$SCRIPT_DIR/../../.." && pwd)                # <repo>/nvim/.config/nvim
export XDG_CONFIG_HOME=$(dirname "$UNIT")               # so `nvim` finds $XDG_CONFIG_HOME/nvim
SNAPDIR=${SNAPDIR:-${TMPDIR:-/tmp}/nvim-driver-snaps}
mkdir -p "$SNAPDIR"

start() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  tmux new-session -d -s "$SESSION" -x 120 -y 35 \
    "cd '$UNIT' && XDG_CONFIG_HOME='$XDG_CONFIG_HOME' nvim ${1:+'$1'}"
  sleep 2 # plugin + colorscheme load
  echo "started tmux session '$SESSION' (nvim in $UNIT)"
}

keys() { tmux send-keys -t "$SESSION" "$@"; sleep 0.5; }
type_() { tmux send-keys -t "$SESSION" -l "$1"; sleep 0.3; }

snap() {
  local f="$SNAPDIR/${1:-snap-$(date +%H%M%S)}.txt"
  tmux capture-pane -pt "$SESSION" > "$f"
  echo "$f"
}

text() { tmux capture-pane -pt "$SESSION"; }

stop() {
  tmux send-keys -t "$SESSION" Escape ':qa!' Enter 2>/dev/null || true
  sleep 0.5
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  echo "stopped"
}

check() {
  XDG_CONFIG_HOME="$XDG_CONFIG_HOME" nvim --headless \
    "+lua print('CONFIG_OK colorscheme=' .. vim.g.colors_name .. ' plugins=' .. #vim.pack.get())" \
    +qa! 2>&1
}

# Every .lua file in this unit, DISCOVERED rather than listed. A hard-coded
# glob (`lua/*.lua lua/config/*.lua`) is how this check silently went to zero
# once lua/ was restructured: zsh aborts the loop on `no matches found`, bash
# passes the unexpanded pattern through. find + the empty guard in syntax()
# below mean a future restructure fails loudly instead of checking nothing.
# -H: invoked through the stow path, $UNIT is itself the ~/.config/nvim
# symlink, and find would not descend into it without being told to.
lua_files() { find -H "$UNIT" -name '*.lua' -type f | sort; }

syntax() {
  local files=() f rel failed=0
  while IFS= read -r f; do files+=("$f"); done < <(lua_files)

  if [ "${#files[@]}" -eq 0 ]; then
    echo "SYNTAX ABORT: no .lua file found under $UNIT — the search is broken, not the config" >&2
    return 1
  fi

  # no luac on this machine (only luajit), so nvim itself is the parser
  for f in "${files[@]}"; do
    rel=${f#"$UNIT"/}
    if ! nvim -es --headless \
      "+lua local _, err = loadfile('$f') if err then io.stderr:write(err .. '\n') os.exit(1) end" +q; then
      echo "SYNTAX FAIL: $rel"
      failed=$((failed + 1))
    fi
  done

  if [ "$failed" -gt 0 ]; then
    echo "SYNTAX: $failed of ${#files[@]} file(s) failed"
    return 1
  fi
  echo "SYNTAX OK: ${#files[@]} file(s) checked"
}

assert_pane() { # assert_pane <pattern> <label>
  if text | grep -q "$1"; then
    echo "PASS: $2"
  else
    echo "FAIL: $2 (pattern '$1' not on screen)"; text; exit 1
  fi
}

smoke() {
  echo "== syntax check =="
  syntax

  echo "== headless check =="
  check | grep CONFIG_OK || { echo "FAIL: headless config load"; exit 1; }

  echo "== interactive flow =="
  start init.lua
  assert_pane 'init.lua' "winbar shows filename"
  assert_pane 'require("plugins")' "file contents rendered"

  keys C-n; sleep 1
  snap neotree >/dev/null
  assert_pane 'nvim-pack-lock.json' "neo-tree sidebar lists repo files"
  keys C-n # toggle back off

  type_ '\ff'; sleep 1.5
  snap telescope >/dev/null
  assert_pane 'Find Files' "telescope find_files opened"
  keys Escape; sleep 0.5

  type_ ':PackList'; keys Enter; sleep 1
  snap packlist >/dev/null
  assert_pane 'tokyonight.nvim' "PackList shows plugins"
  keys Enter # dismiss more-prompt if any

  stop
  echo "SMOKE OK — snapshots in $SNAPDIR"
}

cmd=${1:-smoke}; shift || true
case "$cmd" in
  check) check ;;
  syntax) syntax ;;
  start) start "${1:-}" ;;
  keys) keys "$@" ;;
  type) type_ "$1" ;;
  snap) snap "${1:-}" ;;
  text) text ;;
  stop) stop ;;
  smoke) smoke ;;
  *) echo "unknown command: $cmd"; exit 1 ;;
esac
