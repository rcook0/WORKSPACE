#!/usr/bin/env bash
# Snapshot/restore ./data/ to a backup repo, keeping last 3 snapshots.
set -Eeuo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspaces/WORKSPACE}"
STATE_DIR="${STATE_DIR:-${WORKSPACE_DIR}/data}"
BACKUP_REPO="${BACKUP_REPO:-git@github.com:rcook0/WORKSPACE-backup.git}"
BACKUP_DIR="${BACKUP_DIR:-${WORKSPACE_DIR}/.backup/repo}"
LOG_DIR="${LOG_DIR:-${WORKSPACE_DIR}/logs}"
SYNC_LOG="${SYNC_LOG:-${LOG_DIR}/backup.log}"

mkdir -p "$LOG_DIR" "$STATE_DIR" "$(dirname "$BACKUP_DIR")"
echo -e "\n=== Backup run at $(date +"%Y-%m-%d %H:%M:%S") ===" | tee -a "$SYNC_LOG"

# Clone backup repo if needed
if [[ ! -d "$BACKUP_DIR/.git" ]]; then
  echo "📂 Cloning backup repo into $BACKUP_DIR" | tee -a "$SYNC_LOG"
  git clone "$BACKUP_REPO" "$BACKUP_DIR" >>"$SYNC_LOG" 2>&1 || {
    echo "❌ Failed to clone backup repo" | tee -a "$SYNC_LOG"; exit 1;
  }
fi
#!/usr/bin/env bash
# Snapshot/restore ./data/ to a backup repo, keeping last 3 snapshots.
set -Eeuo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspaces/WORKSPACE}"
STATE_DIR="${STATE_DIR:-${WORKSPACE_DIR}/data}"
BACKUP_REPO="${BACKUP_REPO:-git@github.com:rcook0/WORKSPACE-backup.git}"
BACKUP_DIR="${BACKUP_DIR:-${WORKSPACE_DIR}/.backup/repo}"
LOG_DIR="${LOG_DIR:-${WORKSPACE_DIR}/logs}"
SYNC_LOG="${SYNC_LOG:-${LOG_DIR}/backup.log}"

mkdir -p "$LOG_DIR" "$STATE_DIR" "$(dirname "$BACKUP_DIR")"
echo -e "\n=== Backup run at $(date +"%Y-%m-%d %H:%M:%S") ===" | tee -a "$SYNC_LOG"

# Clone backup repo if needed
if [[ ! -d "$BACKUP_DIR/.git" ]]; then
  echo "📂 Cloning backup repo into $BACKUP_DIR" | tee -a "$SYNC_LOG"
  git clone "$BACKUP_REPO" "$BACKUP_DIR" >>"$SYNC_LOG" 2>&1 || {
    echo "❌ Failed to clone backup repo" | tee -a "$SYNC_LOG"; exit 1;
  }
fi

cd "$BACKUP_DIR"

# Restore if data missing
if [[ ! -d "$STATE_DIR" || -z "$(ls -A "$STATE_DIR" 2>/dev/null)" ]]; then
  latest=$(ls -t workspace-data-*.tar.gz 2>/dev/null | head -n1 || true)
  if [[ -n "$latest" ]]; then
    echo "♻️  Restoring from $latest" | tee -a "$SYNC_LOG"
    tar -xzf "$latest" -C "$WORKSPACE_DIR" >>"$SYNC_LOG" 2>&1 || true
  else
    echo "ℹ️  No backup found to restore." | tee -a "$SYNC_LOG"
  fi
fi

# Create new snapshot if there is content
if [[ -d "$STATE_DIR" && -n "$(ls -A "$STATE_DIR" 2>/dev/null)" ]]; then
  ts=$(date +"%Y%m%d-%H%M%S")
  archive="workspace-data-${ts}.tar.gz"
  echo "💾 Creating $archive" | tee -a "$SYNC_LOG"
  tar -czf "$archive" -C "$WORKSPACE_DIR" data
  git add "$archive"
  git commit -m "Backup workspace data ${ts}" || true

  # prune old (keep last 3)
  keep=$(ls -t workspace-data-*.tar.gz 2>/dev/null | head -n3 || true)
  remove=$(ls -t workspace-data-*.tar.gz 2>/dev/null | tail -n +4 || true)
  if [[ -n "$remove" ]]; then
    echo "🧹 Pruning old backups…" | tee -a "$SYNC_LOG"
    echo "$remove" | xargs -r git rm -f
    git commit -m "Prune old backups (keep last 3)" || true
  fi

  git push origin main || true
else
  echo "⚠️  No workspace data to back up." | tee -a "$SYNC_LOG"
fi

echo "✅ Backup complete." | tee -a "$SYNC_LOG"

cd "$BACKUP_DIR"

# Restore if data missing
if [[ ! -d "$STATE_DIR" || -z "$(ls -A "$STATE_DIR" 2>/dev/null)" ]]; then
  latest=$(ls -t workspace-data-*.tar.gz 2>/dev/null | head -n1 || true)
  if [[ -n "$latest" ]]; then
    echo "♻️  Restoring from $latest" | tee -a "$SYNC_LOG"
    tar -xzf "$latest" -C "$WORKSPACE_DIR" >>"$SYNC_LOG" 2>&1 || true
  else
    echo "ℹ️  No backup found to restore." | tee -a "$SYNC_LOG"
  fi
fi

# Create new snapshot if there is content
if [[ -d "$STATE_DIR" && -n "$(ls -A "$STATE_DIR" 2>/dev/null)" ]]; then
  ts=$(date +"%Y%m%d-%H%M%S")
  archive="workspace-data-${ts}.tar.gz"
  echo "💾 Creating $archive" | tee -a "$SYNC_LOG"
  tar -czf "$archive" -C "$WORKSPACE_DIR" data
  git add "$archive"
  git commit -m "Backup workspace data ${ts}" || true

  # prune old (keep last 3)
  keep=$(ls -t workspace-data-*.tar.gz 2>/dev/null | head -n3 || true)
  remove=$(ls -t workspace-data-*.tar.gz 2>/dev/null | tail -n +4 || true)
  if [[ -n "$remove" ]]; then
    echo "🧹 Pruning old backups…" | tee -a "$SYNC_LOG"
    echo "$remove" | xargs -r git rm -f
    git commit -m "Prune old backups (keep last 3)" || true
  fi

  git push origin main || true
else
  echo "⚠️  No workspace data to back up." | tee -a "$SYNC_LOG"
fi

echo "✅ Backup complete." | tee -a "$SYNC_LOG"
