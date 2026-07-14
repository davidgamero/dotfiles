# My Dotfiles

[![CI](https://github.com/davidgamero/dotfiles/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/davidgamero/dotfiles/actions/workflows/ci.yml?query=branch%3Amain)

Version-controlled configs, symlinked into place. Secrets stay local (gitignored)
and a pre-commit hook scans for anything that shouldn't be pushed.

## Structure

```
config/
  zsh/.zshenv                   zsh4humans (z4h) bootstrap (fetches z4h, sets ZDOTDIR)
  zsh/.zshrc                    zsh4humans (z4h) config
  zsh/devbox.local.zsh.example  template for machine-local secrets
  kanata/kanata.kbd             kanata keyboard remapper
  nvim/                         LazyVim-based neovim config
  tmux/tmux.conf                tmux config
hooks/
  pre-commit                    secret / corporate-info scanner
  install-hooks.sh              installs the hook into .git/hooks
scripts/
  setup-mac.sh                  installs tools, links dotfiles, installs hooks
  setup-ubuntu.sh               same, for Ubuntu
  setup-git-commit-signing.sh   configures SSH-based git commit signing
link.sh                         symlinks config/* into place
test-install.sh                 CI: link idempotency + hook behavior tests
```

Symlink chains created by `link.sh`:

```
~/.zshenv                       → dotfiles/config/zsh/.zshenv   (bootstraps z4h)
~/.zshrc → ~/.config/zsh/.zshrc → dotfiles/config/zsh/.zshrc
~/.config/kanata/kanata.kbd     → dotfiles/config/kanata/kanata.kbd
~/.config/nvim                  → dotfiles/config/nvim
~/.tmux.conf                    → dotfiles/config/tmux/tmux.conf
```

Shell is [zsh4humans](https://github.com/romkatv/zsh4humans): `~/.zshenv`
self-fetches z4h on first interactive shell — no oh-my-zsh needed.

## Setup

Mac:
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/davidgamero/dotfiles/main/scripts/setup-mac.sh)"
```

Or from a clone:
```
git clone https://github.com/davidgamero/dotfiles ~/.dotfiles
~/.dotfiles/scripts/setup-mac.sh          # installs tools + links + hooks
```

Ubuntu:
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/davidgamero/dotfiles/main/scripts/setup-ubuntu.sh)"
```

## Machine-local secrets

Values you don't want in the repo (e.g. Azure subscription IDs, internal
resource-group / VM names) live in gitignored `*.local.zsh` files that `.zshrc`
sources if present:

```
cp config/zsh/devbox.local.zsh.example ~/.config/zsh/devbox.local.zsh
# then edit ~/.config/zsh/devbox.local.zsh with real values
```

## Pre-commit secret scanner

`hooks/pre-commit` blocks commits containing GUIDs / Azure subscription IDs,
private keys, AWS / GitHub / Slack tokens, bearer / API keys, `@microsoft.com`
emails, Azure connection strings, and internal hostnames.

Installed automatically by `setup-mac.sh`; install manually with:
```
~/.dotfiles/hooks/install-hooks.sh
```

Bypass only for a confirmed false positive: `git commit --no-verify`.

## Syncing changes

Edit `~/.config/zsh/.zshrc` (or use the `rc` alias) — it writes through the
symlink to the repo. Then:
```
cd ~/.dotfiles && git add -A && git commit -m "..."   # hook scans on commit
git push
```
