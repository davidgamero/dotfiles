#!/usr/bin/env bash

# Set PROFILES from a portable numbered prompt. Explicit CLI profiles bypass it.
pick_profiles() {
  local platform="$1" input item number name
  [[ -t 0 && -t 1 ]] || return 0

  echo
  echo "🧰 Core tools (including Neovim) are always installed."
  echo "Select optional profiles (comma-separated, Enter for core only):"
  echo
  echo "  1) 🐳 Containers"
  echo "  2) ☸️  Kubernetes"
  echo "  3) ☁️  Cloud tools"
  echo "  4) 🖥️  GUI apps"
  echo "  5) 🧑‍💻 Language runtimes"
  echo "  6) ⌨️  Kanata"
  if [[ "$platform" == mac ]]; then
    echo "  7) 🔤 Fonts"
  fi
  echo "  8) 🔏 Git signing"
  echo "  9) 🤖 AI tools (OpenCode)"
  echo "  a) ✨ Everything"
  echo
  read -r -p "Profiles: " input
  [[ -n "$input" ]] || return 0

  input="${input//,/ }"
  for item in $input; do
    case "$item" in
      a|A|all) PROFILES="$PROFILES all" ;;
      1) PROFILES="$PROFILES containers" ;;
      2) PROFILES="$PROFILES kubernetes" ;;
      3) PROFILES="$PROFILES cloud" ;;
      4) PROFILES="$PROFILES gui" ;;
      5) PROFILES="$PROFILES languages" ;;
      6) PROFILES="$PROFILES kanata" ;;
      7)
        if [[ "$platform" == mac ]]; then
          PROFILES="$PROFILES fonts"
        else
          echo "⚠️  Fonts profile is only available on macOS; skipping 7."
        fi
        ;;
      8) PROFILES="$PROFILES signing" ;;
      9) PROFILES="$PROFILES ai" ;;
      *) echo "⚠️  Unknown selection '$item'; skipping." ;;
    esac
  done

  if [[ -n "$PROFILES" ]]; then
    echo "✅ Selected:$PROFILES"
  else
    echo "✅ Core only"
  fi
}
