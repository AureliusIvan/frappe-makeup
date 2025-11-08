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
	echo -e "${BLUE}Loading environment variables from .env${NC}"
	set -a
	source .env
	set +a
fi

# Configuration with defaults
FRAPPE_VERSION=${FRAPPE_VERSION:-"v15.30.0"}
ERPNEXT_VERSION=${ERPNEXT_VERSION:-"version-15"}
SITE_NAME=${SITE_NAME:-"localhost"}
DB_HOST=${DB_HOST:-"mariadb"}
DB_PORT=${DB_PORT:-"3306"}
REDIS_CACHE=${REDIS_CACHE:-"redis://redis-cache"}
REDIS_QUEUE=${REDIS_QUEUE:-"redis://redis-queue"}
REDIS_SOCKETIO=${REDIS_SOCKETIO:-"redis://redis-socketio"}

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

# Function to prompt for password securely
prompt_password() {
	local prompt_text="$1"
	local var_name="$2"

	if [ -z "${!var_name}" ]; then
		while true; do
			read -s -p "$(echo -e ${BLUE}${prompt_text}${NC}): " password
			echo
			if [ ${#password} -lt 8 ]; then
				print_warning "Password must be at least 8 characters long"
			else
				eval "$var_name='$password'"
				break
			fi
		done
	else
		print_info "Using $var_name from environment"
	fi
}

# Check if we're running inside a container
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
	print_error "This script should be run inside the Frappe container!"
	print_info "Run: docker compose exec dev /bin/bash"
	print_info "Then run this script from inside the container"
	exit 1
fi

# Check if bench is installed
if ! command -v bench &> /dev/null; then
	print_error "bench command not found!"
	exit 1
fi

print_info "Starting Frappe/ERPNext development setup..."
echo

# Prompt for passwords if not set in environment
prompt_password "Enter MariaDB root password" "MYSQL_ROOT_PASSWORD"
prompt_password "Enter admin password for Frappe site" "ADMIN_PASSWORD"
echo

# Step 1: Initialize bench
if [ -d "frappe-bench" ]; then
	print_warning "frappe-bench directory already exists"
	read -p "$(echo -e ${YELLOW}Do you want to remove it and start fresh? [y/N]:${NC} )" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		print_info "Removing existing frappe-bench directory..."
		rm -rf frappe-bench
	else
		print_info "Skipping bench initialization"
		cd frappe-bench
		SKIP_BENCH_INIT=true
	fi
fi

if [ -z "$SKIP_BENCH_INIT" ]; then
	print_info "Initializing bench with Frappe ${FRAPPE_VERSION}..."
	bench init frappe-bench --frappe-branch ${FRAPPE_VERSION} --python python3
	print_success "Bench initialized successfully"
	cd frappe-bench
fi

# Step 2: Configure bench
print_info "Configuring bench database and Redis settings..."
bench set-config -g db_host ${DB_HOST}
bench set-config -gp db_port ${DB_PORT}
bench set-config -g redis_cache "${REDIS_CACHE}"
bench set-config -g redis_queue "${REDIS_QUEUE}"
bench set-config -g redis_socketio "${REDIS_SOCKETIO}"
print_success "Bench configuration completed"

# Step 3: Wait for MariaDB to be ready
print_info "Waiting for MariaDB to be ready..."
max_attempts=30
attempt=0
while ! mysqladmin ping -h"${DB_HOST}" -P"${DB_PORT}" --silent; do
	attempt=$((attempt + 1))
	if [ $attempt -ge $max_attempts ]; then
		print_error "MariaDB not ready after ${max_attempts} attempts"
		exit 1
	fi
	echo -n "."
	sleep 1
done
echo
print_success "MariaDB is ready"

# Step 4: Create new site
if bench --site ${SITE_NAME} list-apps &> /dev/null; then
	print_warning "Site '${SITE_NAME}' already exists"
	read -p "$(echo -e ${YELLOW}Do you want to reinstall? This will delete all data! [y/N]:${NC} )" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		print_info "Dropping existing site..."
		bench drop-site ${SITE_NAME} --mariadb-root-password "${MYSQL_ROOT_PASSWORD}" --force
	else
		print_info "Skipping site creation"
		SKIP_SITE_CREATION=true
	fi
fi

if [ -z "$SKIP_SITE_CREATION" ]; then
	print_info "Creating new site '${SITE_NAME}'..."
	bench new-site ${SITE_NAME} \
		--mariadb-root-password "${MYSQL_ROOT_PASSWORD}" \
		--admin-password "${ADMIN_PASSWORD}"
	print_success "Site created successfully"
fi

# Step 5: Get ERPNext app
if [ -d "apps/erpnext" ]; then
	print_warning "ERPNext app already exists"
else
	print_info "Getting ERPNext app (${ERPNEXT_VERSION})..."
	bench get-app erpnext --branch ${ERPNEXT_VERSION}
	print_success "ERPNext app downloaded"
fi

# Step 6: Install ERPNext on site
if bench --site ${SITE_NAME} list-apps | grep -q "erpnext"; then
	print_warning "ERPNext already installed on site '${SITE_NAME}'"
else
	print_info "Installing ERPNext on site '${SITE_NAME}'..."
	bench --site ${SITE_NAME} install-app erpnext
	print_success "ERPNext installed successfully"
fi

# Step 7: Install custom app if it exists
if [ -d "apps/invenio_property_management" ]; then
	print_info "Found custom app 'invenio_property_management'"
	if bench --site ${SITE_NAME} list-apps | grep -q "invenio_property_management"; then
		print_warning "Custom app already installed"
	else
		print_info "Installing custom app on site '${SITE_NAME}'..."
		bench --site ${SITE_NAME} install-app invenio_property_management
		print_success "Custom app installed successfully"
	fi
fi

# Final summary
echo
print_success "========================================="
print_success "Development setup completed successfully!"
print_success "========================================="
echo
print_info "Site Name: ${SITE_NAME}"
print_info "Admin Password: ${ADMIN_PASSWORD}"
echo
print_info "Next steps:"
print_info "1. Start bench: bench start"
print_info "2. Access site: http://localhost:8000"
print_info "3. Login with username 'Administrator' and your admin password"
echo
