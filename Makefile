.PHONY: help up down restart logs shell bench db-console redis-console test clean up-rebuild down-volumes status ps backup restore dev-setup migrate install-app

# Default target - show help
.DEFAULT_GOAL := help

# Docker compose command with environment file
COMPOSE := docker compose -f docker-compose.yml --env-file=./.env
CONTAINER := dev

##@ General

help: ## Display this help message
	@echo "Available commands:"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Docker Operations

up: ## Start all containers in detached mode
	$(COMPOSE) up -d

up-rebuild: ## Rebuild and start containers (clean start)
	$(COMPOSE) up -d --build --force-recreate --remove-orphans

down: ## Stop all containers
	$(COMPOSE) down

down-volumes: ## Stop containers and remove volumes (WARNING: deletes all data!)
	@echo "⚠️  WARNING: This will delete ALL data including database!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE) down --volumes; \
	else \
		echo "Cancelled."; \
	fi

restart: ## Restart all containers
	$(COMPOSE) restart

stop: ## Stop containers without removing them
	$(COMPOSE) stop

start: ## Start previously stopped containers
	$(COMPOSE) start

ps: ## List all containers and their status
	$(COMPOSE) ps -a

status: ps ## Alias for 'ps' - show container status

##@ Logs & Monitoring

logs: ## Tail logs from all containers
	$(COMPOSE) logs -f

logs-dev: ## Tail logs from dev container only
	$(COMPOSE) logs -f $(CONTAINER)

logs-db: ## Tail logs from database container
	$(COMPOSE) logs -f mariadb

logs-redis: ## Tail logs from Redis containers
	$(COMPOSE) logs -f redis-queue redis-cache redis-socketio

##@ Container Access

shell: ## Open bash shell in dev container
	$(COMPOSE) exec $(CONTAINER) /bin/bash

bench: ## Access bench CLI (usage: make bench CMD="bench --help")
	@if [ -z "$(CMD)" ]; then \
		$(COMPOSE) exec $(CONTAINER) bench --help; \
	else \
		$(COMPOSE) exec $(CONTAINER) $(CMD); \
	fi

db-console: ## Open MariaDB console
	$(COMPOSE) exec mariadb mysql -uroot -proot erpnext

db-console-user: ## Open MariaDB console as erpnext user
	$(COMPOSE) exec mariadb mysql -uerpnext -perpnext erpnext

redis-console: ## Open Redis CLI for queue
	$(COMPOSE) exec redis-queue redis-cli

##@ Development

dev-setup: ## Run initial development setup
	@if [ -f "./scripts/dev-setup.sh" ]; then \
		./scripts/dev-setup.sh; \
	else \
		./setup.sh; \
	fi

migrate: ## Run database migrations
	$(COMPOSE) exec $(CONTAINER) bench --site localhost migrate

clear-cache: ## Clear all caches
	$(COMPOSE) exec $(CONTAINER) bench --site localhost clear-cache

rebuild-search: ## Rebuild search index
	$(COMPOSE) exec $(CONTAINER) bench --site localhost build-search-index

install-app: ## Install custom app (usage: make install-app APP=app_name)
	@if [ -z "$(APP)" ]; then \
		echo "Error: APP variable required. Usage: make install-app APP=app_name"; \
		exit 1; \
	fi
	$(COMPOSE) exec $(CONTAINER) bench --site localhost install-app $(APP)

##@ Testing

test: ## Run all tests
	$(COMPOSE) exec $(CONTAINER) bench --site localhost run-tests

test-app: ## Run tests for specific app (usage: make test-app APP=invenio_property_management)
	@if [ -z "$(APP)" ]; then \
		echo "Error: APP variable required. Usage: make test-app APP=app_name"; \
		exit 1; \
	fi
	$(COMPOSE) exec $(CONTAINER) bench --site localhost run-tests --app $(APP)

##@ Backup & Restore

backup: ## Backup site (usage: make backup SITE=localhost)
	@if [ -f "./scripts/backup.sh" ]; then \
		./scripts/backup.sh $(SITE); \
	else \
		$(COMPOSE) exec $(CONTAINER) bench --site $${SITE:-localhost} backup; \
	fi

restore: ## Restore site from backup (usage: make restore FILE=backup.sql.gz)
	@if [ -f "./scripts/restore.sh" ]; then \
		./scripts/restore.sh $(FILE); \
	else \
		echo "Error: Use scripts/restore.sh for restoring backups"; \
		exit 1; \
	fi

##@ Cleanup

clean: ## Remove stopped containers, unused networks, and dangling images
	docker system prune -f

clean-all: ## Deep clean - remove everything (containers, volumes, images)
	@echo "⚠️  WARNING: This will remove ALL Docker containers, volumes, and images!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE) down -v --rmi all; \
		docker system prune -af --volumes; \
	else \
		echo "Cancelled."; \
	fi

clean-cache: ## Remove cached Python files
	find frappe -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find frappe -type f -name "*.pyc" -delete 2>/dev/null || true

##@ Information

info: ## Show environment information
	@echo "=== Docker Compose Version ==="
	@docker compose version
	@echo ""
	@echo "=== Container Status ==="
	@$(COMPOSE) ps
	@echo ""
	@echo "=== Disk Usage ==="
	@du -sh frappe 2>/dev/null || echo "frappe directory not found"
	@echo ""
	@echo "=== Docker Volumes ==="
	@docker volume ls | grep "$$(basename $$(pwd))" || echo "No volumes found"
