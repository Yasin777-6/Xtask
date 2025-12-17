#!/bin/bash

###############################################################################
# Xtask Full-Stack Deployment Script for Ubuntu VPS
# This script automates the deployment of Django backend and React frontend
###############################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables (modify these as needed)
PROJECT_NAME="xtask"
PROJECT_DIR="/var/www/${PROJECT_NAME}"
BACKEND_DIR="${PROJECT_DIR}"  # Django files are in project root
FRONTEND_DIR="${PROJECT_DIR}/frontend"
DOMAIN_NAME=""  # Set your domain name here, or leave empty for IP-based
EMAIL=""  # For Let's Encrypt SSL
GIT_REPO="https://github.com/Yasin777-6/Xtask.git"  # Git repository URL

# User configuration
APP_USER="www-data"
PYTHON_VERSION="3.10"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Xtask Full-Stack Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Update system
print_info "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install essential packages
print_info "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    supervisor \
    nginx \
    python3-pip \
    python3-venv \
    python3-dev \
    libpq-dev \
    postgresql \
    postgresql-contrib \
    certbot \
    python3-certbot-nginx

# Install Node.js 18.x
print_info "Installing Node.js 18.x..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# Verify installations
print_info "Verifying installations..."
python3 --version
node --version
npm --version
nginx -v

# Create project directory
print_info "Creating project directory..."
mkdir -p ${PROJECT_DIR}
mkdir -p ${FRONTEND_DIR}
mkdir -p /var/log/${PROJECT_NAME}

# Create application user if it doesn't exist
if ! id "$APP_USER" &>/dev/null; then
    print_info "Creating application user..."
    useradd -r -s /bin/bash -d ${PROJECT_DIR} ${APP_USER}
fi

# Set permissions
chown -R ${APP_USER}:${APP_USER} ${PROJECT_DIR}
chmod -R 755 ${PROJECT_DIR}

# Clone or copy project files
print_info "Setting up project files..."
if [ -n "$GIT_REPO" ]; then
    print_info "Cloning from Git repository..."
    if [ -d "${PROJECT_DIR}/.git" ]; then
        print_info "Repository already exists, pulling latest changes..."
        cd ${PROJECT_DIR}
        git pull origin main
    else
        print_info "Cloning repository..."
        git clone ${GIT_REPO} ${PROJECT_DIR}
    fi
else
    print_warning "No Git repository specified. Please copy your project files to ${PROJECT_DIR}"
    print_info "Waiting 10 seconds for you to copy files..."
    sleep 10
fi

# Backend Setup
print_info "Setting up Django backend..."

# Navigate to project directory
cd ${PROJECT_DIR}

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
print_info "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Install additional production dependencies
pip install gunicorn psycopg2-binary

# Create .env file for backend
print_info "Creating backend environment file..."
cat > ${PROJECT_DIR}/.env << EOF
DEBUG=False
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
ALLOWED_HOSTS=${DOMAIN_NAME:-13.60.60.1},localhost,127.0.0.1
DATABASE_URL=postgresql://${PROJECT_NAME}_user:${PROJECT_NAME}_pass@localhost/${PROJECT_NAME}_db
CORS_ALLOWED_ORIGINS=http://${DOMAIN_NAME:-13.60.60.1},https://${DOMAIN_NAME:-13.60.60.1}
EOF

# Update Django settings if needed
print_info "Updating Django settings for production..."
# Note: You may need to manually update settings.py to read from .env

# Run migrations
print_info "Running database migrations..."
${PROJECT_DIR}/venv/bin/python manage.py migrate --noinput

# Collect static files
print_info "Collecting static files..."
${PROJECT_DIR}/venv/bin/python manage.py collectstatic --noinput

# Create superuser (optional, commented out)
# print_info "Creating superuser..."
# sudo -u ${APP_USER} ${BACKEND_DIR}/venv/bin/python manage.py createsuperuser

# Frontend Setup
print_info "Setting up React frontend..."

# Install Node dependencies
print_info "Installing Node.js dependencies..."
cd ${FRONTEND_DIR}
npm install

# Create .env file for frontend
print_info "Creating frontend environment file..."
cat > ${FRONTEND_DIR}/.env << EOF
VITE_API_URL=http://${DOMAIN_NAME:-13.60.60.1}/api
EOF

# Build frontend
print_info "Building React frontend for production..."
npm run build

