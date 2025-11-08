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
SITE_NAME=${SITE_NAME:-"localhost"}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"root"}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-"admin"}

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

# Check if we're running inside a container
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
	print_error "This script should be run inside the Frappe container!"
	print_info "Run: docker compose exec dev bash -c 'cd /home/frappe/bench && ../scripts/reset-db.sh'"
	exit 1
fi

# Check if bench is installed
if ! command -v bench &> /dev/null; then
	print_error "bench command not found!"
	exit 1
fi

# Warning message
echo
print_warning "========================================="
print_warning "WARNING: DATABASE RESET"
print_warning "========================================="
print_warning "This will completely reset the database for site: ${SITE_NAME}"
print_warning "ALL DATA WILL BE PERMANENTLY LOST!"
print_warning "========================================="
echo

# Confirmation prompt
read -p "$(echo -e ${RED}Are you absolutely sure? Type 'RESET' to continue:${NC} )" confirmation
echo

if [ "$confirmation" != "RESET" ]; then
	print_info "Reset cancelled"
	exit 0
fi

# Additional confirmation
read -p "$(echo -e ${RED}Last chance! Type 'YES' to proceed with reset:${NC} )" final_confirmation
echo

if [ "$final_confirmation" != "YES" ]; then
	print_info "Reset cancelled"
	exit 0
fi

# Perform reset
print_info "Starting database reset for site '${SITE_NAME}'..."

# Check if site exists
if ! bench --site ${SITE_NAME} list-apps &> /dev/null; then
	print_error "Site '${SITE_NAME}' does not exist!"
	exit 1
fi

# Get list of installed apps before reset
print_info "Getting list of installed apps..."
INSTALLED_APPS=$(bench --site ${SITE_NAME} list-apps 2>/dev/null || echo "")
echo "Installed apps: $INSTALLED_APPS"

# Drop the site
print_info "Dropping site '${SITE_NAME}'..."
bench drop-site ${SITE_NAME} --mariadb-root-password "${MYSQL_ROOT_PASSWORD}" --force
print_success "Site dropped successfully"

# Recreate the site
print_info "Recreating site '${SITE_NAME}'..."
bench new-site ${SITE_NAME} \
	--mariadb-root-password "${MYSQL_ROOT_PASSWORD}" \
	--admin-password "${ADMIN_PASSWORD}"
print_success "Site recreated successfully"

# Reinstall apps
if [ -n "$INSTALLED_APPS" ]; then
	print_info "Reinstalling apps..."
	for app in $INSTALLED_APPS; do
		if [ "$app" != "frappe" ]; then  # frappe is already installed
			print_info "Installing app: $app"
			bench --site ${SITE_NAME} install-app $app || print_warning "Failed to install $app"
		fi
	done
	print_success "Apps reinstalled"
fi

# Final summary
echo
print_success "========================================="
print_success "Database reset completed successfully!"
print_success "========================================="
echo
print_info "Site Name: ${SITE_NAME}"
print_info "Admin Username: Administrator"
print_info "Admin Password: ${ADMIN_PASSWORD}"
echo
print_info "You can now access the site at: http://localhost:8000"
echo
