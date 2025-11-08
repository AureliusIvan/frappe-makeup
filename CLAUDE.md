# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Docker-based Frappe/ERPNext development environment** for the **Invenio Property Management** custom application. The repository provides a complete containerized development stack with MariaDB, Redis, and developer tools, designed specifically for property management workflows within ERPNext.

## Architecture

### Stack Components

- **Frappe Framework**: Python/JavaScript framework for business applications (version 15.x)
- **ERPNext**: Open-source ERP built on Frappe (version 15.x)
- **Custom App**: `invenio_property_management` - Property management module
- **Database**: MariaDB 11.5 with UTF8MB4 support
- **Cache Layer**: Redis (3 instances - cache, queue, socketio)
- **Container Base**: `frappe/bench:v5.24.1` with development tools

### Service Architecture

The application runs in a multi-container Docker environment:

```
dev container (port 8000)
  ├── Frappe bench (/home/frappe/bench/frappe-bench)
  │   ├── apps/frappe (Frappe framework)
  │   ├── apps/erpnext (ERPNext)
  │   ├── apps/invenio_property_management (custom app)
  │   └── sites/localhost (site data)
  ├── Python environment
  └── Node.js environment

mariadb container (port 3306)
  └── Database: erpnext

redis-cache container (cache layer)
redis-queue container (background jobs)
redis-socketio container (real-time updates)
```

### Volume Mounts

- `./frappe:/home/frappe/bench` - Bench directory (gitignored, created at runtime)
- `mariadb-data:/var/lib/mysql` - Database persistence
- Redis data volumes for each Redis service

## Development Workflow

### Environment Setup

1. **Initial Configuration**: Copy `.env.example` to `.env` and set:
   - `MYSQL_ROOT_PASSWORD` - MariaDB root password
   - `MYSQL_PASSWORD` - Application database password
   - `ADMIN_PASSWORD` - Frappe Administrator password (min 8 chars)
   - Framework versions: `FRAPPE_VERSION`, `ERPNEXT_VERSION`

2. **First-Time Setup**:
   ```bash
   make up              # Start containers
   make dev-setup       # Initialize bench, create site, install apps
   ```

   The `dev-setup` script (`scripts/dev-setup.sh`) performs:
   - Bench initialization with Frappe
   - Database/Redis configuration
   - Site creation
   - ERPNext installation
   - Custom app installation (if present in `apps/invenio_property_management`)

### Common Development Commands

**Container Operations:**
```bash
make up              # Start all services
make down            # Stop all services
make restart         # Restart services
make shell           # Access dev container shell
make logs-dev        # View development logs
```

**Database Operations:**
```bash
make migrate         # Run database migrations (bench migrate)
make db-console      # MySQL console as root
make backup          # Create site backup
make restore FILE=path/to/backup.sql.gz  # Restore backup
```

**Development Tasks:**
```bash
make clear-cache     # Clear Frappe cache
make test            # Run all tests
make test-app APP=invenio_property_management  # Run app tests
make install-app APP=app_name  # Install additional app
```

### Working with Bench

Inside the container (`make shell`), you have direct access to Frappe's `bench` CLI:

```bash
bench --site localhost console       # Python REPL with Frappe context
bench --site localhost migrate       # Run migrations
bench --site localhost clear-cache   # Clear cache
bench --site localhost list-apps     # List installed apps
bench --site localhost enable-scheduler  # Enable background jobs
```

## Custom App: Invenio Property Management

### Location
`frappe/frappe-bench/apps/invenio_property_management/`

### Structure
```
invenio_property_management/
├── invenio_property_management/     # Main module
│   ├── hooks.py                     # Frappe hooks configuration
│   ├── doctype/                     # DocTypes (database models)
│   ├── api/                         # REST API endpoints
│   └── public/                      # Frontend assets (JS/CSS)
├── README.md
└── .pre-commit-config.yaml          # Code quality hooks
```

### Code Quality Tools

The custom app uses pre-commit hooks with:
- **ruff**: Python linting and formatting
- **eslint**: JavaScript linting
- **prettier**: Code formatting
- **pyupgrade**: Python syntax modernization

**Setup pre-commit** (inside container):
```bash
cd apps/invenio_property_management
pre-commit install
```

### DocType Development

Frappe uses "DocTypes" as the data model layer (equivalent to Django models or SQLAlchemy models):

1. **Create DocType**: Use Frappe UI (Setup > Customize > DocType)
2. **Location**: `invenio_property_management/doctype/<doctype_name>/`
3. **Files generated**:
   - `<doctype_name>.json` - Schema definition
   - `<doctype_name>.py` - Controller (business logic)
   - `test_<doctype_name>.py` - Unit tests

