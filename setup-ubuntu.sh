#!/bin/bash
set -e

# --- self-bootstrap -------------------------------------------------------
# Needs the repo on disk (for link.sh + hooks). When run via
#   sh -c "$(curl -fsSL .../setup-ubuntu.sh)"
# there is no clone yet, so clone to ~/.dotfiles and re-exec from there.
DOTFILES_REPO="https://github.com/davidgamero/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SELF="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SELF")" >/dev/null 2>&1 && pwd || true)"

if [ ! -f "$SCRIPT_DIR/link.sh" ]; then
	echo "setup: no local clone detected, bootstrapping into $DOTFILES_DIR..."
	if [ ! -d "$DOTFILES_DIR/.git" ]; then
		command -v git >/dev/null 2>&1 || { sudo apt update && sudo apt install -y git; }
		git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
	else
		echo "setup: existing clone found, reusing it"
	fi
	exec bash "$DOTFILES_DIR/setup-ubuntu.sh"
fi

# git
sudo add-apt-repository ppa:git-core/ppa
sudo apt update
sudo apt install git

# install zsh
sudo apt install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# zsh-autosuggestions install
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

git clone https://github.com/LazyVim/starter ~/.config/nvim

# base updates
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y make unzip jq sudo build-essential

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# kind
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind


# tmux
sudo apt install tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
mkdir ~/.config/tmux
echo "# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Other examples:
# set -g @plugin 'github_username/plugin_name'
# set -g @plugin 'github_username/plugin_name#branch'
# set -g @plugin 'git@github.com:user/plugin'
# set -g @plugin 'git@bitbucket.com:user/plugin'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'" > ~/.config/tmux/tmux.conf

# AZCLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# vscode
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg

sudo apt install apt-transport-https
sudo apt update
sudo apt install code # or code-insiders

# golang
wget https://git.io/go-installer.sh && bash go-installer.sh

# kanata (keyboard remapper) — not in apt; install via cargo if available
if ! command -v kanata >/dev/null 2>&1; then
	if command -v cargo >/dev/null 2>&1; then
		echo "installing kanata via cargo..."
		cargo install kanata || echo "kanata install failed; install manually from https://github.com/jtroo/kanata"
	else
		echo "note: skipping kanata (no cargo). See https://github.com/jtroo/kanata for install."
	fi
fi

# symlink tracked dotfiles into place (~/.config/*, ~/.zshrc)
"$SCRIPT_DIR/link.sh"

# install git hooks (pre-commit secret scanner)
"$SCRIPT_DIR/hooks/install-hooks.sh"

echo ""
echo "Setup complete. Copy config/zsh/devbox.local.zsh.example to"
echo "~/.config/zsh/devbox.local.zsh and fill in your real values if needed."

