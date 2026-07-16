# AGENTS.md

Guidance for AI agents working in this dotfiles repo.

## What this repo is

Version-controlled configs symlinked into place (see `link.sh` and the README).
Editing a linked file in `~/.config/...` writes through the symlink to the repo,
so live changes and repo changes are the same file. That makes it easy for the
working tree to drift out of sync with the remote if changes aren't committed.

## Keeping things in sync (important)

**After making any change to a config in this repo (or to a symlinked file that
writes through to it), ask the user whether to commit and push the update** so
the repo stays in sync with what's live on the machine.

- Confirm before committing/pushing — do not commit automatically unless the
  user has already said to.
- Show the user `git status` / `git diff` before committing so they can review.
- Use a concise commit message that matches the existing history style
  (e.g. `kanata: map F-row to brightness, media, and volume keys`).
- Stage only the files that are actually part of the intended change.

Example prompt to the user after a change:
> I've updated `config/kanata/kanata.kbd`. Want me to commit and push this to
> the dotfiles repo so it stays in sync?

## Commit workflow

```
cd ~/.dotfiles
git status                     # review what changed
git diff <file>                # review the actual change
git add <file>                 # stage only intended files
git commit -m "..."            # pre-commit hook scans for secrets
git push origin main
```

## Secret scanner

A `pre-commit` hook blocks commits containing GUIDs / Azure subscription IDs,
private keys, cloud tokens, `@microsoft.com` emails, connection strings, and
internal hostnames. If a commit is rejected:

- Do NOT use `--no-verify` to bypass it unless the user confirms it's a genuine
  false positive.
- Machine-local secrets belong in gitignored `*.local.zsh` files (see README),
  not in tracked configs.

## Out-of-repo state

Some changes live outside the repo and are NOT tracked by git (e.g. macOS
`~/Library/Preferences` defaults like `com.apple.symbolichotkeys`). When a fix
touches that kind of state, tell the user it won't sync via the repo, and offer
to add a setup script under `scripts/` if it should be reproducible on a new
machine.
