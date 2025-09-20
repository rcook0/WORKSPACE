.PHONY: setup update build up down

build:
	docker-compose build

up:
	docker-compose up -d

down:
    docker-compose down

setup:
    # Run initial repo sync inside container
	docker exec -it workspace-dev /usr/local/bin/clone.sh bash

update:
    docker exec -it workspace-dev git submodule update --init --recursive --remote
