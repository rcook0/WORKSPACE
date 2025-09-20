.PHONY: setup update build test up down

setup:
	# Clone all repos into WORKSPACE (skip if already present)
	gh repo list <your-username> --limit 200 --json nameWithOwner \
		--jq '.[].nameWithOwner' | while read repo; do \
			gh repo clone $$repo || true; \
		done

update:
	git submodule update --init --recursive --remote

build:
	docker-compose build

test:
	for d in */ ; do \
		( cd $$d && make test || true ); \
	done

up:
	docker-compose up -d

down:
	docker-compose down
