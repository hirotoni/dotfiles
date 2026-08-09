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

# run with target
./install.sh zsh
./install.sh nvim
```

## Machine-specific config

```bash
cp zsh/.zsh/local.zsh.example zsh/.zsh/local.zsh
```

