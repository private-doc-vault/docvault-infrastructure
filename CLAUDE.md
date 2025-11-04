# CLAUDE.md - DocVault Infrastructure

This file provides guidance to Claude Code (claude.ai/code) when working with the DocVault infrastructure repository.

## Multi-Repository Structure

**IMPORTANT**: DocVault uses a multi-repository architecture. This repository (`docvault-infrastructure`) is the **infrastructure and orchestration** repository that ties together three service repositories using git submodules.

### Repository Organization

1. **docvault-infrastructure** (this repository)
   - Docker Compose configurations (production & development)
   - Git submodules for all services
   - Shared configuration (Nginx, PostgreSQL, Redis, Meilisearch)
   - Setup scripts and documentation
   - Integration tests

2. **docvault-backend** - [https://github.com/private-doc-vault/docvault-backend](https://github.com/private-doc-vault/docvault-backend)
   - Symfony 7.3 PHP backend
   - REST API endpoints
   - Database models and migrations
   - Standalone repository with own CI/CD

3. **docvault-frontend** - [https://github.com/private-doc-vault/docvault-frontend](https://github.com/private-doc-vault/docvault-frontend)
   - React 19 + Redux Toolkit SPA
   - Vite build tooling
   - Standalone repository with own CI/CD

4. **docvault-ocr-service** - [https://github.com/private-doc-vault/docvault-ocr-service](https://github.com/private-doc-vault/docvault-ocr-service)
   - Python FastAPI OCR service
   - Tesseract OCR integration
   - Redis queue worker
   - Standalone repository with own CI/CD

### Git Submodules Workflow

Services are included as git submodules in `services/` directory:
- `services/backend/` → docvault-backend repository
- `services/frontend/` → docvault-frontend repository
- `services/ocr-service/` → docvault-ocr-service repository

**Initial Setup:**
Run the setup script to initialize the environment and install dependencies:
```bash
./setup.sh
```
The setup script will:
- Validate Docker installation
- Initialize git submodules automatically
- Create required storage directories
- Setup environment file from .env.example
- Optionally install all dependencies for development mode (composer, npm, pip)

**Manually initializing submodules:**
```bash
git submodule update --init --recursive
```

**Updating submodules to latest:**
```bash
git submodule update --remote
```

**Working on a service:**
```bash
cd services/backend
git checkout -b feature/my-feature
# Make changes, commit, push
# Create PR in the backend repository
```

### Development Modes

**Production Mode** (`docker-compose.yml`):
- Uses published Docker images from GitHub Container Registry (ghcr.io)
- Suitable for deployment and testing with stable versions
- No local source code changes

**Development Mode** (`docker-compose.dev.yml`):
- Builds from source code in submodules
- Live reload and hot module replacement
- Mounts source directories for active development
- Suitable for local development

### CI/CD Architecture

Each service repository has:
- **CI workflow**: Runs tests on PR and push to main
- **Release workflow**: Builds and publishes Docker images to ghcr.io when GitHub Release is created
- Automated submodule updates in infrastructure repo after releases

## Overview

DocVault is a document archiving and cataloging system built with:
- **Backend**: Symfony 7.3 (PHP 8.4) with PostgreSQL, Redis, and Meilisearch
- **Frontend (Primary)**: React 19 + Redux Toolkit + Vite (port 3000) - Main SPA interface
- **Frontend (Legacy)**: Symfony Twig templates + Webpack Encore - Server-rendered web interface
- **OCR Service**: Python FastAPI with Tesseract OCR, Redis queue processing
- **Infrastructure**: Docker Compose with shared storage between services

## Important: Dual Frontend Architecture

This project has TWO frontend implementations:

1. **React Frontend** (`frontend/`) - Modern SPA
   - React 19 with Redux Toolkit for state management
   - Vite for building and dev server
   - Standalone Docker container with Nginx
   - Recommended for new development
   - See `frontend/README.md` for details

2. **Symfony Web Interface** (`backend/templates/`, `backend/assets/`)
   - Server-rendered Twig templates with Bootstrap 5
   - Webpack Encore for asset compilation (JavaScript/CSS)
   - JavaScript-heavy pages that fetch data from API endpoints dynamically
   - Used for some admin and document management pages
   - Assets must be compiled before use (see Backend commands below)
   - **Key Pattern**: Templates render static HTML shell, JavaScript loads dynamic content via API calls
     - Example: `dashboard/index.html.twig` renders empty containers, `assets/js/dashboard.js` populates with data from `/api/admin/stats` and `/api/documents`
     - If JavaScript fails to load data, pages appear with only header/footer (common issue when API endpoints are missing)

## Architecture

### Multi-Service Architecture

1. **Symfony Backend** (backend/)
   - REST API and web interface
   - Document management and metadata
   - User authentication (JWT + session-based)
   - Role-based access control (RBAC) with DocumentVoter and PermissionVoter
   - Async message processing via Symfony Messenger

2. **Python OCR Service** (ocr-service/)
   - FastAPI REST API for OCR processing
   - Redis-based task queue with priority support (high/normal/low)
   - Background worker process for OCR tasks
   - Webhook notifications to backend on completion/failure/progress
   - Metadata extraction and document categorization

3. **Infrastructure Services**
   - PostgreSQL: Primary data store
   - Redis: Queue management and caching
   - Meilisearch: Full-text search indexing
   - Nginx: Reverse proxy

### Communication Flow

1. **Document Upload**: User uploads � Backend stores file � Backend dispatches ProcessDocumentMessage
2. **OCR Processing**: Backend MessageHandler calls OCR API � OCR enqueues task � Worker processes � Worker sends webhook to backend
3. **Status Updates**: Backend receives webhooks � Updates document status � Logs audit trail
4. **Search**: Backend syncs to Meilisearch via IndexDocumentMessage

### Key Design Patterns

- **Shared Storage**: `/var/www/html/storage/documents` mounted in both backend and OCR containers for file access
- **Webhook Architecture**: OCR service sends completion/failure/progress webhooks to backend endpoint `/api/webhooks/ocr-status`
- **Circuit Breaker**: Protects OCR API calls with automatic failure detection and recovery
- **Idempotency**: Prevents duplicate processing using IdempotencyService
- **Error Categorization**: Distinguishes transient vs permanent errors for retry logic
- **Dual-track Processing**: Backend uses both Symfony Messenger and direct OCR API calls with fallback

## Common Commands

### Docker Operations
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f backend
docker-compose logs -f ocr-service

# Restart specific service
docker-compose restart backend
docker-compose restart ocr-service

# Execute commands in containers
docker-compose exec backend bash
docker-compose exec ocr-service bash
```

### Backend (Symfony)

**Note**: Commands are run from the backend service repository (`services/backend/` in development mode)

```bash
# Install dependencies
cd services/backend && composer install
npm install  # For Webpack Encore assets

# Compile frontend assets (IMPORTANT: Required for web interface to work)
npm run build          # Production build
npm run dev            # Development build
npm run watch          # Development build with file watching

# Run all tests
composer test
# or from backend directory:
vendor/bin/phpunit

# Run specific test
vendor/bin/phpunit tests/Functional/Api/DocumentProcessingStatusApiTest.php

# Database operations
php bin/console doctrine:migrations:migrate
php bin/console doctrine:fixtures:load

# Clear cache
php bin/console cache:clear

# Debug routes
php bin/console debug:router           # List all routes
php bin/console debug:router app_dashboard  # Details for specific route

# Run message consumer (queue worker)
php bin/console messenger:consume async --time-limit=3600 --memory-limit=256M

# Maintenance commands
php bin/console app:cleanup-orphaned-files  # Remove orphaned files
php bin/console app:cleanup-stuck-tasks     # Clean stuck processing tasks
php bin/console app:reindex-documents       # Rebuild Meilisearch index
```

### OCR Service (Python)

**Note**: Commands are run from the OCR service repository (`services/ocr-service/` in development mode)

```bash
# Install dependencies
cd services/ocr-service && pip install -r requirements.txt

# Run tests
docker-compose exec ocr-service pytest
docker-compose exec ocr-service pytest tests/test_webhook_client.py -v

# Run with coverage
docker-compose exec ocr-service pytest --cov=app

# Run API server
docker-compose exec ocr-service uvicorn app.main:app --host 0.0.0.0 --port 8000

# Run worker process
docker-compose exec ocr-service python -m app.worker
```

### Frontend (React)

**Note**: Commands are run from the frontend service repository (`services/frontend/` in development mode)

```bash
# Install dependencies
cd services/frontend && npm install

# Development server (with hot reload)
npm run dev              # Runs at http://localhost:5173

# Production build
npm run build            # Outputs to dist/

# Run tests
npm test                 # Run all tests
npm test:watch          # Run tests in watch mode
npm test:coverage       # Run with coverage report (70% minimum)

# Code quality
npm run lint            # Run ESLint
npm run format          # Format with Prettier
npm run format:check    # Check formatting without changes
```

## Critical File Locations

### Backend
- **Web Controllers**: `backend/src/Controller/Web/` - Twig template controllers (DashboardController, SecurityController)
- **API Controllers**: `backend/src/Controller/Api/` - REST API endpoints
- **Message Handlers**: `backend/src/MessageHandler/` - Async message processing
- **Document Processing**: `backend/src/Service/DocumentProcessingService.php` - Core orchestration
- **OCR Integration**: `backend/src/Service/OcrApiClient.php` - OCR service communication with circuit breaker
- **Webhook Endpoint**: `backend/src/Controller/Api/OcrWebhookController.php` - Receives OCR completion notifications
- **Security**: `backend/src/Security/Voter/` - Permission checking (DocumentVoter, PermissionVoter)
- **Storage**: `backend/src/Service/DocumentStorageService.php` - File management
- **Twig Templates**: `backend/templates/` - Server-rendered HTML templates
- **JavaScript Assets**: `backend/assets/js/` - Frontend JavaScript for Twig pages
- **Webpack Config**: `backend/webpack.config.js` - Asset compilation configuration

### Frontend (React)
- **Pages**: `frontend/src/pages/` - Page components (LoginPage, DashboardPage, etc.)
- **Components**: `frontend/src/components/` - Reusable UI components
- **Redux Slices**: `frontend/src/features/` - State management slices
- **API Client**: `frontend/src/api/apiClient.js` - Axios instance with interceptors
- **Routes**: `frontend/src/routes/` - React Router configuration
- **Test Utils**: `frontend/src/test-utils/` - Testing helpers and mock data

### OCR Service
- **Worker**: `ocr-service/app/worker.py` - Background task processor with webhook notifications
- **Queue**: `ocr-service/app/redis_queue.py` - Redis queue manager with priority support
- **OCR**: `ocr-service/app/ocr_service.py` - Tesseract OCR integration
- **Webhook Client**: `ocr-service/app/webhook_client.py` - Backend notification with HMAC signing
- **API**: `ocr-service/app/routes.py` - REST API endpoints

## Testing Strategy

### Backend Tests
- Located in `backend/tests/`
- Use PHPUnit with Symfony test framework
- Functional tests verify API endpoints and workflows
- Run with `composer test` or `vendor/bin/phpunit`

### OCR Service Tests
- Located in `ocr-service/tests/`
- Use pytest with async support
- Mock Redis and HTTP calls with respx
- Integration tests in `tests/integration/`
- Run with `docker-compose exec ocr-service pytest`

## Environment Configuration

- Backend: Uses `.env` with DATABASE_URL, REDIS_URL, OCR_SERVICE_URL, JWT secrets
- OCR Service: Uses environment variables from docker-compose.yml
- Shared secrets: `OCR_WEBHOOK_SECRET` must match between services for HMAC verification

## Storage Paths

- **Shared Documents**: `/var/www/html/storage/documents` (accessible by both backend and OCR)
- **Temp Storage**: `/var/www/html/storage/temp` (backend) and `/app/temp` (OCR)
- **Backend manages file lifecycle**: Files are NOT deleted by OCR service after processing

## Security Notes

- JWT authentication for API endpoints (`/api/*`)
- Session-based auth for web interface
- HMAC-signed webhooks between OCR and backend
- Document-level permissions via DocumentVoter
- Permission-based access control via PermissionVoter
- Rate limiting on API endpoints

## Message Queue Architecture

### Symfony Messenger
- **async transport**: General async processing (ProcessDocumentMessage, UpdateProcessingStatusMessage)
- **async_indexing transport**: Meilisearch indexing with enhanced retry (5 retries, exponential backoff)
- **Retry strategy**: Exponential backoff for transient failures
- **Worker**: Runs via `messenger:consume async` command

### Redis Queue (OCR)
- **Priority levels**: high, normal, low (processed in order)
- **Task metadata**: Stored in Redis with task_id as key
- **Result storage**: OCR results stored in Redis with configurable TTL
- **Progress tracking**: Redis-based progress history for task monitoring

## Development Workflow

1. **Adding new document processing step**:
   - Update `DocumentProcessingService` orchestration
   - Modify OCR worker pipeline in `worker.py`
   - Add webhook payload fields if needed
   - Update tests in both backend and OCR service

2. **Adding new API endpoint**:
   - Create controller in `backend/src/Controller/Api/`
   - Add security annotations or access control
   - Update OpenAPI documentation via annotations
   - Add functional tests

3. **Modifying OCR pipeline**:
   - Update worker stages in `worker.py`
   - Adjust progress percentages for accurate tracking
   - Add corresponding tests in `tests/`
   - Update webhook notifications if status changes

## Common Debugging Approaches

- **Symfony web interface shows only header/footer**:
  - Run `npm run build` in `backend/` directory to compile assets
  - Check `backend/public/build/` for compiled files
  - Verify JavaScript console for API errors
  - Missing API endpoints will cause blank pages (check routes with `php bin/console debug:router`)

- **React frontend API errors**:
  - Verify `VITE_API_URL` is set correctly (`.env.development` or `.env.production`)
  - Check browser console and Network tab
  - Ensure backend is running and accessible
  - Check CORS settings if accessing backend directly

- **Queue issues**: Check Redis with `docker-compose exec redis redis-cli` then `AUTH redis_pass` and `KEYS *`

- **OCR failures**: Check worker logs at `/app/logs/worker.log` in OCR container

- **Backend processing**: Check Symfony logs in `backend/var/log/`

- **Webhook failures**: Check backend logs for webhook reception and OCR logs for webhook delivery

- **File access issues**: Verify shared storage mount and permissions

- **Asset compilation issues**:
  - Clear Webpack cache: `rm -rf backend/node_modules/.cache`
  - Rebuild: `npm install && npm run build` in `backend/`
  - Check for JavaScript errors in compiled files
