#!/usr/bin/env bash
set -euo pipefail
SRC="${1:-$HOME/Workspace}"
DEST="${2:?Usage: ./wbackup.sh <src> <dest_dir>}"
TS=$(date +"%Y-%m-%d_%H%M%S")
TARGET="$DEST/$TS"; LATEST="$DEST/latest"
OPTS="-aH --delete --numeric-ids --partial --mkpath"
EXC=(--exclude ".git" --exclude "bazel-*" --exclude "node_modules" --exclude ".venv" --exclude ".cache")
[ -d "$LATEST" ] && OPTS="$OPTS --link-dest=$LATEST"
rsync $OPTS "${EXC[@]}" "$SRC"/ "$TARGET"/
rm -f "$LATEST"; ln -s "$TARGET" "$LATEST"
echo "Snapshot -> $TARGET"
