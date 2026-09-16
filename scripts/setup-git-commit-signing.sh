#!/usr/bin/env bash
# Configure SSH-based Git commit signing.
# Pass a public key path as the first argument, or let the script prefer
# ~/.ssh/id_ed25519.pub and then ~/.ssh/id_rsa.pub.
set -euo pipefail

KEY_PATH="${1:-}"
if [[ -z "$KEY_PATH" ]]; then
  for candidate in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
    if [[ -f "$candidate" ]]; then
      KEY_PATH="$candidate"
      break
    fi
  done
fi
[[ -n "$KEY_PATH" && -f "$KEY_PATH" ]] || { echo "error: no SSH public key found" >&2; exit 1; }

GIT_EMAIL="$(git config --global --get user.email || true)"
[[ -n "$GIT_EMAIL" ]] || { echo "error: configure git user.email before enabling signing" >&2; exit 1; }

git config --global gpg.format ssh
git config --global user.signingkey "$KEY_PATH"

mkdir -p "$HOME/.ssh"
SIGNER_LINE="$GIT_EMAIL namespaces=\"git\" $(cat "$KEY_PATH")"
touch "$HOME/.ssh/allowed_signers"
if ! grep -qF "$SIGNER_LINE" "$HOME/.ssh/allowed_signers"; then
  printf '%s\n' "$SIGNER_LINE" >> "$HOME/.ssh/allowed_signers"
fi
git config --global gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"

git config --global commit.gpgsign true
git config --global tag.gpgsign true

echo "Git SSH signing configured with $KEY_PATH"
