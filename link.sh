#!/usr/bin/env bash
#
# link.sh — symlink tracked dotfiles from this repo into their home locations.
# Idempotent and safe to re-run. Backs up any existing real file.
#
# Mapping: repo config/<X>  ->  ~/.config/<X>
#          (add non-.config dotfiles below as needed)

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

link() {
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    echo "skip: $src missing"; return
  fi
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "ok:   $dst"; return
  fi
  mkdir -p -- "$(dirname -- "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    local bak
    bak="$dst.backup.$(date +%Y%m%d%H%M%S)"
    mv -- "$dst" "$bak"
    echo "bak:  $dst -> $bak"
  fi
  ln -s -- "$src" "$dst"
  echo "link: $dst -> $src"
}

# --- ~/.config mirror ------------------------------------------------------
link "$REPO_ROOT/config/zsh/.zshrc"        "$HOME/.config/zsh/.zshrc"
link "$REPO_ROOT/config/kanata/kanata.kbd" "$HOME/.config/kanata/kanata.kbd"
# nvim: link the whole config dir (~/.config/nvim -> repo config/nvim)
link "$REPO_ROOT/config/nvim"              "$HOME/.config/nvim"

# --- home-level convenience symlink ---------------------------------------
# ~/.zshenv bootstraps zsh4humans (fetches z4h, sets ZDOTDIR) — must live at $HOME.
link "$REPO_ROOT/config/zsh/.zshenv" "$HOME/.zshenv"
# ~/.zshrc -> ~/.config/zsh/.zshrc (z4h reads ~/.zshrc)
link "$HOME/.config/zsh/.zshrc" "$HOME/.zshrc"
# tmux reads ~/.tmux.conf
link "$REPO_ROOT/config/tmux/tmux.conf" "$HOME/.tmux.conf"

echo "done."
