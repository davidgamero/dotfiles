#!/bin/bash

# install homebrew
if ! command -v brew 2>&1 >/dev/null
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
	chsh -s $(which zsh)
else
	echo "current shell is already zsh"	
fi

# install ohmyzsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
	echo "Oh My Zsh not found, installing..."
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	echo "ohmyzsh already found..."
fi

# install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

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

# symlink tracked dotfiles into place (~/.config/*, ~/.zshrc)
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
"$SCRIPT_DIR/link.sh"

# install git hooks (pre-commit secret scanner)
"$SCRIPT_DIR/hooks/install-hooks.sh"

echo ""
echo "Setup complete. Copy config/zsh/devbox.local.zsh.example to"
echo "~/.config/zsh/devbox.local.zsh and fill in your real values if needed."