After creating/modifying DocTypes, always run: `make migrate`

## Important Configuration Files

### docker-compose.yml
- Defines all services (dev, mariadb, redis instances)
- Sets `FRAPPE_DEVELOPER: 1` for development mode (auto-reload, detailed errors)
- Port mapping: 8000 (dev container)

### Dockerfile
- Based on `frappe/bench:v5.24.1`
- Installs `redis-server` in container
- Runs as `frappe` user (UID/GID for proper permissions)

### Makefile
- 25+ commands for container/database/development operations
- Uses Docker Compose with `.env` file
- Main target: `help` (run `make` or `make help`)

### .env.example
- Template for environment variables
- **Security critical**: Never commit `.env` (in `.gitignore`)
- Contains database credentials, admin passwords, version pins

## Database Schema

### ERPNext Standard DocTypes
ERPNext provides standard business entities: Customer, Supplier, Item, Sales Order, Purchase Order, Payment Entry, etc.

### Custom Property Management DocTypes
Located in `invenio_property_management/doctype/`. The custom app extends ERPNext with property-specific entities.

### Querying Data

**Python (in DocType controllers or API):**
```python
import frappe

# Get single document
doc = frappe.get_doc("DocType Name", "document-id")

# Query documents
docs = frappe.get_all("DocType Name",
    filters={"status": "Active"},
    fields=["name", "field1", "field2"])

# ORM-style queries (preferred)
from frappe.query_builder import DocType
Property = DocType("Property")
query = frappe.qb.from_(Property).select(Property.name).where(Property.status == "Active")
```

**SQL (for complex queries):**
```python
frappe.db.sql("""
    SELECT name, status FROM `tabProperty`
    WHERE status = 'Active'
""", as_dict=True)
```

## Running Tests

**All tests:**
```bash
make test
```

**Custom app tests only:**
```bash
make test-app APP=invenio_property_management
```

**Inside container (more control):**
```bash
bench --site localhost run-tests --app invenio_property_management
bench --site localhost run-tests --module invenio_property_management.tests.test_module_name
```

## Developer Mode

Developer mode is **always enabled** via `FRAPPE_DEVELOPER: 1` in `docker-compose.yml`.

**Benefits:**
- Auto-reload on Python/JS file changes
- Detailed stack traces on errors
- Unminified JavaScript/CSS
- Access to bench console and debugging tools

## Important Paths

### Inside Container
- Bench directory: `/home/frappe/bench/frappe-bench/`
- Apps: `/home/frappe/bench/frappe-bench/apps/`
- Sites: `/home/frappe/bench/frappe-bench/sites/`
- Logs: `/home/frappe/bench/frappe-bench/logs/`

### On Host (mounted)
- Bench: `./frappe/frappe-bench/` (gitignored)
- Backups: `./backups/` (gitignored)
- Scripts: `./scripts/`

## Troubleshooting

### Container won't start
```bash
make ps              # Check status
make logs-db         # Check database logs
make restart         # Restart all
```

### Database connection errors
```bash
make db-console      # Verify database access
docker compose logs mariadb  # Check MariaDB status
```

### Changes not reflected
```bash
make clear-cache     # Clear Frappe cache
make restart         # Restart dev container
```

### Permission errors
Inside container, ensure files are owned by `frappe:frappe`:
```bash
ls -la
# If needed: chown -R frappe:frappe /home/frappe/bench
```

## Multi-App Environment

This bench can host **multiple Frappe apps**. Currently installed:
- frappe (framework)
- erpnext (ERP application)
- invenio_property_management (custom app)
- Additional apps: builder, crm, drive, helpdesk, hrms, insights, payments, print_designer, wiki

Each app has hooks defined in `apps/<app_name>/<app_name>/hooks.py` that integrate with Frappe's event system.

## Backup and Restore

### Backup
```bash
make backup          # Creates backup in container
# Manual: bench --site localhost backup
```

Backups stored in: `sites/localhost/private/backups/`

### Restore
```bash
make restore FILE=./backups/site_backup.sql.gz
```

**Restore script** (`scripts/restore.sh`) handles:
- Site recreation
- Database restoration
- App reinstallation

## Security Considerations

1. **Never commit `.env`** - Contains all credentials
2. **Change default passwords** - Set strong passwords in `.env`
3. **Database access** - MariaDB not exposed to host by default
4. **Developer mode** - Only for development, disable in production

## Related Documentation

- Frappe Framework: https://frappeframework.com/docs
- ERPNext: https://docs.erpnext.com
- Frappe Bench CLI: https://frappeframework.com/docs/user/en/bench
- Custom App: `frappe/frappe-bench/apps/invenio_property_management/README.md`
