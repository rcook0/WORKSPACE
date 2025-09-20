#!/usr/bin/env bash
set -e

# Config
TAIL_LINES=20

# Clear Codespaces ephemeral token so gh auth works properly
unset GITHUB_TOKEN

# Check if gh is authenticated, otherwise run login with defaults
if ! gh auth status >/dev/null 2>&1; then
  echo "🔑 GitHub CLI not authenticated — logging in with SSH via web flow..."
  gh auth login -h github.com -p ssh -w -y
fi

# Call the real clone.sh in WORKSPACE repo
/workspaces/WORKSPACE/clone.sh "$@"

# Show last 20 log lines for quick feedback
LOG_FILE="/workspaces/WORKSPACE/logs/sync.log"

if [ -f "$LOG_FILE" ]; then
  if [[ "$1" == "-a" || "$1" == "--all" ]]; then
    echo -e "\n📜 Full sync log ($LOG_FILE):"
    cat "$LOG_FILE"
  else
    echo -e "\n📜 Last $TAIL_LINES lines from $LOG_FILE:"
    tail -n "$TAIL_LINES" "$LOG_FILE"
  fi
else
  echo "!!! No sync.log found yet."
fi
