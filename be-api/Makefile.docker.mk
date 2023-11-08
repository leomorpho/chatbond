MANAGER_IP ?= 0.0.0.0
COMPOSE_FILE_DOCKER ?= docker-compose-common.yml
STACK_NAME ?= chatbond-swarm
API_REPLICAS ?= 1
WORKER_REPLICAS ?= 1

# Check for prod flag
ifeq ($(PROD), 1)
	DEPLOY_STACK_NAME = $(STACK_NAME)
	COMPOSE_FILES = -c $(COMPOSE_FILE_DOCKER)
	STACK_NAME_SUFFIX=
else
	DEPLOY_STACK_NAME = chatbond-test
	COMPOSE_FILES = -c docker-compose-common.yml -c docker-compose.swarm.local.yml
	STACK_NAME_SUFFIX=-test
endif

init-swarm: ## Initialize swarm: `make init-swarm MANAGER_IP=64.227.103.196`
	docker swarm init --advertise-addr $(MANAGER_IP)

up-swarm-setup: ## Build the swarm setup with docker-compose for sanity tests
	@docker-compose -f docker-compose-common.yml -f docker-compose.swarm.local.yml up --remove-orphans

rebuild-swarm-setup: ## Rebuild the swarm setup with docker-compose for sanity tests
	@docker-compose -f docker-compose-common.yml -f docker-compose.swarm.local.yml up --build --remove-orphans
.PHONY: destroy
swarm-setup-down-volume: ## Stop the running Docker containers and remove volumes.
	@docker-compose -f docker-compose-common.yml -f docker-compose.swarm.local.yml down -v

leave-swarm: ## Leave the swarm
	docker swarm leave --force

deploy-stack: ## Deploy a docker-compose stack: `make deploy-stack PROD=1` for prod or `make deploy-stack` for local/dev
	docker stack deploy $(COMPOSE_FILES) --with-registry-auth $(DEPLOY_STACK_NAME)

remove-stack: ## Remove the deployed stack: `make remove-stack PROD=1` for prod or `make remove-stack` for local/dev
	docker stack rm $(DEPLOY_STACK_NAME)

scale-api: ## Scale the app service: `make scale-api API_REPLICAS=3`
	docker service scale $(DEPLOY_STACK_NAME)_chatbond_api=$(API_REPLICAS)

scale-worker: ## Scale workers: `make scale-worker WORKER_REPLICAS=2`
	docker service scale $(DEPLOY_STACK_NAME)_task_worker=$(WORKER_REPLICAS)

update-api-image: ## Update API service image: `make update-api-image NEW_IMAGE=repository:tag`
	docker service update --image $(NEW_IMAGE) $(DEPLOY_STACK_NAME)_chatbond_api

force-update-services: ## Force update services: `make force-update-services`
	@echo "Forcing update for services in $(DEPLOY_STACK_NAME)"
	@docker service ls --filter name=$(DEPLOY_STACK_NAME) --format "{{.Name}}" | xargs -I {} docker service update --force {}

exec-it: ## Exec into a service: make exec-service SERVICE=chatbond_api prod=1
	@service_name=$(STACK_NAME)$(STACK_NAME_SUFFIX)_$(SERVICE); \
	container_id=$(shell docker service ps --format "{{.ID}} {{.CurrentState}} {{.Name}}" $$service_name | grep Running | awk '{print $$1}' | head -n 1); \
	if [ -z "$$container_id" ]; then \
		echo "No running containers found for service: $(SERVICE)"; \
	else \
		real_container_id=$(shell docker inspect --format '{{.Status.ContainerStatus.ContainerID}}' $$container_id); \
		docker exec -it $$real_container_id /bin/sh; \
	fi

log-api: ## Get logs from API services
	docker service logs -f $(DEPLOY_STACK_NAME)_chatbond_api

log-worker: ## Get logs from worker services
	docker service logs -f $(DEPLOY_STACK_NAME)_task_worker

log-sched: ## Get logs from scheduler services
	docker service logs -f $(DEPLOY_STACK_NAME)_scheduler

log-db: ## Get logs from scheduler services
	docker service logs -f $(DEPLOY_STACK_NAME)_postgres

.PHONY: run-dry
run-dry:
	@if command -v dry > /dev/null; then \
		echo "dry binary exists. Running..."; \
		dry; \
	else \
		echo "dry binary not found. Installing..."; \
		curl -sSf https://moncho.github.io/dry/dryup.sh | sudo sh; \
		sudo chmod 755 /usr/local/bin/dry; \
		echo "Installation complete. Running dry..."; \
		dry; \
	fi

.PHONY: init-swarm leave-swarm deploy-stack remove-stack scale-api scale-worker
