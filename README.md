# My Dotfiles

[![CI](https://github.com/davidgamero/dotfiles/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/davidgamero/dotfiles/actions/workflows/ci.yml?query=branch%3Amain)

Version-controlled configs, symlinked into place. Secrets stay local (gitignored)
and a pre-commit hook scans for anything that shouldn't be pushed.

## Setup

Mac:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/davidgamero/dotfiles/main/scripts/setup-mac.sh)"
```

Or from a clone:
```bash
git clone https://github.com/davidgamero/dotfiles ~/.dotfiles
bash ~/.dotfiles/scripts/setup-mac.sh
```

Ubuntu:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/davidgamero/dotfiles/main/scripts/setup-ubuntu.sh)"
```

The default installation is intentionally small. It installs the shell/editor
core, links configs, and installs this repository's pre-commit hook:

- Git, GitHub CLI, Zsh, tmux, fzf, zoxide, Neovim, ripgrep, fd, jq, and build essentials
- TPM (tmux plugin manager)
- Your private `davidgamero/nvim` config cloned into `~/.config/nvim`
- The tracked dotfile symlinks

Heavy or privileged tooling is opt-in through profiles:

```bash
# Run from a clone. Core is always included.
bash ~/.dotfiles/scripts/setup-ubuntu.sh containers kubernetes
bash ~/.dotfiles/scripts/setup-ubuntu.sh cloud gui languages
bash ~/.dotfiles/scripts/setup-mac.sh fonts containers gui

# See platform-specific profiles.
bash ~/.dotfiles/scripts/setup-ubuntu.sh --help
bash ~/.dotfiles/scripts/setup-mac.sh --help
```

Available profiles:

| Profile | Ubuntu | macOS |
| --- | --- | --- |
| `containers` | Docker Engine + Compose | Docker Desktop |
| `kubernetes` | kubectl + kind (also installs Docker) | kubectl + kind |
| `cloud` | Azure CLI | Azure CLI |
| `gui` | VS Code | VS Code |
| `languages` | nvm + system Go | nvm + Go |
| `kanata` | Requires an existing Cargo install | Binary only; system setup remains manual |
| `ai` | OpenCode official installer | OpenCode Homebrew tap |
| `fonts` | — | Cascadia Mono Nerd Font |
| `signing` | SSH Git signing | SSH Git signing |
| `all` | Every optional profile | Every optional profile |

The setup scripts do **not** perform a full operating-system upgrade. Optional
profiles can add third-party package repositories or execute vendor installers;
review the scripts before using `all`.

Docker group membership is deliberately not automatic because the group is
effectively root access. The Ubuntu installer prints the explicit command if
you choose that profile.

Kanata is not operational just from installing the binary. It still requires
platform permissions, drivers, and service setup described in
`config/kanata/README.md`.

### First launch downloads

When setup is run from an interactive terminal without profile arguments, it
shows a numbered, emoji-labelled menu for optional components. Press Enter for
core only, or enter comma-separated selections such as `1,2,5`. Explicit
profile arguments remain available for scripts and unattended setup.

The Neovim config repository is private. Core setup installs `gh` and requires
an authenticated GitHub CLI session (`gh auth login`) to clone it. An existing
`~/.config/nvim` Git checkout is updated with `git pull --ff-only`; other files
or symlinks are backed up before cloning.

The first interactive Zsh starts the zsh4humans bootstrap in `.zshenv`.
The first Neovim launch downloads LazyVim plugins and configured language
servers. Both require network access.

## Structure

```
config/
  zsh/.zshenv                   zsh4humans (z4h) bootstrap (fetches z4h, sets ZDOTDIR)
  zsh/.zshrc                    zsh4humans (z4h) config
  zsh/devbox.local.zsh.example  template for machine-local secrets
  kanata/kanata.kbd             kanata keyboard remapper
  tmux/tmux.conf                tmux config
hooks/
  pre-commit                    secret / corporate-info scanner
  install-hooks.sh              installs the hook into .git/hooks
scripts/
  setup-mac.sh                  core setup + optional macOS profiles
  setup-ubuntu.sh               core setup + optional Ubuntu profiles
  profile-picker.sh             portable interactive optional-profile menu
  setup-git-commit-signing.sh   configures SSH-based git commit signing
link.sh                         symlinks config/* into place
test-install.sh                 CI: link idempotency + hook behavior tests
```

Symlink chains created by `link.sh`:

```
~/.zshenv                       → dotfiles/config/zsh/.zshenv   (bootstraps z4h)
~/.zshrc → ~/.config/zsh/.zshrc → dotfiles/config/zsh/.zshrc
~/.config/kanata/kanata.kbd     → dotfiles/config/kanata/kanata.kbd
~/.tmux.conf                    → dotfiles/config/tmux/tmux.conf
```

Shell is [zsh4humans](https://github.com/romkatv/zsh4humans): `~/.zshenv`
self-fetches z4h on first interactive shell — no oh-my-zsh needed.

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
