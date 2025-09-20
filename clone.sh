#!/usr/bin/env bash
set -e

WORKSPACE_DIR="/workspace"
USER="rcook0"
BACKUP_REPO="git@github.com:${USER}/WORKSPACE-backup.git"
BACKUP_DIR="${WORKSPACE_DIR}/.backup"
STATE_DIR="${WORKSPACE_DIR}/data"   # persistent workspace data

# Ensure gh is authenticated
if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI not authenticated. Please run: gh auth login"
  exec "$@"
fi

cd "$WORKSPACE_DIR"

# --- Sync Repositories ---
echo "Syncing repositories for $USER..."
repos=$(gh repo list $USER --limit 200 --json nameWithOwner --jq '.[].nameWithOwner')

for repo in $repos; do
  name=$(basename "$repo")
  if [ ! -d "$name/.git" ]; then
    echo "Cloning $repo..."
    gh repo clone "$repo" "$name"
  else
    echo "Updating $repo..."
    (cd "$name" && git pull --ff-only || true)
  fi
done

# --- Backup Non-Git State ---
mkdir -p "$BACKUP_DIR"
timestamp=$(date +"%Y%m%d-%H%M%S")
archive="workspace-data-${timestamp}.tar.gz"

if [ -d "$STATE_DIR" ]; then
  echo "Archiving $STATE_DIR -> $archive"
  tar -czf "$BACKUP_DIR/$archive" -C "$WORKSPACE_DIR" data
fi

# Initialize backup repo clone if missing
if [ ! -d "$BACKUP_DIR/repo/.git" ]; then
  git clone "$BACKUP_REPO" "$BACKUP_DIR/repo"
fi

cd "$BACKUP_DIR/repo"
cp "$BACKUP_DIR/$archive" .
git add "$archive"
git commit -m "Backup workspace data ${timestamp}" || true
git push origin main || true

echo "Repositories synced and workspace data backed up."
exec "$@"
