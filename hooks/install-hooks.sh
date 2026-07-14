#!/usr/bin/env bash
#
# install-hooks.sh — symlink repo hooks into .git/hooks so they run on commit.
# Idempotent. Run after cloning the dotfiles repo.

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
HOOK_SRC="$REPO_ROOT/hooks/pre-commit"
HOOK_DST="$REPO_ROOT/.git/hooks/pre-commit"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo "error: $REPO_ROOT is not a git repo" >&2
  exit 1
fi

chmod +x "$HOOK_SRC"
ln -sf "$HOOK_SRC" "$HOOK_DST"
echo "installed pre-commit hook -> $HOOK_DST"
