REG := ghcr.io/rcook0/workspace
PLAT := linux/amd64,linux/arm64

.PHONY: dev runtime images
dev:
	docker buildx build --platform=$(PLAT) -t $(REG)/dev:latest --push docker/dev
runtime:
	docker buildx build --platform=$(PLAT) -t $(REG)/runtime:latest --push docker/runtime
images: dev runtime
