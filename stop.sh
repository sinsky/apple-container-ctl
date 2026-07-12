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
  --border-foreground 204 \
  --foreground 204 \
  --bold \
  "🛑 Stopping Apple Container & Socktainer Environment"

echo ""

# 1. Stop Socktainer via pitchfork
echo "🔌 Stopping Socktainer daemon via pitchfork..."
run_mise pitchfork stop socktainer || echo "Socktainer was already stopped."

# 2. Stop Apple Container system services
echo ""
run_mise gum spin --spinner dot --title "Stopping Apple Container system services..." -- container system stop || echo "Apple Container services were already stopped."

echo ""
run_mise gum style \
  --foreground 214 \
  --bold \
  "✅ All Apple Container & Socktainer services have been stopped cleanly."
echo ""
