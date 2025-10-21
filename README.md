# WORKSPACE (baked-in dev stack)

Mono-root for your local/dev environment with Dockerfiles **in-repo**.

## What you get
- `docker/dev/Dockerfile` — full toolchain (Python venv, TA-Lib, data libs, EDA tooling)
- `docker/runtime/Dockerfile` — lean runtime (copies venv)
- `docker-compose.yml` — builds `dev` locally; mounts repo
- `.devcontainer/devcontainer.json` — uses Compose for Codespaces/Dev Containers
- `scripts/init.sh` — optional bootstrap (`clone.sh` if present), then shell

## Usage
```bash
# local
docker compose up -d --build
docker compose exec dev bash

# Codespaces / Dev Containers
# open repo -> Rebuild container
```

## Next steps
- Add your `scripts/clone.sh` or remove that call from `scripts/init.sh`.
- Commit and push; optional: wire a GH Action to publish images (swap compose `build:` to `image:`).
