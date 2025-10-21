tee scripts/init.sh >/dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspaces/WORKSPACE}"
OWNER="${GITHUB_OWNER:-rcook0}"
mkdir -p "$WORKSPACE_DIR" /workspace/data
if [ -x "$WORKSPACE_DIR/scripts/clone.sh" ]; then
  "$WORKSPACE_DIR/scripts/clone.sh" "$OWNER" || true
elif command -v clone.sh >/dev/null 2>&1; then
  clone.sh "$OWNER" || true
else
  echo "[init] clone.sh not found; skipping bootstrap."
fi
exec bash -l
SH
chmod +x scripts/init.sh
