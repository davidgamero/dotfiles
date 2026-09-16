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
    if ! command -v git >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y ca-certificates git
    fi
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  exec bash "$DOTFILES_DIR/scripts/setup-ubuntu.sh" "$@"
fi

usage() {
  cat <<'EOF'
Usage: setup-ubuntu.sh [profiles...]

The core profile is always installed. Optional profiles:
  containers  Docker Engine and Compose
  kubernetes  kubectl and kind (implies containers)
  cloud       Azure CLI
  gui         Visual Studio Code
  languages   nvm and Go
  kanata      kanata, if Cargo is already installed
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
    containers|kubernetes|cloud|gui|languages|kanata|ai|signing)
      PROFILES="$PROFILES $profile"
      ;;
    *) echo "error: unknown profile: $profile" >&2; usage >&2; exit 2 ;;
  esac
done
if (( EXPLICIT_PROFILES == 0 )); then
  # shellcheck source=profile-picker.sh
  source "$SCRIPT_DIR/profile-picker.sh"
  pick_profiles ubuntu
fi
has_profile() { [[ " $PROFILES " == *" all "* || " $PROFILES " == *" $1 "* ]]; }

echo "setup: installing core Ubuntu tools..."
sudo apt-get update
sudo apt-get install -y \
  build-essential ca-certificates curl fd-find fzf gh git jq \
  ripgrep tmux unzip zoxide zsh

install_neovim() {
  local machine archive tmp asset_json download_url digest
  machine="$(uname -m)"
  case "$machine" in
    x86_64) archive=nvim-linux-x86_64.tar.gz ;;
    aarch64|arm64) archive=nvim-linux-arm64.tar.gz ;;
    *) echo "error: unsupported Neovim architecture: $machine" >&2; return 1 ;;
  esac
  tmp="$(mktemp -d)"
  asset_json="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest |
    jq -er --arg name "$archive" '.assets[] | select(.name == $name)')"
  download_url="$(jq -r '.browser_download_url' <<<"$asset_json")"
  digest="$(jq -r '.digest | sub("^sha256:"; "")' <<<"$asset_json")"
  [[ "$digest" =~ ^[0-9a-f]{64}$ ]] || { echo "error: missing Neovim SHA-256 digest" >&2; return 1; }
  curl -fsSLo "$tmp/$archive" "$download_url"
  printf '%s  %s\n' "$digest" "$tmp/$archive" | sha256sum --check --status
  sudo rm -rf /opt/nvim
  sudo mkdir -p /opt/nvim
  sudo tar -C /opt/nvim --strip-components=1 -xzf "$tmp/$archive"
  sudo ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$tmp"
}

install_neovim

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

# Ubuntu packages fd as fdfind. Give tools such as LazyVim the standard name.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

if [[ "$(basename "${SHELL:-}")" != zsh ]] && command -v chsh >/dev/null 2>&1; then
  chsh -s "$(command -v zsh)" || echo "note: could not change the login shell; run chsh manually"
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

install_docker() {
  echo "setup: installing Docker..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' \
    "$(dpkg --print-architecture)" "$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "note: Docker is installed. Add your user to the docker group only if you accept its root-equivalent access:"
  echo "  sudo usermod -aG docker $USER"
}

install_kubernetes() {
  local machine arch kind_arch kubectl_version tmp
  machine="$(uname -m)"
  case "$machine" in
    x86_64) arch=amd64; kind_arch=amd64 ;;
    aarch64|arm64) arch=arm64; kind_arch=arm64 ;;
    *) echo "error: unsupported Kubernetes architecture: $machine" >&2; return 1 ;;
  esac
  tmp="$(mktemp -d)"
  kubectl_version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSLo "$tmp/kubectl" "https://dl.k8s.io/release/$kubectl_version/bin/linux/$arch/kubectl"
  curl -fsSLo "$tmp/kubectl.sha256" "https://dl.k8s.io/release/$kubectl_version/bin/linux/$arch/kubectl.sha256"
  printf '%s  %s\n' "$(cat "$tmp/kubectl.sha256")" "$tmp/kubectl" | sha256sum --check --status
  sudo install -m 0755 "$tmp/kubectl" /usr/local/bin/kubectl

  curl -fsSLo "$tmp/kind" "https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-$kind_arch"
  curl -fsSLo "$tmp/kind.sha256" "https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-$kind_arch.sha256sum"
  printf '%s  %s\n' "$(cut -d' ' -f1 "$tmp/kind.sha256")" "$tmp/kind" | sha256sum --check --status
  sudo install -m 0755 "$tmp/kind" /usr/local/bin/kind
  rm -rf "$tmp"
}

if has_profile containers || has_profile kubernetes; then
  install_docker
fi
has_profile kubernetes && install_kubernetes

if has_profile cloud; then
  curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

if has_profile gui; then
  sudo snap install code --classic
fi

if has_profile languages; then
  if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  fi
  sudo apt-get install -y golang-go
fi

if has_profile kanata; then
  if command -v cargo >/dev/null 2>&1; then
    cargo install kanata
  else
    echo "error: the kanata profile requires Cargo; install Rust first" >&2
    exit 1
  fi
fi

if has_profile ai; then
  curl -fsSL https://opencode.ai/install | bash
fi

"$REPO_ROOT/link.sh"
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" "$HOME/.tmux/plugins/tpm/bin/install_plugins"
"$REPO_ROOT/hooks/install-hooks.sh"

if has_profile signing; then
  bash "$SCRIPT_DIR/setup-git-commit-signing.sh"
fi

echo
echo "Setup complete. Restart your shell to use zsh and linked configuration."
echo "Optional machine-local values belong in ~/.config/zsh/*.local.zsh."
