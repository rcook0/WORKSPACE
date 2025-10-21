#!/usr/bin/env bash
set -euo pipefail
mkdir -p /workspaces/WORKSPACE /workspace/data
if [ -x "/workspaces/WORKSPACE/scripts/clone.sh" ]; then
  /workspaces/WORKSPACE/scripts/clone.sh rcook0 || true
elif command -v clone.sh >/dev/null 2>&1; then
  clone.sh rcook0 || true
else
  echo "[init] clone.sh not found; skipping bootstrap."
fi
exec bash -l
