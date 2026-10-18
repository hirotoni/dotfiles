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
#   nvim <args...>     run nvim with <args> in a throwaway sandbox (e.g. --headless +PackDrift +qa!)
#   smoke              full start->interact->assert->stop flow
#
# Every nvim this script launches runs in a sandbox: a mktemp dir holding a copy
# of this unit as XDG_CONFIG_HOME/nvim, a copy of the real
# ${XDG_DATA_HOME:-~/.local/share}/nvim (plugins, parsers, mason LSP servers) as
# XDG_DATA_HOME/nvim, and empty XDG_STATE_HOME / XDG_CACHE_HOME. vim.pack writes
# nvim-pack-lock.json under XDG_CONFIG_HOME and installs/deletes under
# XDG_DATA_HOME, and tools started from nvim (lazygit) keep their own config
# under XDG_CONFIG_HOME, so neither the real data nor the repo can be pointed
# at directly.
set -euo pipefail

SESSION=nvim-driver
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
UNIT=$(cd "$SCRIPT_DIR/../../.." && pwd)  # <repo>/nvim/.config/nvim
# Agents run in parallel, each from its own worktree, so everything a start
# leaves behind (tmux server, sandbox record, snapshots) is keyed on $UNIT.
# A private tmux socket also keeps the user's default server untouched.
DRIVER_ID=nvim-driver-$(printf '%s' "$UNIT" | cksum | cut -d' ' -f1)
REAL_DATA=${XDG_DATA_HOME:-$HOME/.local/share}/nvim
[ -d "$REAL_DATA" ] && REAL_DATA=$(cd "$REAL_DATA" && pwd)
TMP_ROOT=${TMPDIR:-/tmp}
TMP_ROOT=${TMP_ROOT%/}
SANDBOX_PREFIX=$TMP_ROOT/nvim-driver-sandbox.
SESSION_SANDBOX_FILE=$TMP_ROOT/$DRIVER_ID.sandbox
SNAPDIR=${SNAPDIR:-$TMP_ROOT/nvim-driver-snaps/$DRIVER_ID}
mkdir -p "$SNAPDIR"

require_tmux() {
  command -v tmux >/dev/null 2>&1 && return 0
  echo "driver.sh: tmux not found on PATH" >&2
  echo "driver.sh: install it with 'brew bundle' at the dotfiles repo root (Brewfile declares tmux), or 'brew install tmux'." >&2
  exit 1
}

tmux_() { tmux -L "$DRIVER_ID" "$@"; }

# make_sandbox <full|empty>: `empty` skips the data copy, for runs that never
# load the config. Called as $(make_sandbox …), where set -e does not reach,
# so every step checks its own status.
make_sandbox() {
  local sb
  sb=$(mktemp -d "${SANDBOX_PREFIX}XXXXXX") || return 1
  if ! populate_sandbox "$sb" "$1"; then
    echo "driver.sh: failed to build sandbox $sb" >&2
    remove_sandbox "$sb"
    return 1
  fi
  echo "$sb"
}

populate_sandbox() { # populate_sandbox <sandbox> <full|empty>
  mkdir -p "$1/config/nvim" "$1/data/nvim" "$1/state" "$1/cache" || return 1
  cp -R "$UNIT/." "$1/config/nvim/" || return 1
  [ "$2" = full ] || return 0
  if [ ! -d "$REAL_DATA" ]; then
    echo "driver.sh: $REAL_DATA not found; the sandbox starts with no plugins" >&2
    return 0
  fi
  # cp -c is the macOS APFS clone (about half the time of a plain copy for
  # the ~500MB of plugins and mason servers); other cp builds reject -c.
  cp -cR "$REAL_DATA/." "$1/data/nvim/" 2>/dev/null || cp -R "$REAL_DATA/." "$1/data/nvim/" || return 1
  relocate_data "$1/data/nvim"
}

# The copy still reaches back into $REAL_DATA through absolute paths: the
# site/queries symlinks nvim-treesitter creates, and text files mason writes
# into packages (lua-language-server's exec wrapper runs the real binary, which
# then logs into the real libexec/log). Repoint both at the copy.
relocate_data() {
  local data=$1 f target phys p paths
  while IFS= read -r f; do
    target=$(readlink "$f") || return 1
    ln -sfn "$data${target#"$REAL_DATA"}" "$f" || return 1
  done < <(abs_links "$data" "$REAL_DATA")
  while IFS= read -r f; do
    sed "s|$REAL_DATA/|$data/|g" "$f" >"$f.tmp" && cat "$f.tmp" >"$f" || return 1
    rm -f "$f.tmp"
  done < <(abs_texts "$data" "$REAL_DATA")
  # Relocation matches $REAL_DATA as a string, so a reference recorded through
  # the symlink-free path is missed and would keep pointing at the real data.
  phys=$(cd "$REAL_DATA" && pwd -P) || return 1
  paths=("$REAL_DATA")
  if [ "$phys" != "$REAL_DATA" ]; then paths+=("$phys"); fi
  for p in "${paths[@]}"; do
    if [ -n "$(abs_links "$data" "$p")" ] || [ -n "$(abs_texts "$data" "$p")" ]; then
      echo "driver.sh: the sandbox copy still references $p" >&2
      return 1
    fi
  done
}

abs_links() { find "$1" -type l -lname "$2/*" 2>/dev/null; }
# lua-language-server writes its logs (which quote paths) under libexec/log.
abs_texts() { grep -rlIF --exclude-dir=log "$2/" "$1/mason/packages" 2>/dev/null; }

