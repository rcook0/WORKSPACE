# WORKSPACE

Meta-repository that orchestrates all development repos using the **dev-stack** base image.

## Features
- Inherits from `dev-stack:latest` Docker image
- Persistent storage via `workspace_data` volume
- Unified Makefile for setup, build, and test
- VSCode multi-root workspace config

## Quickstart
```bash
make build     # build dev-stack image if not done
make setup     # clone all repos here
make up        # start container
docker exec -it workspace-dev bash


Repo Sync and Backups
Wrapper Command: sync

A helper script ~/sync.sh is installed inside Codespaces. It ensures GitHub CLI is authenticated, unsets the ephemeral Codespaces token, and then calls the main clone.sh script.

Usage:

sync          # run sync, show last 20 log lines
sync -a       # run sync, show full log
sync -c       # clear sync.log, then run sync
sync -c -a    # clear sync.log, run sync, show full log


Logs are stored under:

/workspaces/WORKSPACE/logs/sync.log (manual runs)

/workspaces/WORKSPACE/logs/cron-sync.log (cron runs, twice daily)

What Sync Does

Clones/updates all repos under github.com/rcook0

Restores /workspaces/WORKSPACE/data from the latest backup if missing

Backs up /workspaces/WORKSPACE/data into WORKSPACE-backup

Prunes old backups, keeping the last 3 snapshots

Logs all actions with timestamps and repo lists

GitHub Authentication

First time in a new Codespace:

unset GITHUB_TOKEN
gh auth login -h github.com -p ssh -w -y


The sync wrapper handles this automatically if you’re not logged in.

Cron Job

Inside the container, cron runs clone.sh automatically every 12 hours (00:00 and 12:00 UTC). This ensures backups even if you don’t restart your Codespace.

Recovery

If a Codespace expires (30-day inactivity), you can rebuild:

gh repo clone rcook0/WORKSPACE-backup
cd WORKSPACE-backup
tar -xzf workspace-data-<timestamp>.tar.gz -C /workspaces/WORKSPACE


Then run:

sync


to repopulate repos and continue working.
