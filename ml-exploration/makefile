path := .

define Comment
	- Run `make help` to see all the available options.
	- Run `make lint` to run the linter.
	- Run `make lint-check` to check linter conformity.
	- Run `dep-lock` to lock the deps in 'requirements.txt' and 'requirements-dev.txt'.
	- Run `dep-sync` to sync current environment up to date with the locked deps.
endef

# Set the python interpreter
PYTHON = python3.11

# Set the name of your virtual environment
VENV_NAME = .venv

.PHONY: venv
venv:
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


.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'


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

.PHONY: up
up: ## Run the app in a docker container.
	@docker compose up --remove-orphans

.PHONY: background
background: ## Run the app in a docker container.
	@docker compose up -d --remove-orphans

.PHONY: rebuild
rebuild:
	@docker-compose up --build --remove-orphans

.PHONY: kill-container
down: ## Stop the running docker container.
	@docker compose down

.PHONY: logs
logs:
	@docker-compose logs --follow

.PHONE: connect
connect:
	@docker exec -it chatbond_ml /bin/bash

.PHONY: destroy
down-volume:
	@docker-compose down -v