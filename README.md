# My Dotfiles

Version-controlled configs, symlinked into place. Secrets stay local (gitignored)
and a pre-commit hook scans for anything that shouldn't be pushed.

## Structure

```
config/
  zsh/.zshrc                    zsh4humans (z4h) config
  zsh/devbox.local.zsh.example  template for machine-local secrets
  kanata/kanata.kbd             kanata keyboard remapper
hooks/
  pre-commit                    secret / corporate-info scanner
  install-hooks.sh              installs the hook into .git/hooks
link.sh                         symlinks config/* into ~/.config/* (+ ~/.zshrc)
setup-mac.sh                    installs tools, links dotfiles, installs hooks
```

Symlink chains created by `link.sh`:

```
~/.zshrc → ~/.config/zsh/.zshrc → dotfiles/config/zsh/.zshrc
~/.config/kanata/kanata.kbd     → dotfiles/config/kanata/kanata.kbd
```

## Setup

Mac:
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/davidgamero/dotfiles/main/setup-mac.sh)"
```

Or from a clone:
```
git clone https://github.com/davidgamero/dotfiles ~/.dotfiles
~/.dotfiles/setup-mac.sh          # installs tools + links + hooks
```

Ubuntu:
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/davidgamero/dotfiles/main/setup-ubuntu.sh)"
```

Intune for Ubuntu 24.04 (MS Dev):
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/davidgamero/dotfiles/main/intune-ubuntu-24.04.sh)"
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