remove_sandbox() {
  case "$1" in
    */..* | *../*) ;;
    "$SANDBOX_PREFIX"?*) rm -rf "$1" ;;
  esac
}

TRANSIENT_SANDBOX=
trap 'remove_sandbox "$TRANSIENT_SANDBOX"' EXIT

sandbox_vars() { # sandbox_vars <sandbox>: one VAR=value per line
  printf '%s\n' "XDG_CONFIG_HOME=$1/config" "XDG_DATA_HOME=$1/data" \
    "XDG_STATE_HOME=$1/state" "XDG_CACHE_HOME=$1/cache"
}

in_sandbox() { # in_sandbox <sandbox> <cmd...>
  local vars=() v
  while IFS= read -r v; do vars+=("$v"); done < <(sandbox_vars "$1")
  shift
  env "${vars[@]}" "$@"
}

in_new_sandbox() {
  local rc=0
  TRANSIENT_SANDBOX=$(make_sandbox "$1") || return 1
  shift
  in_sandbox "$TRANSIENT_SANDBOX" "$@" || rc=$?
  remove_sandbox "$TRANSIENT_SANDBOX"
  return "$rc"
}

drop_session_sandbox() {
  [ -f "$SESSION_SANDBOX_FILE" ] || return 0
  remove_sandbox "$(cat "$SESSION_SANDBOX_FILE")"
  rm -f "$SESSION_SANDBOX_FILE"
}

start() {
  local sb tmux_env=() v
  tmux_ kill-session -t "$SESSION" 2>/dev/null || true
  drop_session_sandbox
  sb=$(make_sandbox full) || exit 1
  echo "$sb" >"$SESSION_SANDBOX_FILE"
  # The pane gets the tmux server's environment, not this script's, so the
  # sandbox variables have to be handed to tmux explicitly.
  while IFS= read -r v; do tmux_env+=(-e "$v"); done < <(sandbox_vars "$sb")
  tmux_ new-session -d -s "$SESSION" -x 120 -y 35 "${tmux_env[@]}" \
    "cd '$UNIT' && nvim ${1:+'$1'}"
  sleep 2
  echo "started tmux session '$SESSION' (nvim in $UNIT, sandbox $sb)"
}

keys() {
  tmux_ send-keys -t "$SESSION" "$@"
  sleep 0.5
}
type_() {
  tmux_ send-keys -t "$SESSION" -l "$1"
  sleep 0.3
}

snap() {
  local f="$SNAPDIR/${1:-snap-$(date +%H%M%S)}.txt"
  tmux_ capture-pane -pt "$SESSION" >"$f"
  echo "$f"
}

text() { tmux_ capture-pane -pt "$SESSION"; }

stop() {
  tmux_ send-keys -t "$SESSION" Escape ':qa!' Enter 2>/dev/null || true
  sleep 0.5
  tmux_ kill-session -t "$SESSION" 2>/dev/null || true
  drop_session_sandbox
  echo "stopped"
}

check() {
  in_new_sandbox full nvim --headless \
    "+lua print('CONFIG_OK colorscheme=' .. vim.g.colors_name .. ' plugins=' .. #vim.pack.get())" \
    +qa! 2>&1
}

# Every .lua file in this unit, DISCOVERED rather than listed. A hard-coded
# glob (`lua/*.lua lua/config/*.lua`) silently checks nothing once the files
# move: zsh aborts the loop on `no matches found`, bash passes the unexpanded
# pattern through. find + the empty guard in syntax() below make a broken
# search fail loudly instead.
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

  TRANSIENT_SANDBOX=$(make_sandbox empty) || return 1
  # no luac on this machine (only luajit), so nvim itself is the parser
  for f in "${files[@]}"; do
    rel=${f#"$UNIT"/}
    if ! in_sandbox "$TRANSIENT_SANDBOX" nvim -es --headless \
      "+lua local _, err = loadfile('$f') if err then io.stderr:write(err .. '\n') os.exit(1) end" +q; then
      echo "SYNTAX FAIL: $rel"
      failed=$((failed + 1))
    fi
  done
  remove_sandbox "$TRANSIENT_SANDBOX"

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
    echo "FAIL: $2 (pattern '$1' not on screen)"
    text
    exit 1
  fi
}

smoke() {
  echo "== syntax check =="
  syntax

  echo "== headless check =="
  check | grep CONFIG_OK || {
    echo "FAIL: headless config load"
    exit 1
  }

  echo "== interactive flow =="
  require_tmux
  start init.lua
  assert_pane 'init.lua' "winbar shows filename"
  assert_pane 'require("plugins")' "file contents rendered"

  keys C-n
  sleep 1
  snap neotree >/dev/null
  assert_pane 'nvim-pack-lock.json' "neo-tree sidebar lists repo files"
  keys C-n

  type_ '\ff'
  sleep 1.5
  snap telescope >/dev/null
  assert_pane 'Find Files' "telescope find_files opened"
  keys Escape
  sleep 0.5

  type_ ':PackList'
  keys Enter
  sleep 1
  snap packlist >/dev/null
  assert_pane 'tokyonight.nvim' "PackList shows plugins"
  keys Enter # dismiss more-prompt if any

  stop
  echo "SMOKE OK — snapshots in $SNAPDIR"
}

cmd=${1:-smoke}
shift || true
case "$cmd" in
  start | keys | type | snap | text | stop) require_tmux ;;
esac
case "$cmd" in
  check) check ;;
  syntax) syntax ;;
  start) start "${1:-}" ;;
  keys) keys "$@" ;;
  type) type_ "$1" ;;
  snap) snap "${1:-}" ;;
  text) text ;;
  stop) stop ;;
  nvim) in_new_sandbox full nvim "$@" ;;
  smoke) smoke ;;
  *)
    echo "unknown command: $cmd"
    exit 1
    ;;
esac
