include Makefile.docker.mk

path := .
DOCKER_COMPOSE_FILE ?= -f docker-compose-common.yml -f docker-compose.swarm.local.yml

prod := 0
CONTAINER_SUFFIX :=

ifeq ($(prod), 1)
  DOCKER_COMPOSE_FILE = -f docker-compose-common.yml -f docker-compose-prod.swarm.extra.yml
endif



define Comment
	- Run `make help` to see all the available options.
	- Run `make lint` to run the linter.
	- Run `make lint-check` to check linter conformity.
	- Run `dep-lock` to lock the deps in 'requirements.txt' and 'requirements-dev.txt'.
	- Run `dep-sync` to sync current environment up to date with the locked deps.
endef

.PHONY: help
help: ## Show this help message.
	@echo "Available options:"
	@echo
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z_-]+:.*?## .*$$/ { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo
	@echo "To see the details of each command, run: make <command>"

.PHONY: venv
venv: ## Create and activate the virtual environment.
	@echo "Creating $(VENV_NAME)..."
	@echo "================"
	@$(PYTHON) -m venv $(VENV_NAME)
	@. $(VENV_NAME)/bin/activate
	@pip install --upgrade pip
	@pip install pip-tools
	@pip-sync

.PHONY: lint
lint: black ruff mypy	## Apply all the linters.

.PHONY: lint-check
lint-check:  ## Check whether the codebase satisfies the linter rules.
	@echo
	@echo "Checking linter rules..."
	@echo "========================"
	@echo
	@black --check $(path)
	@ruff $(path)
	@mypy $(path)

.PHONY: black
black: ## Apply black.
	@echo
	@echo "Applying black..."
	@echo "================="
	@echo
	@black --fast $(path)
	@echo

.PHONY: ruff
ruff: ## Apply ruff.
	@echo "Applying ruff..."
	@echo "================"
	@echo
	@ruff --fix $(path)

.PHONY: mypy
mypy: ## Apply mypy.
	@echo
	@echo "Applying mypy..."
	@echo "================="
	@echo
	@mypy $(path)

.PHONY: test
test: ## Run the tests against the current version of Python.
	pytest

.PHONY: dep-lock
dep-lock: ## Freeze deps in 'requirements.txt' file.
	@pip-compile requirements.in -o requirements.txt --no-emit-options --resolver=backtracking
	@pip-compile requirements-dev.in -o requirements-dev.txt --no-emit-options --resolver=backtracking

.PHONY: dep-sync
dep-sync: ## Sync venv installation with 'requirements.txt' file.
	@pip-sync

.PHONY: dep-update
dep-update: ## Update all the deps.
	@chmod +x ./scripts/update_deps.sh
	@./scripts/update_deps.sh

.PHONY: up
up: ## Run the app in a docker container.
	@echo "docker-compose $(DOCKER_COMPOSE_FILE) up --remove-orphans"
	@docker-compose $(DOCKER_COMPOSE_FILE) up --remove-orphans

.PHONY: rebuild
rebuild: ## Rebuild the Docker containers.
	@echo "docker-compose $(DOCKER_COMPOSE_FILE) up --build --remove-orphans"
	@docker-compose $(DOCKER_COMPOSE_FILE) up --build --remove-orphans

.PHONY: rebuild-scheduler
rebuild-chatbond: ## Rebuild the scheduler container from scratch.
	docker build -t chatbond -f compose/local/chatbond/Dockerfile . --no-cache

.PHONY: background
background: ## Run the app in a docker container.
	@docker-compose $(DOCKER_COMPOSE_FILE) up -d --remove-orphans

.PHONY: kill-container
down: ## Stop the running Docker containers.
	@docker-compose $(DOCKER_COMPOSE_FILE) down

.PHONY: logs
logs: ## View the logs of the Docker containers.
	@docker-compose $(DOCKER_COMPOSE_FILE) logs --follow

.PHONY: connect
connect: ## Connect to the running Docker container.
	@docker exec -it chatbond_api /bin/bash

.PHONY: destroy
down-volume: ## Stop the running Docker containers and remove volumes.
	@docker-compose $(DOCKER_COMPOSE_FILE) down -v

.PHONY: makemigrations
makemigrations: ## Create database migrations.
	docker exec chatbond_api python manage.py makemigrations

.PHONY: migrate
migrate: ## Apply database migrations.
	docker exec chatbond_api python manage.py migrate

make backup: ## Backup prod DB
	docker exec pgbackups3 sh backup.sh

make restore: ## Restore prod DB
	docker exec pgbackups3 sh restore.sh

make update: ## Update prod setup, backing up first
	make backup
	docker pull leonardmorpho/chatbond-api:0.1.0
	make down prod=1
	make up prod=1
