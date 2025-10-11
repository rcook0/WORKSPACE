#!/usr/bin/env bash
set -euo pipefail
SRC="${1:-$PWD}"
DEST="${2:?Usage: ./wsync.sh <src_dir> <user@host:/path> [MODE=push|pull] [--dry-run]}"
MODE="${MODE:-push}"  # push | pull
EXCLUDES_FILE="${EXCLUDES_FILE:-$SRC/.syncignore}"
RSYNC_OPTS="-az --delete --partial --mkpath"
[ -f "$EXCLUDES_FILE" ] && RSYNC_OPTS="$RSYNC_OPTS --exclude-from=$EXCLUDES_FILE"
case "$MODE" in
  push) rsync $RSYNC_OPTS --exclude '.git' "$SRC"/ "$DEST"/ "${@:3}";;
  pull) rsync $RSYNC_OPTS --exclude '.git' "$DEST"/ "$SRC"/ "${@:3}";;
  *) echo "MODE must be push or pull"; exit 2;;
esac
