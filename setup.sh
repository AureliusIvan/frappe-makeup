#!/bin/bash

# NOTE: This is a legacy setup script with hardcoded values.
# For production use, please use ./scripts/dev-setup.sh instead,
# which supports environment variables and has better error handling.

set -e  # Exit on error

# Load environment variables from .env if it exists
if [ -f .env ]; then
	echo "Loading environment variables from .env"
	set -a
	source .env
	set +a
fi

# Configuration with defaults (use env vars if available)
FRAPPE_VERSION=${FRAPPE_VERSION:-"v15.30.0"}
ERPNEXT_VERSION=${ERPNEXT_VERSION:-"version-15"}
DB_HOST=${DB_HOST:-"mariadb"}
DB_PORT=${DB_PORT:-"3306"}
REDIS_CACHE=${REDIS_CACHE:-"redis://redis-cache"}
REDIS_QUEUE=${REDIS_QUEUE:-"redis://redis-queue"}
REDIS_SOCKETIO=${REDIS_SOCKETIO:-"redis://redis-socketio"}
SITE_NAME=${SITE_NAME:-"localhost"}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"admin"}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-"123"}

echo "=== Frappe/ERPNext Setup ==="
echo "Frappe Version: ${FRAPPE_VERSION}"
echo "ERPNext Version: ${ERPNEXT_VERSION}"
echo "Site Name: ${SITE_NAME}"
echo "WARNING: Using potentially insecure default passwords!"
echo "Set MYSQL_ROOT_PASSWORD and ADMIN_PASSWORD in .env for better security"
echo ""

# Install bench
echo "Initializing bench..."
bench init frappe-bench --frappe-branch ${FRAPPE_VERSION} --python python3

echo "Configuring bench..."
bench set-config -g db_host ${DB_HOST}
bench set-config -gp db_port ${DB_PORT}
bench set-config -g redis_cache "${REDIS_CACHE}"
bench set-config -g redis_queue "${REDIS_QUEUE}"
bench set-config -g redis_socketio "${REDIS_SOCKETIO}"

echo "Creating new site..."
cd frappe-bench && bench new-site ${SITE_NAME} \
	--mariadb-root-password ${MYSQL_ROOT_PASSWORD} \
	--admin-password ${ADMIN_PASSWORD}

echo "Getting ERPNext app..."
bench get-app erpnext --branch ${ERPNEXT_VERSION}

echo "Installing ERPNext..."
bench --site ${SITE_NAME} install-app erpnext

echo ""
echo "=== Setup Complete ==="
echo "Site: ${SITE_NAME}"
echo "Admin Password: ${ADMIN_PASSWORD}"
echo "Access at: http://localhost:8000"