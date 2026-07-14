#!/bin/bash
set -e

# --- self-bootstrap -------------------------------------------------------
# This script needs the repo on disk (for link.sh + hooks). When run via
#   sh -c "$(curl -fsSL .../setup-mac.sh)"
# there is no clone yet, so clone to ~/.dotfiles and re-exec from there.
DOTFILES_REPO="https://github.com/davidgamero/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Resolve the dir this script lives in (empty/unknown when piped).
SELF="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SELF")" >/dev/null 2>&1 && pwd || true)"

if [ ! -f "$SCRIPT_DIR/link.sh" ]; then
	echo "setup: no local clone detected, bootstrapping into $DOTFILES_DIR..."
	if [ ! -d "$DOTFILES_DIR/.git" ]; then
		command -v git >/dev/null 2>&1 || { echo "error: git required to bootstrap" >&2; exit 1; }
		git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
	else
		echo "setup: existing clone found, reusing it"
	fi
	exec bash "$DOTFILES_DIR/setup-mac.sh"
fi

# install homebrew
if ! command -v brew >/dev/null 2>&1
then
	echo "homebrew not found, installing homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "homebrew found..."
fi

# install zsh
if [[ "$(basename "$SHELL")" != "zsh" ]]; then
	echo "Current shell is not zsh, installing..."
	brew install zsh
	chsh -s "$(which zsh)"
else
	echo "current shell is already zsh"
fi

# zsh4humans (z4h) deps. z4h itself self-installs on first interactive shell
# via the tracked ~/.zshenv bootstrap (linked below by link.sh). It just needs
# git + zsh + a few tools for the best experience.
brew install git fzf

# install tpm
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
	echo "tpm already found..."
fi

# install neovim and fonts
if ! command -v nvim >/dev/null 2>&1; then
	echo "neovim install not found, installing..."
	brew install neovim
	brew tap homebrew/cask-fonts
	brew install --cask font-cascadia-code
	brew install --cask font-cascadia-code-pl
	brew install --cask font-cascadia-mono
	brew install --cask font-cascadia-mono-pl
else
    echo "neovim install found..."
fi

# install kanata (keyboard remapper)
if ! command -v kanata >/dev/null 2>&1; then
	echo "kanata not found, installing..."
	brew install kanata
else
	echo "kanata already found..."
fi

# install zoxide (used by .zshrc for `z` dir jumping)
if ! command -v zoxide >/dev/null 2>&1; then
	echo "zoxide not found, installing..."
	brew install zoxide
else
	echo "zoxide already found..."
fi

# symlink tracked dotfiles into place (~/.config/*, ~/.zshrc)
"$SCRIPT_DIR/link.sh"

# install git hooks (pre-commit secret scanner)
"$SCRIPT_DIR/hooks/install-hooks.sh"

echo ""
echo "Setup complete. Copy config/zsh/devbox.local.zsh.example to"
echo "\$HOME/.config/zsh/devbox.local.zsh and fill in your real values if needed."
