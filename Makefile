# Makefile for lofi-stream-dlive
# Dev server deployment and cleanup

# Configuration
SSH_KEY := ~/api-secrets/hetzner-server/id_ed25519
DEV_HOST := 5.78.42.22
DEV_USER := lofidev
DEV_DIR := /home/lofidev/streams
REPO_NAME := lofi-stream-dlive

SSH_CMD := ssh -i $(SSH_KEY) $(DEV_USER)@$(DEV_HOST)
SSH_ROOT := ssh -i $(SSH_KEY) root@$(DEV_HOST)

.PHONY: help deploy-dev cleanup-dev dev-status dev-logs dev-reset

help:
	@echo "Dev Server Targets:"
	@echo "  make deploy-dev   - Deploy this repo to dev server"
	@echo "  make cleanup-dev  - Remove this repo from dev server"
	@echo "  make dev-status   - Show what's deployed on dev server"
	@echo "  make dev-logs     - Show reset log from dev server"
	@echo "  make dev-reset    - Run full dev server reset (as root)"

deploy-dev:
	@echo "Deploying $(REPO_NAME) to dev server..."
	$(SSH_CMD) '\
		set -e; \
		DEPLOY_PATH=$(DEV_DIR)/$(REPO_NAME); \
		mkdir -p $$DEPLOY_PATH; \
		cd $$DEPLOY_PATH; \
		if [ -d ".git" ]; then \
			echo "Updating existing repo..."; \
			git fetch origin; \
			git reset --hard origin/main; \
		else \
			echo "Cloning fresh..."; \
			cd $(DEV_DIR); \
			rm -rf $(REPO_NAME); \
			git clone --depth 1 https://github.com/ldraney/$(REPO_NAME).git; \
		fi; \
		echo "Deploy complete!"; \
		ls -la $$DEPLOY_PATH'

cleanup-dev:
	@echo "Cleaning up $(REPO_NAME) from dev server..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(SSH_CMD) '\
		set -e; \
		echo "Stopping any processes..."; \
		pkill -f "$(REPO_NAME)" || true; \
		echo "Removing deployment..."; \
		rm -rf $(DEV_DIR)/$(REPO_NAME); \
		echo "Cleanup complete!"; \
		echo "Remaining in $(DEV_DIR):"; \
		ls -la $(DEV_DIR) || echo "(empty)"'

dev-status:
	@echo "Dev server status:"
	$(SSH_CMD) 'ls -la $(DEV_DIR)'

dev-logs:
	@echo "Dev reset logs:"
	$(SSH_ROOT) 'tail -50 /var/log/dev-reset.log 2>/dev/null || echo "No logs yet"'

dev-reset:
	@echo "Running full dev server reset..."
	@read -p "This will kill all lofidev processes and clean home dir. Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(SSH_ROOT) '/opt/scripts/reset-dev.sh'
