---
name: run-nvim
description: >-
  Run, launch, test, or screenshot this Neovim config. Use when asked to
  verify the config loads, drive nvim interactively (neo-tree, telescope,
  keymaps), check a plugin change works, or smoke-test after editing
  init.lua / lua/**. Covers headless checks, the tmux driver, and lint.
---

# Run this Neovim config

This unit is a Neovim (v0.12+) configuration using the built-in `vim.pack`
plugin manager — there is no build step. "Running" it means launching
`nvim` with this directory as its config. All paths below are relative to
this unit (`nvim/.config/nvim` inside the dotfiles repo). The driver is
`.claude/skills/run-nvim/driver.sh`; it wraps nvim in tmux and always sets
`XDG_CONFIG_HOME` to the repo copy, so it works whether or not the config
is stowed to `~/.config/nvim`.

## Prerequisites

Verified present via Homebrew: `nvim` (0.12.2), `tmux`, `fd` and `rg`
(telescope pickers hard-require them), `lazygit`, `stylua`. First launch
on a clean machine needs network + a C compiler: `vim.pack` git-clones all
28 plugins and nvim-treesitter compiles parsers, automatically and
headless — no prompt, takes a few minutes.

## Run (agent path) — the driver

```bash
.claude/skills/run-nvim/driver.sh smoke
```

Headless config-load check, then a full tmux flow: open `init.lua`, toggle
neo-tree (`C-n`), open telescope find-files (`\ff`), run `:PackList`,
asserting on pane contents at each step. Prints `SMOKE OK` and the
snapshot directory. Run it after any config change.

Individual commands for driving nvim by hand:

```bash
D=.claude/skills/run-nvim/driver.sh
$D check              # headless: prints CONFIG_OK colorscheme=… plugins=28
$D start init.lua     # nvim in a detached 120x35 tmux session 'nvim-driver'
$D keys C-n           # send tmux key names (C-n, Escape, Enter, …)
$D type ':PackList'   # send literal text; follow with: $D keys Enter
$D text               # dump current screen to stdout
$D snap mystate       # save screen to a .txt "screenshot", prints the path
$D stop               # :qa! and kill the session
```

Snapshots land in `$TMPDIR/nvim-driver-snaps/` (override with `SNAPDIR=`).

## Direct invocation (most PRs need only this)

A change to one module under `lua/` doesn't need the full TUI:

```bash
# syntax-check every lua file (no luac on this machine; use nvim itself)
for f in init.lua lua/*.lua lua/config/*.lua; do
  nvim -es --headless "+lua assert(loadfile('$f'))" +q || echo "SYNTAX FAIL: $f"
done

# formatting gate (uses .stylua.toml)
stylua --check .

# evaluate anything inside the fully-loaded config
# (XDG_CONFIG_HOME must be the dir CONTAINING nvim/, i.e. .config — one level up)
XDG_CONFIG_HOME=$(cd .. && pwd) nvim --headless "+lua print(vim.g.colors_name)" +qa!
```

## Run (human path)

`nvim` in a real terminal — the config is stowed (`~/.config/nvim` →
this directory), so plain `nvim` uses it. Useless from a non-interactive
shell; use the driver.

## Test / isolated first-launch check

There is no test suite. To prove the config bootstraps on a clean
machine, point `XDG_DATA_HOME`/`XDG_STATE_HOME` at an empty dir — verified
working; clones all plugins from scratch:

```bash
XDG_CONFIG_HOME=$(cd .. && pwd) \
XDG_DATA_HOME=/tmp/nvim-clean/data XDG_STATE_HOME=/tmp/nvim-clean/state \
nvim --headless "+lua print('CLEAN_OK plugins=' .. #vim.pack.get())" +qa!
```

## Gotchas

- **Leader is the default `\`** — no `mapleader` is set anywhere. Telescope
  is `\ff`, not `<Space>ff`.
- **Neo-tree opens on the RIGHT** with Files/Buffers/Symbols tabs, and top-level
  dirs start collapsed — don't assert on files inside `lua/` after `C-n`.
- **`laststatus=0`**: there is no bottom statusline; the filename is in the
  winbar at the top of each window. Pane asserts should target the winbar.
- **Headless runs always print** `image.nvim: cannot query terminal size` and a
  `[ClaudeCode] … stopped` line on stderr. Benign; grep for your marker.
- **`:PackList` ends with a `Press ENTER` more-prompt** — send `Enter` to
  dismiss before the next command.
- **telescope-fzf-native is cloned but never built/loaded** (no
  `load_extension("fzf")` in the config), so the missing `build/` dir is not an
  error.
- **`luac` is not installed** (only `luajit`); syntax-check with
  `nvim -es --headless "+lua assert(loadfile(...))"` as shown above.

## Troubleshooting

- `Telescope find_files` shows nothing / errors → `fd` missing
  (`brew install fd`); the picker uses an explicit `find_command = fd`.
- Driver `FAIL: … pattern not on screen` → it dumps the pane; the app state
  is usually fine and the assertion pattern is what's wrong. `$D text` to look.
- Stale tmux session from a crashed run → `tmux kill-session -t nvim-driver`
  (driver `start` also does this automatically).
