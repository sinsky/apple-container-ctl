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
  --border-foreground 46 \
  --foreground 46 \
  --bold \
  "🚀 Starting Apple Container & Socktainer Environment"

# 0. Check prerequisites (container & socktainer installation via which)
for CMD in container socktainer; do
  if ! command -v "$CMD" >/dev/null 2>&1; then
    run_mise gum style --foreground 196 --bold "❌ Error: Required command '$CMD' was not found in PATH."
    echo "Please ensure both 'container' and 'socktainer' are installed."
    exit 1
  fi
done

# 1. Check & start Apple Container system services
if container system status --format json 2>/dev/null | grep -q '"status":"running"'; then
  echo "🟢 Apple Container system services are already running."
else
  run_mise gum spin --spinner dot --title "Starting Apple Container system services..." -- container system start
  echo "✅ Apple Container system services started."
fi

# 2. Start Socktainer via pitchfork (daemon process management)
echo ""
echo "🔌 Starting Socktainer daemon via pitchfork..."
run_mise pitchfork start socktainer

# 3. Set Docker context to socktainer
if command -v docker >/dev/null 2>&1; then
  docker context use socktainer >/dev/null 2>&1 || true
fi

echo ""
run_mise gum style \
  --foreground 46 \
  --bold \
  "🎉 Environment Ready! 'docker' commands will now run via Apple Container + Socktainer."
echo ""
