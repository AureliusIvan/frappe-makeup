# Invenio Property Management - ERPNext Development Environment

A Docker-based development environment for running ERPNext with the custom **Invenio Property Management** application. This setup provides a complete, containerized Frappe/ERPNext stack with MariaDB, Redis, and development tools.

## Features

- **Dockerized Environment** - Complete ERPNext stack in containers
- **Custom App Included** - Invenio Property Management for property management workflows
- **Developer-Friendly** - Auto-reload, detailed errors, and debugging tools enabled
- **Comprehensive Tooling** - Makefile commands, helper scripts, and documentation
- **Pre-configured** - MariaDB, Redis (cache, queue, socketio) ready to use
- **Automated Updates** - Renovate bot keeps dependencies current

## Quick Start

### Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- 4GB+ RAM available for containers
- 10GB+ disk space

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd invenio-finance-erpnext
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your preferred passwords and configuration
   ```

3. **Start the containers:**
   ```bash
   make up
   ```

4. **Run initial setup:**
   ```bash
   make dev-setup
   ```

   This will:
   - Initialize Frappe bench
   - Configure database and Redis connections
   - Create a new site
   - Install ERPNext
   - Install the custom Invenio Property Management app (if present)

5. **Access the application:**
   - **URL:** http://localhost:8000
   - **Username:** `Administrator`
   - **Password:** (as configured in your `.env` file)

## Usage

### Common Commands

```bash
make help          # Show all available commands
make up            # Start all containers
make down          # Stop all containers
make restart       # Restart all containers
make logs          # View logs from all containers
make shell         # Open bash shell in dev container
make ps            # Show container status
```

### Development Workflow

```bash
# Start development
make up
make logs-dev      # Watch dev container logs

# Access container
make shell

# Run migrations
make migrate

# Clear cache
make clear-cache

# Run tests
make test
```

### Database Operations

```bash
# Backup your site
make backup

# Restore from backup
make restore FILE=./backups/localhost_backup.sql.gz

# Access database console
make db-console
```

For more detailed workflows, see **[DEVELOPMENT.md](DEVELOPMENT.md)**.

## Project Structure

```
.
├── docker-compose.yml      # Docker services configuration
├── Dockerfile              # Container image definition
├── Makefile               # Development commands (25+ commands)
├── README.md              # This file
├── DEVELOPMENT.md         # Detailed development guide
├── .env.example          # Environment variables template
├── .env                  # Your local environment (gitignored)
├── setup.sh              # Legacy setup script
├── scripts/              # Helper utilities
│   ├── dev-setup.sh      # Interactive development setup
│   ├── backup.sh         # Backup utility
│   ├── restore.sh        # Restore utility
│   └── reset-db.sh       # Database reset utility
├── backups/              # Local backups directory (gitignored)
└── frappe/               # Frappe bench directory (gitignored)
    └── frappe-bench/
        ├── apps/         # Frappe apps
        │   ├── frappe/   # Frappe framework
        │   ├── erpnext/  # ERPNext app
        │   └── invenio_property_management/  # Custom app
        ├── sites/        # Site data and configurations
        └── logs/         # Application logs
```

### Custom App

The **Invenio Property Management** app is located at:
```
frappe/frappe-bench/apps/invenio_property_management/
```

This app includes:
- Property management doctypes and workflows
- Collection and tracking reports
- Energy dashboard features
- Custom API endpoints
- Pre-commit hooks and CI/CD setup

For app-specific documentation, see: `frappe/frappe-bench/apps/invenio_property_management/README.md`

## Docker Services

This environment includes the following services:

| Service | Description | Port |
|---------|-------------|------|
| `dev` | Frappe/ERPNext application server | 8000 |
| `mariadb` | Database server (MariaDB 11.5) | 3306 |
| `redis-cache` | Redis cache | - |
| `redis-queue` | Redis queue for background jobs | - |
| `redis-socketio` | Redis for Socket.IO | - |

## Configuration

All configuration is done via the `.env` file. Key variables:

```bash
# Database
MYSQL_ROOT_PASSWORD=your_secure_password
MYSQL_PASSWORD=your_db_password

