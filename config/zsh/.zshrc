# Personal Zsh configuration file (zsh4humans).
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Capture startup begin time to measure zshrc load time.
zmodload zsh/datetime
_ZSHRC_START=$EPOCHREALTIME

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
zstyle ':z4h:' auto-update      'no'
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'mac'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow accepts the whole autosuggestion.
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'

# direnv off by default.
zstyle ':z4h:direnv'         enable 'no'
zstyle ':z4h:direnv:success' notify 'yes'

# No SSH teleportation by default.
zstyle ':z4h:ssh:*' enable 'no'

# Initialize z4h. Console I/O is unavailable after this point until Zsh is
# fully initialized. Anything needing user interaction or network I/O goes ABOVE.
z4h init || return

# ---------------------------------------------------------------------------
# Everything below runs after init (fast, no network).
# ---------------------------------------------------------------------------

# --- Environment / PATH ---------------------------------------------------
export EDITOR=nvim

# Homebrew (Apple Silicon).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Cargo (was previously in ~/.zshenv).
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# BEGIN Agency MANAGED BLOCK
if [[ ":${PATH}:" != *":/Users/d/.config/agency/CurrentVersion:"* ]]; then
    export PATH="/Users/d/.config/agency/CurrentVersion:${PATH}"
fi
# END Agency MANAGED BLOCK

# Added by Agency Claude Code installer
export PATH="/Users/d/.claude-cli/currentVersion:$PATH"

# --- nvm (lazy) -----------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
# Put default node on PATH immediately (no nvm.sh sourcing cost).
if [ -s "$NVM_DIR/alias/default" ]; then
  DEFAULT_VER="$(cat "$NVM_DIR/alias/default")"
  NODE_BIN="$(ls -d "$NVM_DIR/versions/node/v${DEFAULT_VER}"*/bin 2>/dev/null | tail -1)"
  [ -n "$NODE_BIN" ] && export PATH="$NODE_BIN:$PATH"
fi
_lazy_nvm_load() {
  unset -f nvm
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}
nvm() { _lazy_nvm_load; nvm "$@"; }

# --- oh-my-zsh plugins ----------------------------------------------------
# Dropped: z4h provides autosuggestions, syntax highlighting, completions,
# and z-style dir jumping (Alt+Down / z4h-cd) natively.

# --- zoxide: `z dirname` frecency jumping (replaces omz `z`) --------------
# `z foo` jumps to best-matching dir; `zi foo` opens fzf picker.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# --- Aliases --------------------------------------------------------------
alias nvrc="nvim ~/.config/nvim"
alias rc="nvim ~/.zshrc && echo 'reloading ~/.zshrc' && source ~/.zshrc"

# --- One-time git autofetch config ---------------------------------------
if [[ ! -f "$HOME/.zshrc_gitconfig_done" ]]; then
  git config --global fetch.autoFetch true
  git config --global fetch.autoFetchInterval 300  # 5 minutes
  : > "$HOME/.zshrc_gitconfig_done"
fi

