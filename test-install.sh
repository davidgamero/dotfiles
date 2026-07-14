#!/usr/bin/env bash
#
# test-install.sh — validate the install/link tooling in isolation.
# Runs against a throwaway HOME so it never touches the real machine.
# Used by CI (.github/workflows/ci.yml) and runnable locally.

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "== 1. syntax check =="
for f in scripts/setup-mac.sh scripts/setup-ubuntu.sh scripts/setup-git-commit-signing.sh link.sh hooks/install-hooks.sh hooks/pre-commit test-install.sh; do
  if bash -n "$REPO_ROOT/$f"; then ok "syntax $f"; else bad "syntax $f"; fi
done

echo "== 2. isolated sandbox HOME =="
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
FAKE_HOME="$SANDBOX/home"
mkdir -p "$FAKE_HOME"
# Clone-free: point a fake dotfiles dir at the real repo tree (copy, no .git needed for link.sh).
FAKE_REPO="$FAKE_HOME/.dotfiles"
mkdir -p "$FAKE_REPO"
cp -R "$REPO_ROOT/config" "$FAKE_REPO/"
cp "$REPO_ROOT/link.sh" "$FAKE_REPO/"

echo "== 3. link.sh creates all symlinks =="
HOME="$FAKE_HOME" bash "$FAKE_REPO/link.sh" >/dev/null
check_link() {
  local path="$1" want="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$want" ]; then ok "linked $path"; else bad "link $path (got '$(readlink "$path" 2>/dev/null)')"; fi
}
check_link "$FAKE_HOME/.config/zsh/.zshrc"        "$FAKE_REPO/config/zsh/.zshrc"
check_link "$FAKE_HOME/.config/kanata/kanata.kbd" "$FAKE_REPO/config/kanata/kanata.kbd"
check_link "$FAKE_HOME/.config/nvim"              "$FAKE_REPO/config/nvim"
check_link "$FAKE_HOME/.zshenv"                   "$FAKE_REPO/config/zsh/.zshenv"
check_link "$FAKE_HOME/.tmux.conf"                "$FAKE_REPO/config/tmux/tmux.conf"
# ~/.zshrc chains through ~/.config/zsh/.zshrc
check_link "$FAKE_HOME/.zshrc"                    "$FAKE_HOME/.config/zsh/.zshrc"

echo "== 4. link.sh is idempotent (2nd run: no backups, all 'ok') =="
out="$(HOME="$FAKE_HOME" bash "$FAKE_REPO/link.sh")"
if echo "$out" | grep -q '^bak:'; then bad "2nd run created a backup (not idempotent)"; echo "$out"; else ok "no backups on re-run"; fi
if echo "$out" | grep -q '^link:'; then bad "2nd run re-created a link (not idempotent)"; else ok "no re-links on re-run"; fi
# No stray backup files anywhere
if find "$FAKE_HOME" -name '*.backup.*' | grep -q .; then bad "stray backup files exist"; else ok "no stray backups"; fi

echo "== 5. link.sh backs up a pre-existing real file/dir =="
rm "$FAKE_HOME/.config/nvim"
mkdir -p "$FAKE_HOME/.config/nvim"; echo "preexisting" > "$FAKE_HOME/.config/nvim/init.lua"
HOME="$FAKE_HOME" bash "$FAKE_REPO/link.sh" >/dev/null
if [ -L "$FAKE_HOME/.config/nvim" ] && find "$FAKE_HOME/.config" -maxdepth 1 -name 'nvim.backup.*' | grep -q .; then
  ok "pre-existing nvim dir backed up + relinked"
else bad "pre-existing nvim dir not handled"; fi

echo "== 6. pre-commit hook blocks a planted secret =="
HOOK_HOME="$SANDBOX/hookrepo"
git init -q "$HOOK_HOME"
cp -R "$REPO_ROOT/hooks" "$HOOK_HOME/"
cp "$REPO_ROOT/config/zsh/.zshrc" "$HOOK_HOME/sample.zsh" 2>/dev/null || true
(
  cd "$HOOK_HOME"
  git config user.email ci@test; git config user.name ci
  bash hooks/install-hooks.sh >/dev/null
  # Build a fake GUID at runtime so this test script contains no literal secret.
  fake_guid="$(printf '%s-%s-%s-%s-%s' c1089427 0000 0000 0000 000000000000)"
  printf 'SUB=%s\n' "$fake_guid" > leak.txt
  git add leak.txt
  if git commit -m "should block" >/dev/null 2>&1; then echo "  FAIL: hook did not block secret"; exit 1; else echo "  PASS: hook blocked planted GUID"; fi
  # clean commit should pass
  git rm -q --cached leak.txt; rm leak.txt
  echo "clean file" > ok.txt; git add ok.txt
  if git commit -m "clean" >/dev/null 2>&1; then echo "  PASS: hook allows clean commit"; else echo "  FAIL: hook blocked a clean commit"; exit 1; fi
) || FAIL=$((FAIL+1))

echo ""
echo "== RESULT: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
