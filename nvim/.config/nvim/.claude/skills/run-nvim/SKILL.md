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
`.claude/skills/run-nvim/driver.sh`; it wraps nvim in tmux and runs every
nvim it launches in a throwaway sandbox under `$TMPDIR`, so it works whether
or not the config is stowed to `~/.config/nvim`.

## Isolation — what the driver may and may not touch

Each driver launch gets a fresh `mktemp` dir: a copy of this unit as
`XDG_CONFIG_HOME/nvim`, a copy of the real `~/.local/share/nvim` (plugins,
treesitter parsers, mason LSP servers) as `XDG_DATA_HOME/nvim`, and empty
`XDG_STATE_HOME`/`XDG_CACHE_HOME`. Plugins and LSP load exactly as on the
real machine, but every write — `nvim-pack-lock.json`, plugin installs and
`vim.pack.del`, shada, swap, logs, lazygit's config — lands in the copy and is
deleted afterwards (`start`'s sandbox lives until `stop` or the next `start`).
The real `~/.local/{share,state}/nvim`, `~/.cache/nvim` and the repo's working
tree stay unchanged. Tools started from inside nvim (git, lazygit, LSP
servers) inherit the sandbox XDG dirs too, so they don't see the user's
`~/.config` either (e.g. the global git ignore), and code that derives the
dotfiles root from `stdpath("config")` (the mmdc hint in
`lua/plugins/diagram.lua`) prints a wrong path under `$TMPDIR`.

A change that must land in the repo's `nvim-pack-lock.json` is therefore
copied out explicitly, at the end of the same run that made it. A new plugin
is written to the sandbox lockfile by the `vim.pack.add` at startup; a
`version`/`rev` bump needs a `vim.pack.update` of that plugin first:

```bash
.claude/skills/run-nvim/driver.sh nvim --headless \
  "+lua vim.pack.update({ '<name>' }, { force = true })" \
  "+lua assert(vim.uv.fs_copyfile(vim.fn.stdpath('config') .. '/nvim-pack-lock.json', '$PWD/nvim-pack-lock.json'))" +qa!
```

Drop the `vim.pack.update` line for a new plugin. Run it from this unit's
directory, and review the result with `git diff` before committing.

So run nvim only through the driver (`$D check`, `$D start`, `$D nvim …`).
A bare `XDG_CONFIG_HOME=… nvim` points nvim at the repo and the real data
and rewrites both. The only path that uses the real data is the human one
below (plain `nvim`); a check that needs it — e.g. confirming a `:PackSync`
on the user's machine — is a step to report to the user, not to run.

## Prerequisites

Declared in the repo's `Brewfile` (installed by `install.sh` / `brew bundle`):
`nvim` (`neovim`), `tmux` (3.2+, for `new-session -e`), `fd` and `rg`
(`ripgrep`; telescope pickers hard-require them), `lazygit`, `stylua`.
`check` and `syntax` need only `nvim`; every tmux-backed command (and `smoke`
before its interactive flow) exits with an install hint if `tmux` is missing. First launch
on a clean machine needs network + a C compiler: `vim.pack` git-clones every
plugin declared under `lua/` and nvim-treesitter compiles parsers,
automatically and headless — no prompt, takes a few minutes.

The `plugins=<n>` that `driver.sh check` prints is `#vim.pack.get()`: every
plugin installed on disk, not only the ones declared under `lua/`. Expect it
to equal the declared count on every machine; a larger `<n>` is a leftover
to remove, not an expected gap. The two ways `<n>` drifts:

- **Any machine, incl. a fresh one:** an entry left in `nvim-pack-lock.json`
  after its declaration was removed. `vim.pack` installs every lockfile entry
  missing on disk at startup, so the leftover is cloned again on first launch.
- **Long-lived machine:** a plugin directory left on disk. `vim.pack` writes
  any on-disk plugin missing from the lockfile back into it at startup, so
  deleting only the lockfile entry gets undone and dirties the repo's lockfile.

So removing a plugin takes both steps: delete its `vim.pack.add` declaration,
then run `:lua vim.pack.del({ '<name>' })` on each machine — that removes the
directory and the lockfile entry together. Leftovers show up as inactive
entries (so would a declared plugin that the config skips at startup); list
them with:

```bash
.claude/skills/run-nvim/driver.sh nvim --headless \
  "+lua for _, p in ipairs(vim.pack.get()) do if not p.active then print('INACTIVE ' .. p.spec.name) end end" +qa!
```

## Run (agent path) — the driver

```bash
.claude/skills/run-nvim/driver.sh smoke
```

Syntax check, headless config-load check, then a full tmux flow: open
`init.lua`, toggle neo-tree (`C-n`), open telescope find-files (`\ff`),
run `:PackList`, asserting on pane contents at each step. Prints `SMOKE OK`
and the snapshot directory. Run it after any config change.

Individual commands for driving nvim by hand:

```bash
D=.claude/skills/run-nvim/driver.sh
$D check              # headless: prints CONFIG_OK colorscheme=<name> plugins=<n>
$D syntax             # headless: loadfile() every .lua in this unit
$D start init.lua     # nvim in a detached 120x35 tmux session 'nvim-driver'
$D keys C-n           # send tmux key names (C-n, Escape, Enter, …)
$D type ':PackList'   # send literal text; follow with: $D keys Enter
$D text               # dump current screen to stdout
$D snap mystate       # save screen to a .txt "screenshot", prints the path
$D stop               # :qa! and kill the session
$D nvim <args…>       # run nvim <args…> in a fresh sandbox, e.g. --headless "+lua …" +qa!
```

The tmux session runs on a private socket (`tmux -L nvim-driver-<n>`), never
the default server, and `<n>` is derived from this unit's absolute path. So
drivers started from different worktrees at the same time each drive and read
only their own nvim, provided each calls its own worktree's copy of the driver
(not one reached through `~/.config/nvim`); two runs of the same copy still
share one session. To attach by hand, from this unit's directory:
`tmux -L "nvim-driver-$(printf %s "$PWD" | cksum | cut -d' ' -f1)" attach`.

Snapshots land in `$TMPDIR/nvim-driver-snaps/nvim-driver-<n>/` (override with
`SNAPDIR=`).

## Direct invocation (most PRs need only this)

A change to one module under `lua/` doesn't need the full TUI:

```bash
# syntax-check every lua file: prints "SYNTAX OK: <n> file(s) checked", or a
# "SYNTAX FAIL: <path>" line per bad file, and exits non-zero on any failure
.claude/skills/run-nvim/driver.sh syntax

# formatting gate (uses .stylua.toml); prints "Diff in <path>:" per file
stylua --check .

# evaluate anything inside the fully-loaded config
.claude/skills/run-nvim/driver.sh nvim --headless "+lua print(vim.g.colors_name)" +qa!
```

`syntax` and `check` need no tmux, and behave identically from zsh and bash
because `driver.sh` runs under its own bash shebang. Keep the syntax check in
`driver.sh` rather than pasting a `for f in init.lua lua/*.lua …` loop back
into this file; the comment above `lua_files()` in `driver.sh` explains why.

The same formatting check runs as the `lua-format` pre-commit hook, but only
on the staged lua files under this unit. A file whose formatting drifted in
through a merge (a merge commit that git creates on its own skips the hook)
is therefore reported by `stylua --check .` here, or by
`pre-commit run --all-files`. If it names a file you did not touch, the
drift predates your change: fix it with `stylua <path>` in a commit of its
own rather than folding the reformat into an unrelated commit.

## Run (human path)

`nvim` in a real terminal — the config is stowed (`~/.config/nvim` →
this directory), so plain `nvim` uses it — with the real data, so this is
the path where installs, `:PackSync` and lockfile write-backs really happen.
Useless from a non-interactive shell; use the driver.

## Test / isolated first-launch check

There is no test suite. To prove the config bootstraps on a clean
machine, give the driver an empty `XDG_DATA_HOME` to copy from — the sandbox
then starts with no plugins and clones all of them from scratch:

```bash
XDG_DATA_HOME=/var/empty .claude/skills/run-nvim/driver.sh nvim --headless \
  "+lua print('CLEAN_OK plugins=' .. #vim.pack.get())" +qa!
```

## Plugin revisions on disk vs the lockfile

`vim.pack.add()` never moves a plugin that is already on disk, and a clean
install checks out the lockfile `rev`, not the `version` under `lua/`. So a
version bump must commit the updated `rev` in `nvim-pack-lock.json` along with
the `version`, and a machine that pulls it keeps running the old revision
until it is synced. `:PackList` can't show this — its REV column is
read from the lockfile, not from disk.

`lua/core/packsync.lua` compares each plugin's checked-out commit with the
lockfile `rev`:

- On a real (non-headless-`+qa`) startup it warns once, listing each drifted
  plugin as `<name>  disk=<sha>  lock=<sha>`.
- `:PackDrift` prints `PACK_DRIFT none`, or `PACK_DRIFT <n>` followed by the
  same lines. Headless `+qa` exits before `VimEnter`, so agents use this:

  ```bash
  .claude/skills/run-nvim/driver.sh nvim --headless +PackDrift +qa! 2>&1 | grep -A50 PACK_DRIFT
  ```

- `:PackSync` runs `vim.pack.update(nil, { target = "lockfile" })` and opens
  the confirmation buffer (`:w` to apply). `:PackSync!` applies without
  confirming; `:PackSync <name>…` limits it to those plugins. `:PackUpdate`
  is not a substitute — it moves plugins to the newest commit matching
  `version`, not to the lockfile `rev`.

A task that bumps a plugin's `version`/`rev` is verified in the driver's
sandbox, whose sync is thrown away with it, so it changes nothing on the
user's machine. Report `:PackSync` as the step the user must run, and never
run `:PackSync`/`vim.pack.update` against the real
`~/.local/share/nvim/site/pack`. To exercise the sync, run it in the sandbox
— it starts from a copy of the real pack dir, and `vim.pack.update` rewrites
only the sandbox's copy of `nvim-pack-lock.json`:

```bash
.claude/skills/run-nvim/driver.sh nvim --headless '+PackSync!' +PackDrift +qa!
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
- **The config is a copy taken at launch.** After editing `lua/` or the
  lockfile, a running `$D start` session still has the old copy (re-`require`,
  `:PackDrift`); restart it, or use `$D check` / `$D nvim`, to see the edit.
- **Each `check`/`smoke`/`start`/`nvim` copies ~500MB of data first** (an
  APFS clone on macOS, a few seconds). That cost is the isolation; don't
  "speed it up" by pointing nvim at the real data.
- **`:PackList` ends with a `Press ENTER` more-prompt** — send `Enter` to
  dismiss before the next command.
- **telescope-fzf-native is cloned but never built/loaded** (no
  `load_extension("fzf")` in the config), so the missing `build/` dir is not an
  error.
- **`luac` is not installed** (only `luajit`), so `driver.sh syntax` uses nvim
  itself as the parser: `nvim -es --headless "+lua loadfile(…)"` per file.

## Troubleshooting

- `Telescope find_files` shows nothing / errors → `fd` missing
  (`brew install fd`); the picker uses an explicit `find_command = fd`.
- Driver `FAIL: … pattern not on screen` → it dumps the pane; the app state
  is usually fine and the assertion pattern is what's wrong. `$D text` to look.
- Stale tmux session from a crashed run → `$D stop`, which also removes that
  session's sandbox (driver `start` also does this automatically).
- An interrupted run can leave `$TMPDIR/nvim-driver-sandbox.*` behind; they
  are throwaway copies and safe to delete.
