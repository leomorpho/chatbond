# Makefile for a Flutter project

# Declare phony targets
.PHONY: help dev dev-tools stage prod test build watch

# Variables for common options
FLAVOR_OPTIONS = --flavor
TARGET_OPTIONS = --target lib
PORT ?= 6060

# Show help message with available commands
help: ## Show this help message.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

# Run the app in development mode
chrome:
	@echo "Usage: make chrome-<port_number>"
	@exit 1

chrome-%:
	trap 'kill 0' EXIT; \
	flutter run $(FLAVOR_OPTIONS) development $(TARGET_OPTIONS)/main_development.dart --web-port $* -d Chrome & \
	caffeinate -t 1000000 & \
	wait

dev:
	@echo "Usage: make chrome-<port_number>"
	@exit 1

dev-%:
	flutter run $(FLAVOR_OPTIONS) development $(TARGET_OPTIONS)/main_development.dart --web-port $* 

# dev: ## Run the app in development mode
# 	flutter run $(FLAVOR_OPTIONS) development $(TARGET_OPTIONS)/main_development.dart --web-port $(PORT)
# dev2: ## Run the app in development mode
# 	flutter run $(FLAVOR_OPTIONS) development $(TARGET_OPTIONS)/main_development.dart --web-port 6061

mac: ## Run the app for MacOS
	flutter run --target lib/main_development.dart --web-port 6060
	
# Run Dart DevTools
dev-tools: ## Run Dart DevTools
	dart devtools

# Run the app in staging mode
stage: ## Run the app in staging mode
	flutter run $(FLAVOR_OPTIONS) staging $(TARGET_OPTIONS)/main_staging.dart

# Run the app in production mode
prod: ## Run the app in production mode
	flutter run $(FLAVOR_OPTIONS) production $(TARGET_OPTIONS)/main_production.dart 

# Run build_runner in watch mode for continuous code generation
watch: ## Run build_runner in watch mode
	flutter pub run build_runner watch --delete-conflicting-outputs

book: ## Start the widgetbook
	flutter run -t widgetbook/main.dart