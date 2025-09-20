#!/usr/bin/env bash
set -e

# Prevent Codespaces ephemeral token from interfering
unset GITHUB_TOKEN

WORKSPACE_DIR="/workspace"
USER="rcook0"
BACKUP_REPO="git@github.com:${USER}/WORKSPACE-backup.git"
BACKUP_DIR="${WORKSPACE_DIR}/.backup"
STATE_DIR="${WORKSPACE_DIR}/data"

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

# --- Prepare Backup Repo ---
mkdir -p "$BACKUP_DIR"
if [ ! -d "$BACKUP_DIR/repo/.git" ]; then
  git clone "$BACKUP_REPO" "$BACKUP_DIR/repo"
fi
cd "$BACKUP_DIR/repo"

# --- Auto-Restore (if /workspace/data is missing) ---
if [ ! -d "$STATE_DIR" ] || [ -z "$(ls -A "$STATE_DIR" 2>/dev/null)" ]; then
  latest_backup=$(ls -t workspace-data-*.tar.gz 2>/dev/null | head -n1 || true)
  if [ -n "$latest_backup" ]; then
    echo "Restoring workspace data from $latest_backup"
    mkdir -p "$STATE_DIR"
    tar -xzf "$latest_backup" -C "$WORKSPACE_DIR"
  else
    echo "No backup found to restore."
  fi
fi

# --- Backup Non-Git State ---
timestamp=$(date +"%Y%m%d-%H%M%S")
archive="workspace-data-${timestamp}.tar.gz"

if [ -d "$STATE_DIR" ] && [ -n "$(ls -A "$STATE_DIR")" ]; then
  echo "Archiving $STATE_DIR -> $archive"
  tar -czf "$BACKUP_DIR/$archive" -C "$WORKSPACE_DIR" data
  cp "$BACKUP_DIR/$archive" .
  git add "$archive"
  git commit -m "Backup workspace data ${timestamp}" || true
fi

# --- Prune old backups, keep last 3 ---
echo "Pruning old backups, keeping last 3..."
ls -tp workspace-data-*.tar.gz | tail -n +4 | xargs -r git rm -f
git commit -m "Prune old backups (keep last 3)" || true

# Push changes upstream
git push origin main || true

echo "Repositories synced, workspace data restored/backed up (last 3 snapshots retained)."
exec "$@"