# --- Functions ------------------------------------------------------------
setup-repo() {
  TARGET_REPO=$1
  FORK_GITHUB_USERNAME=davidgamero

  if [[ -n "${TARGET_REPO}" ]]; then
    TARGET_REPO=$(echo "$TARGET_REPO" | sed -E 's#^https://github\.com/##' | sed 's#\.git$##')
  fi

  if [[ -z "${TARGET_REPO}" ]]; then
    if git rev-parse --git-dir > /dev/null 2>&1; then
      TARGET_REPO=$(git remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##' | sed 's/.git$//')
    fi
    if [[ -z "${TARGET_REPO}" ]]; then
      echo "Usage: git-fork [owner/repo]"
      echo "Or run from a git repo with origin set"
      return 1
    fi
  fi

  local NEED_CLONE=false
  local CLONE_DIR=""
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    NEED_CLONE=true
    CLONE_DIR="$(pwd)/$(basename $TARGET_REPO)"
    echo "Not in a git repository. Will clone to: $CLONE_DIR"
    echo -n "Clone here? [Y/n/path]: "
    read CONFIRM
    if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
      echo "Aborted"
      return 1
    elif [[ -n "$CONFIRM" && "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
      CLONE_DIR="$CONFIRM"
    fi
  fi

  if [[ "$NEED_CLONE" == false ]]; then
    local CURRENT_REPO=$(git remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##' | sed 's/.git$//')
    if [[ -n "$TARGET_REPO" && "$CURRENT_REPO" != "$TARGET_REPO" && "$CURRENT_REPO" != "${FORK_GITHUB_USERNAME}/$(basename $TARGET_REPO)" ]]; then
      CLONE_DIR="$(pwd)/$(basename $TARGET_REPO)"
      echo "You're in a different repo ($CURRENT_REPO), not $TARGET_REPO."
      echo -n "Clone $TARGET_REPO to $CLONE_DIR instead? [Y/n/path]: "
      read CONFIRM
      if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
        echo "Aborted"
        return 1
      elif [[ -n "$CONFIRM" && "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        CLONE_DIR="$CONFIRM"
      fi
      NEED_CLONE=true
    fi
  fi

  echo "Setting up fork for: $TARGET_REPO"

  if ! gh repo view "${FORK_GITHUB_USERNAME}/$(basename $TARGET_REPO)" > /dev/null 2>&1; then
    echo "Creating fork..."
    gh repo fork "$TARGET_REPO" --clone=false
  else
    echo "Fork already exists"
  fi

  if [[ "$NEED_CLONE" == true ]]; then
    echo "Cloning to $CLONE_DIR..."
    git clone "git@github.com:${FORK_GITHUB_USERNAME}/$(basename $TARGET_REPO).git" "$CLONE_DIR"
    cd "$CLONE_DIR"
    echo "Adding upstream remote"
    git remote add upstream "git@github.com:${TARGET_REPO}.git"
  else
    CURRENT_ORIGIN=$(git remote get-url origin 2>/dev/null)
    if [[ "$CURRENT_ORIGIN" == *"$TARGET_REPO"* ]] && [[ "$CURRENT_ORIGIN" != *"$FORK_GITHUB_USERNAME"* ]]; then
      echo "Renaming origin -> upstream"
      git remote rename origin upstream 2>/dev/null || true
      echo "Adding fork as origin"
      git remote add origin "git@github.com:${FORK_GITHUB_USERNAME}/$(basename $TARGET_REPO).git"
    elif ! git remote get-url upstream > /dev/null 2>&1; then
      echo "Adding upstream remote"
      git remote add upstream "git@github.com:${TARGET_REPO}.git"
    fi
  fi

  DEFAULT_BRANCH=$(gh repo view "$TARGET_REPO" --json defaultBranchRef --jq '.defaultBranchRef.name')
  echo "Setting $DEFAULT_BRANCH to track upstream/$DEFAULT_BRANCH"
  git fetch upstream 2>/dev/null || true
  git branch --set-upstream-to=upstream/$DEFAULT_BRANCH $DEFAULT_BRANCH 2>/dev/null || true

  echo "Enabling push.autoSetupRemote"
  git config --local push.autoSetupRemote true

  echo "Blocking direct pushes to origin/$DEFAULT_BRANCH"
  git config --local branch.$DEFAULT_BRANCH.pushRemote no_push

  echo ""
  echo "Done! Remotes:"
  git remote -v
}

# devbox config (RG / VM name / subscription ID) lives in a gitignored
# local file so infra identifiers stay out of the public repo.
# See devbox.local.zsh.example for the template.
[[ -f "$HOME/.config/zsh/devbox.local.zsh" ]] && source "$HOME/.config/zsh/devbox.local.zsh"
devbox() {
  echo "Querying devbox power state..."
  DEVBOX_POWER_STATE=$(az vm show -g $DEVBOX_RG -n $DEVBOX_VM_NAME -d --query powerState -o tsv --subscription $DEVBOX_SUB_ID)
  echo "DEVBOX_POWER_STATE=$DEVBOX_POWER_STATE"

  if [[ $DEVBOX_POWER_STATE != "VM running" ]]; then
    echo "Starting devbox..."
    az vm start --resource-group "$DEVBOX_RG" --name "$DEVBOX_VM_NAME" --subscription "$DEVBOX_SUB_ID"
  else
    echo "already running..."
  fi

  echo "Connecting..."
  while true; do
    ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=3 "${DEVBOX_SSH_HOST:-$DEVBOX_VM_NAME}"    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1005l'
    stty sane
    while read -r -t 0.1; do :; done
    echo "\n\033[33m--- Disconnected. Press Enter to reconnect (Ctrl-C to quit) ---\033[0m"
    read -r
  done
}

devbox5() {
  echo "Querying devbox5 power state..."
  DEVBOX_POWER_STATE=$(az vm show -g $DEVBOX5_RG -n $DEVBOX5_VM_NAME -d --query powerState -o tsv --subscription $DEVBOX5_SUB_ID)
  echo "DEVBOX5_POWER_STATE=$DEVBOX_POWER_STATE"

  if [[ $DEVBOX_POWER_STATE != "VM running" ]]; then
    echo "Starting devbox $DEVBOX5_VM_NAME..."
    az vm start --resource-group "$DEVBOX5_RG" --name "$DEVBOX5_VM_NAME" --subscription "$DEVBOX5_SUB_ID"
  else
    echo "already running..."
  fi

  echo "Connecting..."
  while true; do
    ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=3 "${DEVBOX5_SSH_HOST:-$DEVBOX5_VM_NAME}"
    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1005l'
    stty sane
    while read -r -t 0.1; do :; done
    echo "\n\033[33m--- Disconnected. Press Enter to reconnect (Ctrl-C to quit) ---\033[0m"
    read -r
  done
}

# --- Shell options --------------------------------------------------------
setopt glob_dots
setopt no_auto_menu

# --- Startup banner: date / unix time / load time ------------------------
# Use zsh builtin strftime (no external `date` fork).
local _now=$EPOCHSECONDS
strftime '%a %b %d %Y %I:%M:%S %p %Z' $_now
print -r -- $_now
printf 'zshrc load: %.0fms\n' $(( (EPOCHREALTIME - _ZSHRC_START) * 1000 ))
