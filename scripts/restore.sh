#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables from .env if it exists
if [ -f .env ]; then
	set -a
	source .env
	set +a
fi

# Configuration
SITE_NAME=${SITE_NAME:-"localhost"}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"root"}
BACKUP_FILE=${1:-$BACKUP_FILE}

# Function to print colored messages
print_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Check if backup file is provided
if [ -z "$BACKUP_FILE" ]; then
	print_error "No backup file specified!"
	echo
	print_info "Usage: $0 <backup_file.sql.gz>"
	print_info "   or: make restore FILE=<backup_file.sql.gz>"
	echo
	print_info "Available backups:"
	if [ -d "./backups" ]; then
		find ./backups -name "*.sql.gz" -type f -exec ls -lh {} \;
	fi
	exit 1
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
	print_error "Backup file not found: $BACKUP_FILE"
	exit 1
fi

# Check if running inside container
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
	IS_CONTAINER=true
	BENCH_DIR="/home/frappe/bench/frappe-bench"
else
	IS_CONTAINER=false
fi

# Warning message
echo
print_warning "========================================="
print_warning "WARNING: DATABASE RESTORE"
print_warning "========================================="
print_warning "This will restore the database for site: ${SITE_NAME}"
print_warning "Current data will be OVERWRITTEN!"
print_warning "========================================="
echo
print_info "Backup file: $BACKUP_FILE"
echo

# Confirmation prompt
read -p "$(echo -e ${YELLOW}Do you want to continue? [y/N]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	print_info "Restore cancelled"
	exit 0
fi

if [ "$IS_CONTAINER" = true ]; then
	# Running inside container
	if ! command -v bench &> /dev/null; then
		print_error "bench command not found!"
		exit 1
	fi

	cd ${BENCH_DIR}

	# Check if site exists
	if ! bench --site ${SITE_NAME} list-apps &> /dev/null; then
		print_error "Site '${SITE_NAME}' does not exist!"
		print_info "Create the site first with: make dev-setup"
		exit 1
	fi

	print_info "Restoring database from backup..."
	bench --site ${SITE_NAME} restore \
		--mariadb-root-password "${MYSQL_ROOT_PASSWORD}" \
		"$BACKUP_FILE"

	print_success "Database restored successfully!"

else
	# Running outside container
	print_info "Running restore inside container..."

	# Check if container is running
	if ! docker compose ps dev | grep -q "Up"; then
		print_error "Dev container is not running!"
		print_info "Start it with: make up"
		exit 1
	fi

	# Get absolute path of backup file
	BACKUP_FILE_ABS=$(realpath "$BACKUP_FILE")
	BACKUP_FILE_NAME=$(basename "$BACKUP_FILE")

	# Copy backup file to container
	print_info "Copying backup file to container..."
	CONTAINER_TEMP="/tmp/${BACKUP_FILE_NAME}"
	docker compose cp "$BACKUP_FILE_ABS" "dev:${CONTAINER_TEMP}"

	# Restore inside container
	print_info "Restoring database from backup..."
	docker compose exec dev bash -c "cd frappe-bench && bench --site ${SITE_NAME} restore --mariadb-root-password ${MYSQL_ROOT_PASSWORD} ${CONTAINER_TEMP}"

	# Clean up
	print_info "Cleaning up temporary files..."
	docker compose exec dev rm -f "${CONTAINER_TEMP}"

	print_success "Database restored successfully!"
fi

# Final summary
echo
print_success "========================================="
print_success "Restore completed successfully!"
print_success "========================================="
echo
print_info "Site Name: ${SITE_NAME}"
print_info "Restored from: $BACKUP_FILE"
echo
print_info "You may need to:"
print_info "1. Clear cache: make clear-cache"
print_info "2. Restart services: make restart"
echo
