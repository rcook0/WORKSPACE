# Workspace Overview

This repository acts as the **meta-workspace** for all projects owned by `rcook0`.

## Design
- **dev-stack**: Base Docker image with compilers, runtimes, and tooling.
- **WORKSPACE**: Orchestration layer that:
  - Clones and updates all GitHub repos.
  - Runs inside the `dev-stack` image.
  - Provides persistent storage via Docker volumes.
  - Backs up non-git state (`/workspace/data`) into `WORKSPACE-backup`.

## Lifecycle
1. Codespace starts using the `dev-stack` image.
2. `clone.sh` runs automatically:
   - Unsets ephemeral `GITHUB_TOKEN`.
   - Ensures `gh auth login` is active.
   - Clones/updates all `rcook0/*` repositories.
   - Archives `/workspace/data` and pushes to `WORKSPACE-backup`.
3. Developer continues work inside a consistent environment.

## Recovery
- If a Codespace expires (30-day retention), a new one can be rebuilt by:
  ```bash
  gh repo clone rcook0/WORKSPACE-backup
  tar -xzf workspace-data-<timestamp>.tar.gz -C /workspace
