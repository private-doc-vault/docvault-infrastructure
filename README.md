# DocVault Infrastructure

**Docker Compose orchestration, configuration, and integration for the multi-service document management system**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Quick Start](#quick-start)
- [Service Integration](#service-integration)
- [Environment Variables](#environment-variables)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

DocVault Infrastructure provides the orchestration layer for a multi-service document archiving and cataloging system. It manages service integration, shared infrastructure components (PostgreSQL, Redis, Meilisearch, Nginx), and provides both development and production Docker Compose configurations.

### Repositories

- **[docvault-backend](https://github.com/private-doc-vault/docvault-backend)** - Symfony REST API for document management
- **[docvault-frontend](https://github.com/private-doc-vault/docvault-frontend)** - React SPA with Redux Toolkit
- **[docvault-ocr-service](https://github.com/private-doc-vault/docvault-ocr-service)** - FastAPI OCR processing service
- **[docvault-infrastructure](https://github.com/private-doc-vault/docvault-infrastructure)** - This repository

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           Nginx (Port 80)                        │
│                      Reverse Proxy & Load Balancer              │
└─────────────────┬───────────────────────────┬───────────────────┘
                  │                           │
         ┌────────▼─────────┐        ┌───────▼────────┐
         │    Frontend       │        │    Backend     │
         │   React SPA       │        │  Symfony API   │
         │  (Port 3000)      │        │  (Port 9000)   │
         └───────────────────┘        └────────┬───────┘
                                               │
                                      ┌────────┴─────────┐
                                      │                  │
                              ┌───────▼──────┐   ┌──────▼─────────┐
                              │ OCR Service  │   │  PostgreSQL    │
                              │   FastAPI    │   │   Database     │
                              │ (Port 8000)  │   │  (Port 5432)   │
                              └──────┬───────┘   └────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
            ┌───────▼─────────┐           ┌─────────▼─────────┐
            │     Redis       │           │   Meilisearch     │
            │ Queue & Cache   │           │  Search Engine    │
            │  (Port 6379)    │           │   (Port 7700)     │
            └─────────────────┘           └───────────────────┘
```

### Communication Flow

1. **User Request** → Nginx → Frontend (for static assets) or Backend API
2. **Document Upload** → Backend stores file → Dispatches OCR task
3. **OCR Processing** → OCR service processes → Sends webhook to Backend
4. **Search** → Backend syncs to Meilisearch → Frontend queries via Backend
5. **Real-time Updates** → Redis pub/sub for status updates

### Shared Storage

All services share access to document storage:
- **Backend**: Reads/writes documents at `/var/www/html/storage/documents`
- **OCR Service**: Reads documents for processing at same path
- **Volume Mount**: `./storage:/var/www/html/storage`

## Quick Start

### Prerequisites

- **Docker** 20.10+ and **Docker Compose** 2.0+
- **Git** 2.30+
- Minimum 4GB RAM, 10GB free disk space

### Installation

1. **Clone the repository with submodules:**

```bash
git clone --recursive https://github.com/private-doc-vault/docvault-infrastructure.git
cd docvault-infrastructure
```

2. **Run the setup script:**

```bash
./setup.sh
```

This script will:
- Initialize git submodules
- Create required directories (`storage/`, `logs/`)
- Copy `.env.example` to `.env`
- Validate Docker installation

3. **Configure environment variables:**

Edit `.env` file and update the following required variables:
- `APP_SECRET` - Generate with `openssl rand -hex 32`
- `JWT_SECRET_KEY` - Generate with `openssl rand -hex 32`
- `JWT_PASSPHRASE` - Choose a strong passphrase
- `OCR_WEBHOOK_SECRET` - Generate with `openssl rand -hex 32`
- `MEILISEARCH_MASTER_KEY` - Generate with `openssl rand -hex 32`

4. **Start services:**

**Development mode** (builds from source in submodules):
```bash
docker-compose -f docker-compose.dev.yml up -d
```

**Production mode** (uses published Docker images):
```bash
docker-compose up -d
```

5. **Verify services are running:**

```bash
docker-compose ps
```

6. **Access the application:**

- **Frontend:** http://localhost
- **Backend API:** http://localhost/api
- **OCR Service:** http://localhost/ocr
- **Meilisearch:** http://localhost:7700

## Service Integration

### Backend Service

**Technology:** Symfony 7.3, PHP 8.4
**Port:** 9000 (internal), exposed via Nginx
**Database:** PostgreSQL
**Cache/Queue:** Redis
**Search:** Meilisearch

**Key Features:**
- REST API for document management
- JWT + session-based authentication
- Role-based access control (RBAC)
- Async message processing (Symfony Messenger)
- OCR orchestration and webhook receiver

### Frontend Service

**Technology:** React 19, Redux Toolkit, Vite
**Port:** 3000 (internal), exposed via Nginx

**Key Features:**
- Modern SPA interface
- State management with Redux Toolkit
- JWT authentication
- Real-time document status updates

### OCR Service

**Technology:** Python 3.12, FastAPI, Tesseract OCR
**Port:** 8000 (internal), exposed via Nginx

**Key Features:**
- Tesseract OCR processing
- Redis-based task queue with priority support
- Background worker process
- Webhook notifications (completion, failure, progress)
- Metadata extraction

### Infrastructure Services

**PostgreSQL 16:**
- Primary database for backend
- Port: 5432 (exposed for development)
- Initialization script: `postgres/init-db.sql`

**Redis 7:**
- Task queue for OCR service
- Cache for backend
- Port: 6379 (exposed for development)
- Configuration: `redis/redis.conf`

**Meilisearch 1.5:**
- Full-text search engine
- Port: 7700 (exposed)
- Configuration: `meilisearch/config.toml`

**Nginx:**
- Reverse proxy for all services
- Port: 80 (exposed)
- Configuration: `nginx/nginx.conf` (production), `nginx/nginx-dev.conf` (development)

## Environment Variables

### Backend Service

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_ENV` | Application environment | `prod`, `dev` |
| `APP_SECRET` | Symfony secret key | `<random-32-char-hex>` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@postgres:5432/docvault` |
| `REDIS_URL` | Redis connection string | `redis://redis:6379` |
| `MEILISEARCH_URL` | Meilisearch URL | `http://meilisearch:7700` |
| `MEILISEARCH_API_KEY` | Meilisearch master key | `<random-key>` |
| `OCR_SERVICE_URL` | OCR service URL | `http://ocr-service:8000` |
| `OCR_WEBHOOK_SECRET` | Webhook HMAC secret | `<random-32-char-hex>` |
| `JWT_SECRET_KEY` | JWT signing key | `<random-32-char-hex>` |
| `JWT_PASSPHRASE` | JWT passphrase | `<strong-passphrase>` |

### Frontend Service

| Variable | Description | Example |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API URL | `/api` (relative) or `http://localhost/api` |

### OCR Service

| Variable | Description | Example |
|----------|-------------|---------|
| `REDIS_URL` | Redis connection string | `redis://redis:6379` |
| `REDIS_PASSWORD` | Redis password | `redis_pass` |
| `WEBHOOK_URL` | Backend webhook endpoint | `http://backend/api/webhooks/ocr-status` |
| `WEBHOOK_SECRET` | HMAC secret (must match backend) | `<random-32-char-hex>` |
| `LOG_LEVEL` | Logging level | `INFO`, `DEBUG` |

### Infrastructure Services

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_DB` | Database name | `docvault` |
| `POSTGRES_USER` | Database user | `docvault_user` |
| `POSTGRES_PASSWORD` | Database password | `<strong-password>` |
| `REDIS_PASSWORD` | Redis password | `redis_pass` |
| `MEILISEARCH_MASTER_KEY` | Meilisearch master key | `<random-key>` |

## Development Workflow

### Working with Submodules

The infrastructure repository uses git submodules to reference service repositories:

**Update submodules to latest commits:**
```bash
git submodule update --remote --merge
```

**Check submodule status:**
```bash
git submodule status
```

**Pull latest changes for all submodules:**
```bash
git submodule foreach git pull origin main
```

### Local Development Setup

1. **Make changes in a service repository:**
```bash
cd services/backend
# Make your changes
git add .
git commit -m "feat: add new feature"
git push
```

2. **Test changes locally:**
```bash
# From infrastructure root
docker-compose -f docker-compose.dev.yml build backend
docker-compose -f docker-compose.dev.yml up -d backend
```

3. **View logs:**
```bash
docker-compose -f docker-compose.dev.yml logs -f backend
```

4. **Run tests in a service:**
```bash
# Backend tests
docker-compose -f docker-compose.dev.yml exec backend composer test

# Frontend tests
docker-compose -f docker-compose.dev.yml exec frontend npm test

# OCR service tests
docker-compose -f docker-compose.dev.yml exec ocr-service pytest
```

### Creating a Release

1. **Update version in service repository:**
   - Update version numbers in code if applicable
   - Commit and push changes

2. **Create a GitHub release:**
```bash
cd services/backend
gh release create v1.0.1 --title "v1.0.1" --notes "Release notes here"
```

3. **Release workflow triggers automatically:**
   - Builds and pushes Docker image to ghcr.io
   - Tags image with version (e.g., `v1.0.1`) and `latest`
   - Dispatches event to infrastructure repository

4. **Infrastructure repo receives automated PR:**
   - Updates submodule reference to new release tag
   - Updates `docker-compose.yml` image tag
   - Review and merge the PR

### Running Individual Services

You can run and test individual services outside of Docker:

**Backend:**
```bash
cd services/backend
composer install
symfony server:start
```

**Frontend:**
```bash
cd services/frontend
npm install
npm run dev
```

**OCR Service:**
```bash
cd services/ocr-service
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Testing

### Integration Tests

Integration tests are located in `tests/integration/`:

```bash
# Start all services
docker-compose -f docker-compose.dev.yml up -d

# Run integration tests
cd tests/integration
pytest -v

# Run with coverage
pytest --cov=. -v
```

### Service-Specific Tests

Each service has its own test suite:

**Backend (PHPUnit):**
```bash
docker-compose -f docker-compose.dev.yml exec backend composer test
```

**Frontend (Vitest):**
```bash
docker-compose -f docker-compose.dev.yml exec frontend npm test
```

**OCR Service (pytest):**
```bash
docker-compose -f docker-compose.dev.yml exec ocr-service pytest
```

## Troubleshooting

### Common Issues

#### Port Conflicts

**Symptom:** `Error: Bind for 0.0.0.0:80 failed: port is already allocated`

**Solution:**
```bash
# Check what's using the port
lsof -i :80
# or
netstat -an | grep :80

# Stop the conflicting service or change port in docker-compose.yml
# Edit docker-compose.yml and change nginx port mapping:
ports:
  - "8080:80"  # Use port 8080 instead
```

#### Docker Not Running

**Symptom:** `Cannot connect to the Docker daemon`

**Solution:**
```bash
# Check Docker status
docker info

# Start Docker Desktop (macOS/Windows) or Docker daemon (Linux)
# macOS: Open Docker Desktop application
# Linux:
sudo systemctl start docker
```

#### Submodule Sync Issues

**Symptom:** `Submodule is not initialized` or empty submodule directories

**Solution:**
```bash
# Initialize and update all submodules
git submodule init
git submodule update --recursive

# Or re-clone with submodules
cd ..
rm -rf docvault-infrastructure
git clone --recursive https://github.com/private-doc-vault/docvault-infrastructure.git
```

#### Services Not Starting

**Symptom:** Container exits immediately or shows unhealthy status

**Solution:**
```bash
# Check service logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs ocr-service

# Common issues:
# 1. Missing .env file - copy from .env.example
# 2. Invalid environment variables - check .env syntax
# 3. Database not ready - wait for postgres to be healthy
# 4. Port conflicts - see Port Conflicts section above

# Restart specific service
docker-compose restart backend
```

#### Database Connection Errors

**Symptom:** `SQLSTATE[HY000] [2002] Connection refused`

**Solution:**
```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Verify database credentials in .env match docker-compose.yml

# Restart PostgreSQL
docker-compose restart postgres
```

#### OCR Processing Failures

**Symptom:** Documents stuck in "processing" status

**Solution:**
```bash
# Check OCR service logs
docker-compose logs ocr-service

# Check Redis queue
docker-compose exec redis redis-cli
AUTH redis_pass
KEYS ocr:*

# Check worker process is running
docker-compose exec ocr-service ps aux | grep worker

# Restart OCR service and worker
docker-compose restart ocr-service
```

#### Permission Issues with Storage

**Symptom:** `Permission denied` when uploading documents

**Solution:**
```bash
# Fix storage directory permissions
chmod -R 777 storage/

# Or use appropriate user permissions
sudo chown -R $(whoami):$(whoami) storage/
chmod -R 755 storage/
```

#### Meilisearch Connection Issues

**Symptom:** Search not working, `Connection refused` to Meilisearch

**Solution:**
```bash
# Check Meilisearch status
docker-compose ps meilisearch
docker-compose logs meilisearch

# Verify MEILISEARCH_MASTER_KEY matches in:
# - .env (MEILISEARCH_API_KEY)
# - docker-compose.yml (MEILI_MASTER_KEY)

# Restart Meilisearch
docker-compose restart meilisearch

# Rebuild search index
docker-compose exec backend php bin/console app:reindex-documents
```

### Debug Mode

Enable debug mode for more verbose logging:

```bash
# Edit .env
APP_ENV=dev
APP_DEBUG=1
LOG_LEVEL=DEBUG

# Restart services
docker-compose restart
```

### Getting Help

If you encounter issues not covered here:

1. Check service-specific documentation:
   - [Backend README](https://github.com/private-doc-vault/docvault-backend/blob/main/README.md)
   - [Frontend README](https://github.com/private-doc-vault/docvault-frontend/blob/main/README.md)
   - [OCR Service README](https://github.com/private-doc-vault/docvault-ocr-service/blob/main/README.md)

2. Review logs for all services:
   ```bash
   docker-compose logs --tail=100 -f
   ```

3. Open an issue in the appropriate repository

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines, including:
- Code style and standards
- Pull request process
- Testing requirements
- Code review expectations

## License

This project is licensed under the MIT License.

## Related Documentation

- [CLAUDE.md](CLAUDE.md) - Guidance for AI assistants working with this codebase
- [Backend Documentation](https://github.com/private-doc-vault/docvault-backend)
- [Frontend Documentation](https://github.com/private-doc-vault/docvault-frontend)
- [OCR Service Documentation](https://github.com/private-doc-vault/docvault-ocr-service)
