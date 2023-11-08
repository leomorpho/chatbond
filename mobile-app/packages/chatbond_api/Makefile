# Makefile for a Flutter project

# Declare phony targets
.PHONY: help watch


# Show help message with available commands
help: ## Show this help message.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

# Run build_runner in watch mode for continuous code generation
watch: ## Run build_runner in watch mode
	flutter pub run build_runner watch --delete-conflicting-outputs