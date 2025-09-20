#!/usr/bin/env bash
set -e

# Prevent Codespaces ephemeral token from interfering
unset GITHUB_TOKEN

WORKSPACE_DIR="/workspaces/WORKSPACE"
USER="rcook0"
BACKUP_REPO="git@github.com:${USER}/WORKSPACE-backup.git"
BACKUP_DIR="${WORKSPACE_DIR}/.backup"
STATE_DIR="${WORKSPACE_DIR}/data"
LOG_DIR="${WORKSPACE_DIR}/logs"
SYNC_LOG="${LOG_DIR}/sync.log"

mkdir -p "$LOG_DIR"

# Add a header for this run
run_time=$(date +"%Y-%m-%d %H:%M:%S")
echo -e "\n=== Sync run at $run_time ===" | tee -a "$SYNC_LOG"

# Ensure gh is authenticated
if ! gh auth status >/dev/null 2>&1; then
  echo "⚠️  GitHub CLI not authenticated. Please run: gh auth login" | tee -a "$SYNC_LOG"
  exec "$@"
fi

cd "$WORKSPACE_DIR"

# --- Sync Repositories ---
echo "🔄 Syncing repositories for $USER..." | tee -a "$SYNC_LOG"
repos=$(gh repo list $USER --limit 200 --json nameWithOwner --jq '.[].nameWithOwner')

for repo in $repos; do
  name=$(basename "$repo")
  if [ ! -d "$name/.git" ]; then
    echo "  ➕ Cloning $repo" | tee -a "$SYNC_LOG"
    gh repo clone "$repo" "$name"
  else
    echo "  ⬆️  Updating $repo" | tee -a "$SYNC_LOG"
    (cd "$name" && git pull --ff-only || true)
  fi
done

# --- Prepare Backup Repo ---
mkdir -p "$BACKUP_DIR"
if [ ! -d "$BACKUP_DIR/repo/.git" ]; then
  echo "📂 Cloning backup repo..." | tee -a "$SYNC_LOG"
  git clone "$BACKUP_REPO" "$BACKUP_DIR/repo"
fi
cd "$BACKUP_DIR/repo"

# --- Auto-Restore (if /workspace/data is missing) ---
if [ ! -d "$STATE_DIR" ] || [ -z "$(ls -A "$STATE_DIR" 2>/dev/null)" ]; then
  latest_backup=$(ls -t workspace-data-*.tar.gz 2>/dev/null | head -n1 || true)
  if [ -n "$latest_backup" ]; then
    echo "♻️  Restoring workspace data from $latest_backup" | tee -a "$SYNC_LOG"
    mkdir -p "$STATE_DIR"
    tar -xzf "$latest_backup" -C "$WORKSPACE_DIR"
  else
    echo "ℹ️  No backup found to restore." | tee -a "$SYNC_LOG"
  fi
else
  echo "✅ Workspace data already present, no restore needed." | tee -a "$SYNC_LOG"
fi

# --- Backup Non-Git State ---
timestamp=$(date +"%Y%m%d-%H%M%S")
archive="workspace-data-${timestamp}.tar.gz"

if [ -d "$STATE_DIR" ] && [ -n "$(ls -A "$STATE_DIR")" ]; then
  echo "💾 Creating new backup: $archive" | tee -a "$SYNC_LOG"
  tar -czf "$BACKUP_DIR/$archive" -C "$WORKSPACE_DIR" data
  cp "$BACKUP_DIR/$archive" .
  git add "$archive"
  git commit -m "Backup workspace data ${timestamp}" || true
else
  echo "⚠️  No workspace data to back up." | tee -a "$SYNC_LOG"
fi

# --- Prune old backups, keep last 3 ---
echo "🧹 Pruning old backups (keep last 3)..." | tee -a "$SYNC_LOG"
keep=$(ls -t workspace-data-*.tar.gz 2>/dev/null | head -n3 || true)
remove=$(ls -t workspace-data-*.tar.gz 2>/dev/null | tail -n +4 || true)

if [ -n "$remove" ]; then
  echo "   Removing:" | tee -a "$SYNC_LOG"
  echo "$remove" | sed 's/^/     - /' | tee -a "$SYNC_LOG"
  echo "$remove" | xargs -r git rm -f
  git commit -m "Prune old backups (keep last 3)" || true
else
  echo "   Nothing to prune." | tee -a "$SYNC_LOG"
fi

echo "   Keeping:" | tee -a "$SYNC_LOG"
echo "$keep" | sed 's/^/     - /' | tee -a "$SYNC_LOG"

# Push changes upstream
git push origin main || true

echo "✅ Repositories synced, workspace data restored/backed up (last 3 snapshots retained)." | tee -a "$SYNC_LOG"
exec "$@"
