#!/usr/bin/env bash
set -e

# Clear Codespaces ephemeral token so gh auth works properly
unset GITHUB_TOKEN

# Check if gh is authenticated, otherwise run login interactively
if ! gh auth status >/dev/null 2>&1; then
  echo "🔑 GitHub CLI not authenticated — starting login..."
  gh auth login
fi

# Call the real clone.sh in WORKSPACE repo
/workspaces/WORKSPACE/clone.sh "$@"