# Application
ADMIN_PASSWORD=your_admin_password
SITE_NAME=localhost

# Versions
FRAPPE_VERSION=v15.30.0
ERPNEXT_VERSION=version-15
```

See `.env.example` for all available options.

## Available Make Commands

Run `make help` to see all commands. Key commands:

### Docker Operations
- `make up` - Start containers
- `make down` - Stop containers
- `make restart` - Restart containers
- `make up-rebuild` - Rebuild and start containers
- `make ps` - Show container status

### Logs & Monitoring
- `make logs` - Tail all logs
- `make logs-dev` - Dev container logs only
- `make logs-db` - Database logs
- `make info` - Show environment info

### Container Access
- `make shell` - Open bash in dev container
- `make bench` - Access bench CLI
- `make db-console` - MariaDB console
- `make redis-console` - Redis console

### Development
- `make dev-setup` - Run initial setup
- `make migrate` - Run migrations
- `make clear-cache` - Clear all caches
- `make test` - Run tests
- `make install-app` - Install a Frappe app

### Backup & Restore
- `make backup` - Create site backup
- `make restore` - Restore from backup

### Cleanup
- `make clean` - Remove stopped containers
- `make clean-cache` - Remove Python cache files
- `make clean-all` - Deep clean everything

## Troubleshooting

### Common Issues

**Containers not starting:**
```bash
make logs          # Check for errors
make down          # Stop everything
make up-rebuild    # Rebuild and start
```

**Database connection errors:**
```bash
make logs-db       # Check database logs
make restart       # Restart all services
```

**Changes not reflected:**
```bash
make clear-cache   # Clear application cache
make restart       # Restart services
```

**Port 8000 already in use:**
```bash
make down
sudo lsof -i :8000  # Find what's using the port
# Kill the process or change the port in docker-compose.yml
```

For more troubleshooting tips, see **[DEVELOPMENT.md](DEVELOPMENT.md#common-issues)**.

## Documentation

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Comprehensive development guide
- **[Frappe Framework Docs](https://frappeframework.com/docs)** - Frappe documentation
- **[ERPNext Docs](https://docs.erpnext.com)** - ERPNext documentation
- **Custom App Docs** - See `frappe/frappe-bench/apps/invenio_property_management/`

## Development Practices

This project follows these practices:

- **Environment Variables** - All credentials and configuration via `.env`
- **No Hardcoded Secrets** - Security-first approach
- **Automated Testing** - CI/CD with GitHub Actions (in custom app)
- **Code Quality** - Pre-commit hooks with ruff, eslint, prettier
- **Automated Updates** - Renovate bot for dependency management
- **Comprehensive Documentation** - README, DEVELOPMENT.md, inline comments

## Contributing

1. Create a new branch for your feature
2. Make your changes
3. Run tests: `make test`
4. Submit a pull request

For the custom app, see its contributing guidelines.

## License

See individual components for their licenses:
- Frappe Framework: MIT License
- ERPNext: GNU GPL v3
- Custom App: See `frappe/frappe-bench/apps/invenio_property_management/license.txt`

## Support

- **Issues:** Report bugs via GitHub Issues
- **Frappe Forum:** [discuss.frappe.io](https://discuss.frappe.io)
- **ERPNext Forum:** [discuss.erpnext.com](https://discuss.erpnext.com)

## Maintenance

This repository uses:
- **Renovate Bot** - Automated dependency updates
- **GitHub Actions** - CI/CD for the custom app

See `.github/workflows/` in the custom app for CI/CD configuration.

---

**Quick Links:**
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Development Guide](DEVELOPMENT.md)
- [Make Commands](#available-make-commands)
- [Troubleshooting](#troubleshooting)
