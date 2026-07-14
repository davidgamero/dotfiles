#!/usr/bin/env bash
# Configure SSH-based git commit signing.
# Assumes an ssh key exists at ~/.ssh/id_rsa.pub and is added to GitHub
# for both push and signing.
set -euo pipefail

git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_rsa.pub

# Add this key to allowed_signers (idempotent — don't duplicate).
SIGNER_LINE="$(git config --get user.email) namespaces=\"git\" $(cat ~/.ssh/id_rsa.pub)"
touch ~/.ssh/allowed_signers
if ! grep -qF "$SIGNER_LINE" ~/.ssh/allowed_signers; then
	echo "$SIGNER_LINE" >> ~/.ssh/allowed_signers
fi
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers

git config --global commit.gpgsign true
git config --global tag.gpgsign true
