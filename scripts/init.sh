#!/usr/bin/env bash
set -euo pipefail

# Optional: create workspace dirs if missing
mkdir -p /workspaces/WORKSPACE /workspace/data

# If clone.sh exists in the bind mount, run it once; otherwise no-op.
if [ -x "/workspaces/WORKSPACE/scripts/clone.sh" ]; then
  /workspaces/WORKSPACE/scripts/clone.sh rcook0 || true
elif command -v clone.sh >/dev/null 2>&1; then
  clone.sh rcook0 || true
else
  echo "[init] clone.sh not found; skipping bootstrap."
fi

# Hand control to a shell
exec bash -l