# Set permissions
chown -R ${APP_USER}:${APP_USER} ${PROJECT_DIR}

# Database Setup
print_info "Setting up PostgreSQL database..."
sudo -u postgres psql << EOF
CREATE DATABASE ${PROJECT_NAME}_db;
CREATE USER ${PROJECT_NAME}_user WITH PASSWORD '${PROJECT_NAME}_pass';
ALTER ROLE ${PROJECT_NAME}_user SET client_encoding TO 'utf8';
ALTER ROLE ${PROJECT_NAME}_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE ${PROJECT_NAME}_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE ${PROJECT_NAME}_db TO ${PROJECT_NAME}_user;
\q
EOF

# Create Gunicorn systemd service
print_info "Creating Gunicorn systemd service..."
cat > /etc/systemd/system/${PROJECT_NAME}.service << EOF
[Unit]
Description=${PROJECT_NAME} Gunicorn daemon
After=network.target

[Service]
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${PROJECT_DIR}
Environment="PATH=${PROJECT_DIR}/venv/bin"
ExecStart=${PROJECT_DIR}/venv/bin/gunicorn \\
    --workers 3 \\
    --bind 127.0.0.1:8000 \\
    --access-logfile /var/log/${PROJECT_NAME}/access.log \\
    --error-logfile /var/log/${PROJECT_NAME}/error.log \\
    xtask.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# Create Nginx configuration
print_info "Creating Nginx configuration..."
cat > /etc/nginx/sites-available/${PROJECT_NAME} << EOF
# Backend API
upstream ${PROJECT_NAME}_backend {
    server 127.0.0.1:8000;
}

# Frontend
server {
    listen 80;
    server_name ${DOMAIN_NAME:-13.60.60.1};

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Frontend static files
    location / {
        root ${FRONTEND_DIR}/dist;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Backend API
    location /api {
        proxy_pass http://${PROJECT_NAME}_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # CORS headers (if needed)
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PATCH, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        
        if (\$request_method = OPTIONS) {
            return 204;
        }
    }

    # Django admin static files
    location /static/ {
        alias ${PROJECT_DIR}/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Django admin media files (if needed)
    location /media/ {
        alias ${PROJECT_DIR}/media/;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable Nginx site
ln -sf /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
print_info "Testing Nginx configuration..."
nginx -t

# Configure firewall
print_info "Configuring firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Start and enable services
print_info "Starting services..."
systemctl daemon-reload
systemctl enable ${PROJECT_NAME}
systemctl start ${PROJECT_NAME}
systemctl restart nginx

# SSL Certificate (if domain is set)
if [ -n "$DOMAIN_NAME" ] && [ -n "$EMAIL" ]; then
    print_info "Setting up SSL certificate with Let's Encrypt..."
    certbot --nginx -d ${DOMAIN_NAME} --non-interactive --agree-tos --email ${EMAIL}
    systemctl restart nginx
fi

# Print summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Project Information:${NC}"
echo "  Project Directory: ${PROJECT_DIR}"
echo "  Backend Directory: ${BACKEND_DIR}"
echo "  Frontend Directory: ${FRONTEND_DIR}"
echo ""
echo -e "${BLUE}Service URLs:${NC}"
if [ -n "$DOMAIN_NAME" ]; then
    echo "  Frontend: http://${DOMAIN_NAME}"
    echo "  Backend API: http://${DOMAIN_NAME}/api"
else
    echo "  Frontend: http://13.60.60.1"
    echo "  Backend API: http://13.60.60.1/api"
fi
echo ""
echo -e "${BLUE}Service Management:${NC}"
echo "  Start:   systemctl start ${PROJECT_NAME}"
echo "  Stop:    systemctl stop ${PROJECT_NAME}"
echo "  Restart: systemctl restart ${PROJECT_NAME}"
echo "  Status:  systemctl status ${PROJECT_NAME}"
echo "  Logs:    journalctl -u ${PROJECT_NAME} -f"
echo ""
echo -e "${BLUE}Database Information:${NC}"
echo "  Database: ${PROJECT_NAME}_db"
echo "  User: ${PROJECT_NAME}_user"
echo "  Password: ${PROJECT_NAME}_pass"
echo ""
print_warning "IMPORTANT: Change the database password in production!"
print_warning "Update Django settings.py to use environment variables"
print_warning "Set up proper SECRET_KEY in .env file"
echo ""
print_success "Deployment completed successfully!"

