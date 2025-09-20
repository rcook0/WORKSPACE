#!/usr/bin/env bash
set -e

# === Config ===
TAIL_LINES=20   # how many log lines to show after sync
LOG_FILE="/workspaces/WORKSPACE/logs/sync.log"

# Parse options
SHOW_ALL=false
CLEAR_LOG=false
for arg in "$@"; do
  case $arg in
    -a|--all) SHOW_ALL=true ;;
    -c|--clear) CLEAR_LOG=true ;;
  esac
done

# Clear Codespaces ephemeral token so gh auth works properly
unset GITHUB_TOKEN

# Clear log if requested
if $CLEAR_LOG; then
  echo "🧹 Clearing sync log at $LOG_FILE"
  : > "$LOG_FILE"
fi

# Check if gh is authenticated, otherwise run login with defaults
if ! gh auth status >/dev/null 2>&1; then
  echo "🔑 GitHub CLI not authenticated — logging in with SSH via web flow..."
  gh auth login -h github.com -p ssh -w -y
fi

# Call the real clone.sh in WORKSPACE repo
/workspaces/WORKSPACE/clone.sh "$@"

# Show log output
if [ -f "$LOG_FILE" ]; then
  if $SHOW_ALL; then
    echo -e "\n📜 Full sync log ($LOG_FILE):"
    cat "$LOG_FILE"
  else
    echo -e "\n📜 Last $TAIL_LINES lines from $LOG_FILE:"
    tail -n "$TAIL_LINES" "$LOG_FILE"
  fi
else
  echo "⚠️  No sync.log found yet."
fi
