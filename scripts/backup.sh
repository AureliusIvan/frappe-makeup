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

# Configuration with defaults
SITE_NAME=${1:-${SITE_NAME:-"localhost"}}
BACKUP_DIR=${BACKUP_DIR:-"./backups"}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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

# Check if running inside container
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
	IS_CONTAINER=true
	BENCH_DIR="/home/frappe/bench/frappe-bench"
else
	IS_CONTAINER=false
	BENCH_DIR="./frappe/frappe-bench"
fi

print_info "Starting backup for site: ${SITE_NAME}"
print_info "Backup directory: ${BACKUP_DIR}"
echo

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

if [ "$IS_CONTAINER" = true ]; then
	# Running inside container - use bench directly
	if ! command -v bench &> /dev/null; then
		print_error "bench command not found!"
		exit 1
	fi

	# Navigate to bench directory
	cd ${BENCH_DIR}

	# Check if site exists
	if ! bench --site ${SITE_NAME} list-apps &> /dev/null; then
		print_error "Site '${SITE_NAME}' does not exist!"
		exit 1
	fi

	# Perform backup
	print_info "Creating backup (this may take a while)..."
	bench --site ${SITE_NAME} backup --with-files

	# Find the backup files
	BACKUP_PATH="${BENCH_DIR}/sites/${SITE_NAME}/private/backups"

	print_success "Backup created successfully!"
	print_info "Backup location: ${BACKUP_PATH}"

	# List recent backups
	echo
	print_info "Recent backups:"
	ls -lht "${BACKUP_PATH}" | head -10

else
	# Running outside container - use docker exec
	print_info "Running backup inside container..."

	# Check if container is running
	if ! docker compose ps dev | grep -q "Up"; then
		print_error "Dev container is not running!"
		print_info "Start it with: make up"
		exit 1
	fi

	# Execute backup inside container
	docker compose exec dev bash -c "cd frappe-bench && bench --site ${SITE_NAME} backup --with-files"

	print_success "Backup created successfully!"

	# Copy backups from container to host
	print_info "Copying backups from container to host..."

	CONTAINER_BACKUP_PATH="/home/frappe/bench/frappe-bench/sites/${SITE_NAME}/private/backups"
	HOST_BACKUP_PATH="${BACKUP_DIR}/${SITE_NAME}_${TIMESTAMP}"

	mkdir -p "${HOST_BACKUP_PATH}"

	# Get the latest backup files
	DATABASE_FILE=$(docker compose exec dev bash -c "ls -t ${CONTAINER_BACKUP_PATH}/*-*-*-*.sql.gz 2>/dev/null | head -1" | tr -d '\r')
	FILES_FILE=$(docker compose exec dev bash -c "ls -t ${CONTAINER_BACKUP_PATH}/*-*-*-*-files.tar 2>/dev/null | head -1" | tr -d '\r')

	if [ -n "$DATABASE_FILE" ]; then
		print_info "Copying database backup..."
		docker compose cp dev:${DATABASE_FILE} "${HOST_BACKUP_PATH}/"
		print_success "Database backup copied"
	fi

	if [ -n "$FILES_FILE" ]; then
		print_info "Copying files backup..."
		docker compose cp dev:${FILES_FILE} "${HOST_BACKUP_PATH}/"
		print_success "Files backup copied"
	fi

	echo
	print_success "========================================="
	print_success "Backup completed successfully!"
	print_success "========================================="
	echo
	print_info "Host backup location: ${HOST_BACKUP_PATH}"
	echo
	print_info "Backup contents:"
	ls -lh "${HOST_BACKUP_PATH}"
fi

echo
print_info "To restore this backup, use:"
print_info "  make restore FILE=<backup_file>"
echo
