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
