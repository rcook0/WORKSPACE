#!/usr/bin/env bash
# Bulk clone/pull GitHub repos into /workspaces/WORKSPACE with logs & safety.
# Works for a user or org. Defaults to USER=rcook0.
set -Eeuo pipefail

### --- Config ---------------------------------------------------------------
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspaces/WORKSPACE}"
OWNER="${1:-${GITHUB_OWNER:-rcook0}}"         # user or org (e.g. rcook0 or my-org)
FILTER_REGEX="${FILTER_REGEX:-.*}"            # e.g. "^(svc-|lib-|WORKSPACE|tooling)"
INCLUDE_FORKS="${INCLUDE_FORKS:-false}"       # "true" to include forks
SKIP_ARCHIVED="${SKIP_ARCHIVED:-true}"        # "false" to include archived
SHALLOW="${SHALLOW:-true}"                    # shallow clone (depth 1)
SUBMODULES="${SUBMODULES:-false}"             # "true" to recurse
PARALLEL="${PARALLEL:-6}"                     # parallel jobs
LOG_DIR="${LOG_DIR:-${WORKSPACE_DIR}/logs}"
SYNC_LOG="${SYNC_LOG:-${LOG_DIR}/sync.log}"

# Make sure Codespaces' ephemeral token doesn't hijack auth
unset GITHUB_TOKEN || true

mkdir -p "${LOG_DIR}" "${WORKSPACE_DIR}"
run_time=$(date +"%Y-%m-%d %H:%M:%S")
echo -e "\n=== Sync run at ${run_time} (owner=${OWNER}, filter=${FILTER_REGEX}) ===" | tee -a "$SYNC_LOG"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing dependency: $1" | tee -a "$SYNC_LOG"
    exit 1
  }
}
need_cmd gh
need_cmd jq
need_cmd git
need_cmd xargs

# gh auth check
if ! gh auth status >/dev/null 2>&1; then
  echo "⚠️  GitHub CLI not authenticated. Run: gh auth login" | tee -a "$SYNC_LOG"
  exit 1
fi

cd "$WORKSPACE_DIR"

### --- Discover repos -------------------------------------------------------
echo "🔎 Listing repos for '${OWNER}'..." | tee -a "$SYNC_LOG"
# `gh repo list` works for users or orgs.
# We pull metadata so we can filter safely.
repos_json=$(gh repo list "$OWNER" --limit 1000 --json name,sshUrl,archived,isFork,visibility 2>/dev/null | jq -c '.[]')

# Filter list
filtered=$(echo "$repos_json" | jq -r --arg rx "$FILTER_REGEX" --argjson allowForks "${INCLUDE_FORKS}" --argjson skipArchived "${SKIP_ARCHIVED}" '
  select(.name|test($rx))
  | select(($allowForks) or (.isFork|not))
  | select((.archived|not) or ( $skipArchived|not ))
  | [.name, .sshUrl] | @tsv
')

if [[ -z "$filtered" ]]; then
  echo "ℹ️  No repositories matched filter '${FILTER_REGEX}' under '${OWNER}'." | tee -a "$SYNC_LOG"
  exit 0
fi

mapfile -t LINES <<< "$filtered"
echo "🧾 Repos to sync: ${#LINES[@]}" | tee -a "$SYNC_LOG"

### --- Functions ------------------------------------------------------------
clone_or_update() {
  local name="$1" ssh="$2"
  local path="${WORKSPACE_DIR}/${name}"

  if [[ ! -d "${path}/.git" ]]; then
    echo "  ➕ Cloning ${name}" | tee -a "$SYNC_LOG"
    local depth=()
    [[ "$SHALLOW" == "true" ]] && depth=(--depth 1)

    local submod=()
    [[ "$SUBMODULES" == "true" ]] && submod=(--recurse-submodules)

    # Faster/leaner clone: blob filtering reduces bandwidth
    if git clone --filter=blob:none "${depth[@]}" "${submod[@]}" "$ssh" "$path" >>"$SYNC_LOG" 2>&1; then
      echo "     ✅ clone ok: ${name}" | tee -a "$SYNC_LOG"
    else
      echo "     ❌ clone failed: ${name}" | tee -a "$SYNC_LOG"
      return 1
    fi
  else
    echo "  ⬆️  Updating ${name}" | tee -a "$SYNC_LOG"
    (
      cd "$path"
      # normalize origin URL to SSH (in case gh cloned via https before)
      git remote set-url origin "$ssh" || true
      git fetch --all -p >>"$SYNC_LOG" 2>&1 || true

      # detect unpushed commits
      # compute upstream; fallback to origin/HEAD where possible
      upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "origin/HEAD")
      ahead=$(git rev-list --count "${upstream}..HEAD" 2>/dev/null || echo 0)

      if ! git pull --ff-only >>"$SYNC_LOG" 2>&1; then
        echo "     ❌ non-fast-forward; manual rebase required in ${name}" | tee -a "$SYNC_LOG"
      fi

      if [[ "$ahead" != "0" ]]; then
        echo "     ⚠️ ${name} has ${ahead} local commit(s) not pushed" | tee -a "$SYNC_LOG"
        echo "${name}" >> "${LOG_DIR}/needs-push.list"
      fi
    )
  fi
}

export -f clone_or_update
export WORKSPACE_DIR SYNC_LOG SHALLOW SUBMODULES LOG_DIR

### --- Parallel sync --------------------------------------------------------
# shellcheck disable=SC2016
printf '%s\n' "${LINES[@]}" | xargs -r -n1 -P "${PARALLEL}" bash -lc '
  IFS=$'\''\t'\'' read -r name ssh <<< "$0"
  clone_or_update "$name" "$ssh"
'

### --- Summary --------------------------------------------------------------
if [[ -f "${LOG_DIR}/needs-push.list" ]]; then
  sort -u "${LOG_DIR}/needs-push.list" > "${LOG_DIR}/needs-push.list.tmp" && mv "${LOG_DIR}/needs-push.list.tmp" "${LOG_DIR}/needs-push.list"
  count=$(wc -l < "${LOG_DIR}/needs-push.list" || echo 0)
  echo -e "\n📌 Summary: ${count} repos have local commits not on origin:" | tee -a "$SYNC_LOG"
  sed 's/^/   - /' "${LOG_DIR}/needs-push.list" | tee -a "$SYNC_LOG"
else
  echo -e "\n📌 Summary: All repos are fast-forward with origin (no local-ahead repos detected)." | tee -a "$SYNC_LOG"
fi

echo "✅ Done." | tee -a "$SYNC_LOG"
