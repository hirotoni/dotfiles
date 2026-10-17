# dotfiles

Personal dotfiles for macOS. Managed with Homebrew + GNU Stow.

## Requirements

macOS with [Homebrew](https://brew.sh) installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Everything else (GNU Stow, the zsh plugins, and the rest of the `Brewfile`) is
installed by `install.sh`. You do not need to add `brew shellenv` to your shell
profile first: both `install.sh` and `zsh/.zshrc` look for `brew` on `PATH`,
then at `/opt/homebrew/bin/brew` (Apple Silicon) and `/usr/local/bin/brew`
(Intel).

## Setup

```bash
git clone git@github.com:hirotoni/dotfiles.git ~/dotfiles
cd ~/dotfiles

# run once per target
./install.sh zsh    # ~/.zshrc, ~/.zshenv, ~/.zsh
./install.sh nvim   # ~/.config/nvim
./install.sh cmux   # ~/.config/cmux, ~/.config/ghostty, ~/.hammerspoon
```

`install.sh` accepts one target per run: `zsh`, `nvim`, or `cmux`. The `cmux`
target places the config for cmux, Ghostty, and Hammerspoon. The Ghostty
config is read by cmux, not by a separate Ghostty app. The `Brewfile` installs
cmux and Hammerspoon but not their config, so if you skip this target they
start with their defaults.

## Updating

After `git pull`, plugins already installed by Neovim stay at their old
revision even if `nvim/.config/nvim/nvim-pack-lock.json` changed. Neovim warns
at startup when they differ; run `:PackSync` in Neovim and `:w` the
confirmation buffer to check out the revisions in the lockfile. `:PackDrift`
lists the plugins that differ.

## Machine-specific config

```bash
cp zsh/.zsh/local.zsh.example zsh/.zsh/local.zsh
```

