#!/bin/bash
# DocVault Infrastructure Setup Script
# This script initializes the development environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup function
main() {
    print_header "DocVault Infrastructure Setup"

    # Step 1: Validate Docker installation
    print_info "Validating Docker installation..."

    if ! command_exists docker; then
        print_error "Docker is not installed!"
        echo "Please install Docker from https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running!"
        echo "Please start Docker and try again."
        exit 1
    fi

    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_success "Docker is installed and running (version: $DOCKER_VERSION)"

    # Check Docker Compose
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed!"
        echo "Please install Docker Compose from https://docs.docker.com/compose/install/"
        exit 1
    fi

    print_success "Docker Compose is available"

    # Step 2: Initialize git submodules
    print_header "Initializing Git Submodules"

    if [ -d ".git" ]; then
        print_info "Updating git submodules..."

        if git submodule update --init --recursive; then
            print_success "Git submodules initialized successfully"

            # Show submodule status
            echo ""
            print_info "Submodule status:"
            git submodule status
            echo ""
        else
            print_error "Failed to initialize git submodules"
            exit 1
        fi
    else
        print_warning "Not a git repository - skipping submodule initialization"
        print_info "If you cloned without --recursive, run: git submodule update --init --recursive"
    fi

    # Step 3: Create storage directories
    print_header "Creating Storage Directories"

    STORAGE_DIRS=(
        "storage/documents"
        "storage/temp"
        "storage/logs/ocr"
        "storage/logs/backend"
    )

    for dir in "${STORAGE_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        else
            print_info "Directory already exists: $dir"
        fi
    done

    # Set appropriate permissions
    if command_exists chmod; then
        chmod -R 775 storage 2>/dev/null || true
        print_success "Set permissions on storage directories"
    fi

    # Step 4: Setup environment file
    print_header "Setting Up Environment File"

    if [ -f ".env" ]; then
        print_warning ".env file already exists - skipping"
        print_info "To reset, delete .env and run this script again"
    else
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Created .env from .env.example"
            echo ""
            print_warning "IMPORTANT: Edit .env and update the following:"
            print_warning "  - APP_SECRET (random 32+ character string)"
            print_warning "  - POSTGRES_PASSWORD"
            print_warning "  - REDIS_PASSWORD"
            print_warning "  - MEILISEARCH_KEY"
            print_warning "  - OCR_WEBHOOK_SECRET (must match backend, 32+ chars)"
            print_warning "  - JWT_PASSPHRASE"
            echo ""
        else
            print_error ".env.example not found!"
            exit 1
        fi
    fi

    # Step 5: Validate configuration files
    print_header "Validating Configuration Files"

    CONFIG_FILES=(
        "docker-compose.yml:Production compose file"
        "docker-compose.dev.yml:Development compose file"
        "nginx/nginx.conf:Nginx production config"
        "nginx/nginx-dev.conf:Nginx development config"
        "postgres/init-db.sql:PostgreSQL init script"
        "redis/redis.conf:Redis configuration"
    )

    for config in "${CONFIG_FILES[@]}"; do
        file="${config%%:*}"
        desc="${config##*:}"

        if [ -f "$file" ]; then
            print_success "$desc found"
        else
            print_error "$desc missing: $file"
        fi
    done

    # Step 6: Install dependencies for development mode
    print_header "Installing Dependencies for Development Mode"

    # Ask user if they want to install dependencies
    echo ""
    read -p "Do you want to install dependencies for development mode? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Starting dependency installation..."
        echo ""

        # Build and start base services first
        print_info "Building and starting infrastructure services..."
        if docker compose -f docker-compose.dev.yml up -d postgres redis meilisearch 2>&1 | grep -v "attribute.*version.*is obsolete" | grep -v "variable is not set"; then
            print_success "Infrastructure services started"
        else
            print_warning "Some infrastructure services may have issues, continuing..."
        fi

        echo ""
        print_info "Waiting for services to be ready (10 seconds)..."
        sleep 10

        # Install backend dependencies
        if [ -f "services/backend/composer.json" ]; then
            print_info "Installing backend dependencies (PHP/Composer)..."

            # Build backend image first
            if docker compose -f docker-compose.dev.yml build backend 2>&1 | grep -v "attribute.*version.*is obsolete" | grep -v "variable is not set"; then
                print_success "Backend image built"

                # Start backend temporarily to install dependencies
                docker compose -f docker-compose.dev.yml up -d backend 2>&1 | grep -v "attribute.*version.*is obsolete" | grep -v "variable is not set"

                echo ""
                print_info "Running composer install (this may take a few minutes)..."
                if docker compose -f docker-compose.dev.yml exec -T backend composer install --no-interaction --prefer-dist 2>&1 | tail -5; then
                    print_success "Backend dependencies installed"
                else
                    print_warning "Backend dependency installation had issues, but continuing..."
                fi
            else
                print_warning "Failed to build backend image, skipping dependency installation"
            fi
        else
            print_warning "Backend composer.json not found - skipping"
        fi

        echo ""

        # Install frontend dependencies
        if [ -f "services/frontend/package.json" ]; then
            print_info "Installing frontend dependencies (Node.js/npm)..."

            # Build frontend image
            if docker compose -f docker-compose.dev.yml build frontend 2>&1 | grep -v "attribute.*version.*is obsolete" | grep -v "variable is not set"; then
                print_success "Frontend image built"

                # Start frontend temporarily to install dependencies
                docker compose -f docker-compose.dev.yml up -d frontend 2>&1 | grep -v "attribute.*version.*is obsolete" | grep -v "variable is not set"

                echo ""
                print_info "Running npm install (this may take a few minutes)..."
                if docker compose -f docker-compose.dev.yml exec -T frontend npm install 2>&1 | tail -5; then
                    print_success "Frontend dependencies installed"
                else
                    print_warning "Frontend dependency installation had issues, but continuing..."
                fi
            else
                print_warning "Failed to build frontend image, skipping dependency installation"
            fi
        else
            print_warning "Frontend package.json not found - skipping"
        fi

        echo ""

        # Install OCR service dependencies
        if [ -f "services/ocr-service/requirements.txt" ]; then
            print_info "Installing OCR service dependencies (Python/pip)..."

            # Build OCR service image
            if docker compose -f docker-compose.dev.yml build ocr-service 2>&1 | grep -v "attribute.*version.*is obsolete" | grep -v "variable is not set"; then
                print_success "OCR service image built"

                # Dependencies are installed during image build, so just verify
                print_success "OCR service dependencies included in image"
            else
                print_warning "Failed to build OCR service image, skipping dependency installation"
            fi
        else
            print_warning "OCR service requirements.txt not found - skipping"
        fi

        echo ""
        print_success "Dependency installation complete!"

        # Stop all services
        print_info "Stopping services..."
        docker compose -f docker-compose.dev.yml down 2>&1 | grep -v "attribute.*version.*is obsolete" | grep -v "variable is not set" > /dev/null
        print_success "Services stopped"
    else
        print_info "Skipping dependency installation"
        print_warning "You will need to install dependencies manually before starting containers"
    fi

    # Step 7: Summary and next steps
    print_header "Setup Complete!"

    echo -e "${GREEN}✓${NC} Docker and Docker Compose are installed"
    echo -e "${GREEN}✓${NC} Git submodules initialized"
    echo -e "${GREEN}✓${NC} Storage directories created"
    echo -e "${GREEN}✓${NC} Environment file created"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓${NC} Development dependencies installed"
    fi
    echo ""

    print_header "Next Steps"

    echo "1. Edit the .env file and update all secret values:"
    echo "   ${BLUE}nano .env${NC} or ${BLUE}vim .env${NC}"
    echo ""
    echo "2. For development mode (builds from source):"
    echo "   ${BLUE}docker compose -f docker-compose.dev.yml up -d${NC}"
    echo ""
    echo "3. For production mode (uses published images):"
    echo "   ${BLUE}docker compose up -d${NC}"
    echo ""
    echo "4. Check service status:"
    echo "   ${BLUE}docker compose ps${NC}"
    echo ""
    echo "5. View logs:"
    echo "   ${BLUE}docker compose logs -f [service-name]${NC}"
    echo ""
    echo "6. Access the application:"
    echo "   - Frontend: ${BLUE}http://localhost${NC}"
    echo "   - Backend API: ${BLUE}http://localhost/api${NC}"
    echo "   - React Dev Server: ${BLUE}http://localhost:5173${NC}"
    echo "   - Meilisearch: ${BLUE}http://localhost:7700${NC}"
    echo "   - OCR Service: ${BLUE}http://localhost:8001${NC}"
    echo ""

    print_info "For more information, see README.md"
    echo ""
}

# Run main function
main "$@"
