#!/usr/bin/env bash
set -e

# Clear Codespaces ephemeral token so gh auth works properly
unset GITHUB_TOKEN

# Call the real clone.sh in WORKSPACE repo
/workspaces/WORKSPACE/clone.sh "$@"
