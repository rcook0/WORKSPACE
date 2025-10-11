# WORKSPACE Dev Stack

Source of truth for:
- Docker images: `ghcr.io/rcook0/workspace/{dev,runtime}`
- Reusable CI: `.github/workflows/reusable-ci.yml`
- Linters & pre-commit configs
- Scripts: `wsync.sh`, `wbackup.sh`
- (Optional) Bazel bits under `build-commons/`

## Quick start
1. Push to `main` to publish images.
2. In any repo, drop `templates/devcontainer.json` into `.devcontainer/devcontainer.json`.
3. Use reusable CI:
```yaml
name: ci
on: [push, pull_request]
jobs:
  use-reusable:
    uses: rcook0/WORKSPACE/.github/workflows/reusable-ci.yml@main
```
