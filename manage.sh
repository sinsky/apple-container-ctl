#!/usr/bin/env bash
set -e

# Ensure we are in the script's directory so mise and pitchfork use local configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Helper to run commands with mise tools available
run_mise() {
  mise exec -- "$@"
}

GUM="run_mise gum"
PITCHFORK="run_mise pitchfork"
# Check prerequisites (container & socktainer installation via which)
for CMD in container socktainer; do
  if ! command -v "$CMD" >/dev/null 2>&1; then
    run_mise gum style --foreground 196 --bold "❌ Error: Required command '$CMD' was not found in PATH."
    echo "Please ensure both 'container' and 'socktainer' are installed."
    exit 1
  fi
done

# Function to display header
show_header() {
  clear || true
  run_mise gum style \
    --border double \
    --margin "0 1" \
    --padding "1 2" \
    --border-foreground 212 \
    --foreground 212 \
    --bold \
    "🍎 Apple Container & Socktainer Manager"
}

# Function to get current status summary
get_status_summary() {
  echo ""
  run_mise gum style --foreground 99 --bold "System Status Overview:"

  # Check Apple Container status
  if container system status --format json 2>/dev/null | grep -q '"status":"running"'; then
    CONTAINER_STATUS="🟢 RUNNING"
  else
    CONTAINER_STATUS="🔴 STOPPED"
  fi

  # Check Socktainer via pitchfork
  if run_mise pitchfork status socktainer 2>/dev/null | grep -i -q "running"; then
    SOCKTAINER_STATUS="🟢 RUNNING"
  else
    SOCKTAINER_STATUS="🔴 STOPPED"
  fi

  echo "  • Apple Container (container system): $CONTAINER_STATUS"
  echo "  • Socktainer Daemon (pitchfork):      $SOCKTAINER_STATUS"
  echo ""
}

# Start all services
start_all() {
  echo ""
  run_mise gum style --foreground 212 --bold "Starting Apple Container & Socktainer..."

  run_mise gum spin --spinner dot --title "Starting Apple Container system services..." -- container system start
  echo "✅ Apple Container system services started."

  echo "Starting Socktainer daemon via pitchfork..."
  run_mise pitchfork start socktainer
  echo "✅ Socktainer daemon is ready."

  # Ensure docker context is set to socktainer
  if command -v docker >/dev/null 2>&1; then
    docker context use socktainer >/dev/null 2>&1 || true
  fi

  run_mise gum style --foreground 46 --bold "🎉 Environment is ready! You can now run 'docker' commands."
  echo ""
  read -n 1 -s -r -p "Press any key to continue..."
}

# Stop all services
stop_all() {
  echo ""
  run_mise gum style --foreground 204 --bold "Stopping Socktainer & Apple Container..."

  echo "🔌 Stopping Socktainer daemon via pitchfork..."
  run_mise pitchfork stop socktainer || true
  echo "✅ Socktainer daemon stopped."

  run_mise gum spin --spinner dot --title "Stopping Apple Container system services..." -- container system stop || true
  echo "✅ Apple Container system services stopped."

  run_mise gum style --foreground 214 --bold "🛑 All container services have been shut down."
  echo ""
  read -n 1 -s -r -p "Press any key to continue..."
}

# Show detailed status
show_detailed_status() {
  echo ""
  run_mise gum style --foreground 212 --bold "🍎 Apple Container Status (container system status):"
  container system status || echo "Apple Container services stopped."
  echo ""
  run_mise gum style --foreground 212 --bold "🔌 Socktainer Status (pitchfork status socktainer):"
  run_mise pitchfork status socktainer || echo "Socktainer stopped."
  echo ""
  if command -v docker >/dev/null 2>&1; then
    run_mise gum style --foreground 212 --bold "🐳 Docker Context & Version Info:"
    echo "Current Docker context: $(docker context show 2>/dev/null || echo 'N/A')"
    docker version 2>/dev/null || echo "Docker CLI cannot reach server (socktainer might be stopped)."
  fi
  echo ""
  read -n 1 -s -r -p "Press any key to continue..."
}

# View Socktainer logs
view_logs() {
  echo ""
  run_mise gum style --foreground 212 --bold "📋 Recent Socktainer Logs:"
  run_mise pitchfork logs socktainer || echo "No logs found."
  echo ""
  read -n 1 -s -r -p "Press any key to continue..."
}

# Main loop
while true; do
  show_header
  get_status_summary

  CHOICE=$(run_mise gum choose \
    "🚀 Start All (Apple Container & Socktainer)" \
    "🛑 Stop All (Socktainer & Apple Container)" \
    "🔄 Restart All" \
    "🍏 Apple Container Only -> Start/Stop" \
    "🔌 Socktainer Only -> Start/Stop" \
    "📊 Show Detailed Status & Docker Info" \
    "📋 View Socktainer Logs" \
    "❌ Exit")

  case "$CHOICE" in
    "🚀 Start All (Apple Container & Socktainer)")
      start_all
      ;;
    "🛑 Stop All (Socktainer & Apple Container)")
      stop_all
      ;;
    "🔄 Restart All")
      stop_all
      start_all
      ;;
    "🍏 Apple Container Only -> Start/Stop")
      SUB=$(run_mise gum choose "Start Apple Container" "Stop Apple Container" "Back")
      if [ "$SUB" = "Start Apple Container" ]; then
        container system start
        read -n 1 -s -r -p "Press any key to continue..."
      elif [ "$SUB" = "Stop Apple Container" ]; then
        container system stop
        read -n 1 -s -r -p "Press any key to continue..."
      fi
      ;;
    "🔌 Socktainer Only -> Start/Stop")
      SUB=$(run_mise gum choose "Start Socktainer via pitchfork" "Stop Socktainer via pitchfork" "Back")
      if [ "$SUB" = "Start Socktainer via pitchfork" ]; then
        run_mise pitchfork start socktainer
        read -n 1 -s -r -p "Press any key to continue..."
      elif [ "$SUB" = "Stop Socktainer via pitchfork" ]; then
        run_mise pitchfork stop socktainer
        read -n 1 -s -r -p "Press any key to continue..."
      fi
      ;;
    "📊 Show Detailed Status & Docker Info")
      show_detailed_status
      ;;
    "📋 View Socktainer Logs")
      view_logs
      ;;
    "❌ Exit"|"")
      echo ""
      run_mise gum style --foreground 212 "Goodbye! 👋"
      break
      ;;
  esac
done
