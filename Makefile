REG := ghcr.io/rcook0/workspace
PLAT := linux/amd64,linux/arm64

.PHONY: dev runtime images up down sh
dev:
	docker build -t workspace-dev:local docker/dev
runtime:
	docker build -t workspace-runtime:local docker/runtime
images: dev runtime

up:
	docker compose up -d --build
down:
	docker compose down

sh:
	docker compose exec dev bash
