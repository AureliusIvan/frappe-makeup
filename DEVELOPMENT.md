# Development Guide

This guide covers common development workflows, debugging tips, and best practices for working with this Frappe/ERPNext development environment.

## Table of Contents

- [Quick Start](#quick-start)
- [Daily Workflows](#daily-workflows)
- [Container Access](#container-access)
- [Database Operations](#database-operations)
- [Testing](#testing)
- [Debugging](#debugging)
- [Common Issues](#common-issues)
- [Useful Commands](#useful-commands)

## Quick Start

### First Time Setup

1. **Create environment configuration:**
   ```bash
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

2. **Start the containers:**
   ```bash
   make up
   ```

3. **Run initial setup:**
   ```bash
   make dev-setup
   ```
   This will initialize Frappe bench, create a site, and install ERPNext.

4. **Access the application:**
   - URL: http://localhost:8000
   - Username: `Administrator`
   - Password: (as set in your .env or default from setup)

### Subsequent Starts

```bash
make up     # Start containers
make logs   # View logs
```

## Daily Workflows

### Starting Your Day

```bash
# Start all services
make up

# Check container status
make ps

# View logs
make logs
```

### During Development

```bash
# Access the container shell
make shell

# Run migrations after code changes
make migrate

# Clear cache when needed
make clear-cache

# Run tests
make test
```

### Ending Your Day

```bash
# Stop containers (preserves data)
make stop

# Or completely shut down
make down
```

## Container Access

### Shell Access

```bash
# Open bash in dev container
make shell

# Once inside, you have access to bench commands
bench --version
bench --site localhost list-apps
```

### Bench Commands

```bash
# Via make (from host)
make bench CMD="bench --site localhost migrate"

# Or from inside container
make shell
# Then:
bench --site localhost migrate
bench --site localhost console
bench --site localhost clear-cache
```

### Database Console

```bash
# MariaDB console as root
make db-console

# MariaDB console as erpnext user
make db-console-user

# Run SQL queries
USE erpnext;
SHOW TABLES;
SELECT * FROM tabUser LIMIT 5;
```

### Redis Console

```bash
# Access Redis CLI
make redis-console

# Common Redis commands
KEYS *
GET key_name
FLUSHALL  # Clear all cache (use with caution!)
```

## Database Operations

### Backup

Create a backup of your site:

```bash
# Quick backup (stored in container)
make backup

# Backup with custom site name
make backup SITE=mysite
```

Backups are stored in:
- Container: `/home/frappe/bench/frappe-bench/sites/{site}/private/backups/`
- Host: `./backups/{site}_{timestamp}/`

### Restore

Restore from a backup:

```bash
make restore FILE=./backups/localhost_20250108/database.sql.gz
```

### Reset Database

**WARNING: This deletes all data!**

```bash
# Interactive reset with confirmations
docker compose exec dev bash
cd /home/frappe/bench
../scripts/reset-db.sh
```

### Migrations

After modifying DocTypes or making schema changes:

```bash
make migrate

# Or for specific site
make bench CMD="bench --site localhost migrate"
```

## Testing

### Run All Tests

```bash
make test
```

### Run Tests for Specific App

```bash
make test-app APP=invenio_property_management
```

### Run Tests from Container

```bash
make shell

# All tests
bench --site localhost run-tests

# Specific app
bench --site localhost run-tests --app invenio_property_management

# Specific module
bench --site localhost run-tests --module invenio_property_management.tests.test_collection_report_generator
```

## Debugging

### View Logs

```bash
# All containers
make logs

# Dev container only
make logs-dev

# Database logs
make logs-db

# Redis logs
make logs-redis
```

### Enable Frappe Developer Mode

Developer mode is already enabled via the `FRAPPE_DEVELOPER: 1` environment variable in `docker-compose.yml`.

Benefits of developer mode:
- Auto-reload on code changes
- Detailed error messages
- JS/CSS not minified
- Access to developer console

### Common Debugging Steps

1. **Check container status:**
   ```bash
   make ps
   ```

2. **View recent logs:**
   ```bash
   make logs | tail -100
   ```

3. **Access Python debugger:**
   Add to your code:
   ```python
   import pdb; pdb.set_trace()
   ```

4. **Check bench console:**
   ```bash
   make shell
   bench --site localhost console
   # Python REPL with Frappe context
   ```

5. **Inspect database:**
   ```bash
   make db-console
   ```

## Common Issues

### Issue: Cannot connect to database

**Solution:**
```bash
# Check if MariaDB is running
make ps

# View MariaDB logs
make logs-db

# Restart containers
make restart
```

### Issue: Port 8000 already in use

**Solution:**
```bash
# Stop containers
make down

# Check what's using the port
sudo lsof -i :8000

# Kill the process or change port in docker-compose.yml
```

### Issue: Bench not found

**Solution:**
```bash
# Make sure you're inside the container
make shell

# Bench should be available in PATH
which bench
```

### Issue: Permission denied errors

**Solution:**
```bash
# Check file ownership in container
make shell
ls -la

# Fix permissions if needed
sudo chown -R frappe:frappe /home/frappe/bench
```

### Issue: Changes not reflected

**Solution:**
```bash
# Clear cache
make clear-cache

# Restart services
make restart

# Rebuild if needed
make up-rebuild
```

## Useful Commands

### Information

```bash
make help          # Show all available commands
make info          # Show environment information
make ps            # Show container status
```

### Container Management

```bash
make up            # Start containers
make down          # Stop containers
make restart       # Restart containers
make stop          # Stop without removing
make start         # Start stopped containers
make up-rebuild    # Rebuild and start fresh
```

### Development

```bash
make shell         # Container shell access
make bench         # Run bench commands
make migrate       # Run migrations
make clear-cache   # Clear all caches
make test          # Run tests
```

### Database

```bash
make db-console    # MariaDB console
make backup        # Create backup
make restore       # Restore from backup
```

### Cleanup

```bash
make clean         # Clean Docker artifacts
make clean-cache   # Clean Python cache files
make clean-all     # Deep clean everything
```

### Install Custom App

```bash
make install-app APP=your_app_name
```

## Directory Structure

```
.
├── docker-compose.yml      # Docker services configuration
├── Dockerfile              # Container image definition
├── Makefile               # Development commands
├── setup.sh               # Legacy setup script
├── .env                   # Environment variables (create from .env.example)
├── .env.example          # Environment variables template
├── scripts/              # Helper scripts
│   ├── dev-setup.sh      # Interactive setup
│   ├── backup.sh         # Backup utility
│   ├── restore.sh        # Restore utility
│   └── reset-db.sh       # Database reset
├── backups/              # Local backups (gitignored)
└── frappe/               # Mounted to container (gitignored)
    └── frappe-bench/     # Frappe bench directory
        ├── apps/         # Frappe apps
        ├── sites/        # Sites data
        └── logs/         # Application logs
```

## Custom App Development

### Installing Your App

If you have a custom Frappe app in `frappe/frappe-bench/apps/your_app`:

```bash
make install-app APP=your_app
```

### Setting Up Pre-commit Hooks

For the custom app `invenio_property_management`:

```bash
make shell
cd apps/invenio_property_management
pre-commit install
```

### Running Linters

```bash
make shell
cd apps/invenio_property_management

# Run ruff
ruff check .

# Run eslint
eslint .

# Run prettier
prettier --check .
```

## Best Practices

1. **Always use environment variables** instead of hardcoding credentials
2. **Create backups** before major changes
3. **Test in development** before deploying to production
4. **Use make commands** instead of raw docker/bench commands when possible
5. **Keep dependencies updated** via Renovate bot
6. **Run tests** before committing code
7. **Clear cache** after significant changes
8. **Check logs** when debugging issues

## Additional Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [ERPNext Documentation](https://docs.erpnext.com)
- [Bench Documentation](https://frappeframework.com/docs/user/en/bench)
- Custom App: See `frappe/frappe-bench/apps/invenio_property_management/README.md`
