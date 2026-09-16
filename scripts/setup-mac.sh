#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="https://github.com/davidgamero/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SELF="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
REPO_ROOT=""
if [[ -n "$SELF" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "$SELF")" >/dev/null 2>&1 && pwd || true)"
  REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd || true)"
fi

if [[ -z "$REPO_ROOT" || ! -f "$REPO_ROOT/link.sh" ]]; then
  echo "setup: no local clone detected, bootstrapping into $DOTFILES_DIR..."
  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    command -v git >/dev/null 2>&1 || { echo "error: install the Xcode command line tools first" >&2; exit 1; }
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  exec bash "$DOTFILES_DIR/scripts/setup-mac.sh" "$@"
fi

usage() {
  cat <<'EOF'
Usage: setup-mac.sh [profiles...]

The core profile is always installed. Optional profiles:
  fonts       Cascadia Mono Nerd Font
  containers  Docker Desktop
  kubernetes  kubectl and kind
  cloud       Azure CLI
  gui         Visual Studio Code
  languages   nvm and Go
  kanata      kanata binary (driver, permissions, and daemon remain manual)
  ai          OpenCode terminal coding agent
  signing     configure SSH-based Git commit signing
  all         all optional profiles
EOF
}

PROFILES=""
EXPLICIT_PROFILES=$#
for profile in "$@"; do
  case "$profile" in
    -h|--help) usage; exit 0 ;;
    all) PROFILES="$PROFILES all" ;;
    fonts|containers|kubernetes|cloud|gui|languages|kanata|ai|signing)
      PROFILES="$PROFILES $profile"
      ;;
    *) echo "error: unknown profile: $profile" >&2; usage >&2; exit 2 ;;
  esac
done
if (( EXPLICIT_PROFILES == 0 )); then
  # shellcheck source=profile-picker.sh
  source "$SCRIPT_DIR/profile-picker.sh"
  pick_profiles mac
fi
has_profile() { [[ " $PROFILES " == *" all "* || " $PROFILES " == *" $1 "* ]]; }

if ! command -v brew >/dev/null 2>&1; then
  echo "setup: installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
command -v brew >/dev/null 2>&1 || { echo "error: Homebrew installation did not add brew to PATH" >&2; exit 1; }

echo "setup: installing core macOS tools..."
brew install fd fzf gh git neovim ripgrep tmux zoxide

install_nvim_config() {
  local target="$HOME/.config/nvim" backup
  if [[ -d "$target/.git" ]]; then
    echo "setup: updating Neovim config..."
    git -C "$target" pull --ff-only
    return
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    backup="$target.backup.$(date +%Y%m%d%H%M%S).$$"
    mv -- "$target" "$backup"
    echo "setup: backed up existing Neovim config to $backup"
  fi
  mkdir -p "$HOME/.config"
  if gh auth status >/dev/null 2>&1; then
    git -c credential.helper='!gh auth git-credential' clone https://github.com/davidgamero/nvim.git "$target"
  else
    echo "error: github.com/davidgamero/nvim is private." >&2
    echo "Run 'gh auth login', then re-run setup to install your Neovim config." >&2
    return 1
  fi
}

install_nvim_config

if [[ "$(basename "${SHELL:-}")" != zsh ]] && command -v chsh >/dev/null 2>&1; then
  chsh -s "$(command -v zsh)" || echo "note: could not change the login shell; run chsh manually"
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

has_profile fonts && brew install --cask font-caskaydia-mono-nerd-font
has_profile containers && brew install --cask docker
has_profile kubernetes && brew install kubectl kind
has_profile cloud && brew install azure-cli
has_profile gui && brew install --cask visual-studio-code

if has_profile languages; then
  brew install go nvm
fi

if has_profile kanata; then
  brew install kanata
  echo "note: kanata still requires macOS permissions, Karabiner VirtualHIDDevice, and a daemon; see config/kanata/README.md"
fi

has_profile ai && brew install anomalyco/tap/opencode

"$REPO_ROOT/link.sh"
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" "$HOME/.tmux/plugins/tpm/bin/install_plugins"
"$REPO_ROOT/hooks/install-hooks.sh"

if has_profile signing; then
  bash "$SCRIPT_DIR/setup-git-commit-signing.sh"
fi

echo
echo "Setup complete. Restart your shell to use linked configuration."
echo "Optional machine-local values belong in ~/.config/zsh/*.local.zsh."
