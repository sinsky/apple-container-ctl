#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

run_mise() {
  mise exec -- "$@"
}


run_mise gum style \
  --border rounded \
  --margin "0 1" \
  --padding "1 2" \
  --border-foreground 212 \
  --foreground 212 \
  --bold \
  "🔍 Checking Installation Status (container & socktainer)"

echo ""

STATUS=0

check_cmd() {
  local CMD_NAME="$1"
  local DISPLAY_NAME="$2"
  local VERSION_CMD="$3"

  if BIN_PATH=$(command -v "$CMD_NAME" 2>/dev/null); then
    echo "🟢 [$DISPLAY_NAME] Installed at: $BIN_PATH"
    if [ -n "$VERSION_CMD" ]; then
      VER_OUT=$(eval "$VERSION_CMD" 2>/dev/null | head -n 1)
      echo "   └─ Version: $VER_OUT"
    fi
  else
    echo "🔴 [$DISPLAY_NAME] NOT FOUND ('$CMD_NAME' is not installed or not in PATH)"
    STATUS=1
  fi
  echo ""
}

check_cmd "container" "Apple Container CLI" "container --version"
check_cmd "socktainer" "Socktainer Bridge Proxy" "socktainer --version"
check_cmd "docker" "Docker CLI Client" "docker --version"

if [ $STATUS -eq 0 ]; then
  run_mise gum style --foreground 46 --bold "✅ All required CLI tools are properly installed!"
else
  run_mise gum style --foreground 196 --bold "❌ Missing required tools. Please verify your Apple Container & Socktainer installations."
fi

exit $STATUS
