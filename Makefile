# =============================================================================
# OSCR Makefile
# =============================================================================
# Provides consistent commands for local development and CI.
# Run `make help` for available targets.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Find all shell scripts
SHELL_SCRIPTS := $(shell find . -name '*.sh' -not -path './node_modules/*' -not -path './.git/*')

# =============================================================================
# Help
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo "OSCR - Odd Self-Hosted CI Runtime"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# =============================================================================
# Quality Checks
# =============================================================================

.PHONY: lint
lint: ## Run shellcheck on all shell scripts
	@echo "==> Running shellcheck..."
	@shellcheck --shell=bash $(SHELL_SCRIPTS)
	@echo "==> Shellcheck passed"

.PHONY: lint-docker
lint-docker: ## Run shellcheck via Docker (no local install required)
	@echo "==> Running shellcheck via Docker..."
	@docker run --rm -v "$(PWD):/mnt" koalaman/shellcheck:stable $(SHELL_SCRIPTS)
	@echo "==> Shellcheck passed"

.PHONY: format-check
format-check: ## Check shell scripts for formatting issues
	@echo "==> Checking for CRLF line endings..."
	@if git ls-files --eol | grep -E 'w/crlf.*\.sh$$'; then \
		echo "ERROR: Shell scripts with CRLF detected"; \
		exit 1; \
	fi
	@echo "==> No CRLF issues found"

.PHONY: verify
verify: format-check lint ## Run all verification checks (used by CI and hooks)
	@echo "==> All checks passed"

# =============================================================================
# Docker Operations
# =============================================================================

.PHONY: build
build: ## Build all Docker images
	@echo "==> Building Docker images..."
	@cd orchestrator && ./select-provider.sh build github
	@cd orchestrator && ./select-provider.sh build azure-devops
	@echo "==> Build complete"

.PHONY: build-github
build-github: ## Build GitHub runner image
	@cd orchestrator && ./select-provider.sh build github

.PHONY: build-azure
build-azure: ## Build Azure DevOps agent image
	@cd orchestrator && ./select-provider.sh build azure-devops

# =============================================================================
# Development
# =============================================================================

.PHONY: start
start: ## Start the runner (requires .env configuration)
	@cd orchestrator && ./select-provider.sh start

.PHONY: stop
stop: ## Stop and unregister the runner
	@cd orchestrator && ./select-provider.sh stop

.PHONY: logs
logs: ## Follow runner logs
	@cd orchestrator && ./select-provider.sh logs

.PHONY: status
status: ## Show runner status
	@cd orchestrator && ./select-provider.sh status

.PHONY: health
health: ## Run health check
	@./scripts/healthcheck.sh

# =============================================================================
# CI Targets
# =============================================================================

.PHONY: ci
ci: verify build ## Run full CI pipeline (lint + build)
	@echo "==> CI pipeline complete"
