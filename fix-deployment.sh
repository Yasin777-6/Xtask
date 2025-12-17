#!/bin/bash

# Quick fix script for Xtask deployment issues
# Run this on your Ubuntu VPS server

set -e  # Exit on error

PROJECT_DIR="/var/www/xtask"
APP_USER="www-data"

echo "========================================="
echo "Xtask Deployment Fix Script"
echo "========================================="

# Step 1: Fix Git ownership
echo "[1/8] Fixing Git ownership..."
cd $PROJECT_DIR
sudo git config --global --add safe.directory $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR/.git

# Step 2: Pull latest code
echo "[2/8] Pulling latest code from GitHub..."
cd $PROJECT_DIR
git stash || true  # Stash any local changes
git pull origin main

# Step 3: Fix project ownership
echo "[3/8] Fixing project file ownership..."
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR

# Step 4: Create db directory with proper permissions
echo "[4/8] Creating database directory..."
sudo mkdir -p $PROJECT_DIR/db
sudo chown $APP_USER:$APP_USER $PROJECT_DIR/db
sudo chmod 775 $PROJECT_DIR/db

# Step 5: Install/update Python dependencies
echo "[5/8] Installing Python dependencies..."
cd $PROJECT_DIR
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

# Step 6: Run migrations and collect static files
echo "[6/8] Running database migrations..."
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py migrate --noinput

echo "[6/8] Collecting static files..."
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py collectstatic --noinput

# Step 7: Build frontend
echo "[7/8] Building frontend..."
cd $PROJECT_DIR/frontend

# Fix frontend ownership
sudo chown -R $USER:$USER $PROJECT_DIR/frontend

# Remove node_modules if it exists with wrong permissions
if [ -d "node_modules" ]; then
    sudo rm -rf node_modules
fi

# Install dependencies
npm install

# Create .env file for production if it doesn't exist
if [ ! -f ".env" ]; then
    echo "VITE_API_URL=/api" > .env
fi

# Build frontend
npm run build

# Fix ownership of dist directory
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR/frontend/dist

# Step 8: Configure and restart services
echo "[8/8] Configuring services..."

# Copy Nginx configuration
sudo cp $PROJECT_DIR/nginx-xtask.conf /etc/nginx/sites-available/xtask
sudo ln -sf /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Create systemd service if it doesn't exist
if [ ! -f "/etc/systemd/system/xtask.service" ]; then
    sudo cp $PROJECT_DIR/xtask.service /etc/systemd/system/xtask.service
    sudo systemctl daemon-reload
fi

# Restart services
echo "Restarting services..."
sudo systemctl restart xtask
sudo systemctl enable xtask
sudo systemctl restart nginx

# Final permissions fix
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR
sudo chmod 775 $PROJECT_DIR/db

echo ""
echo "========================================="
echo "Deployment fix completed!"
echo "========================================="
echo ""
echo "Check service status:"
echo "  sudo systemctl status xtask"
echo "  sudo systemctl status nginx"
echo ""
echo "Check logs:"
echo "  sudo journalctl -u xtask -f"
echo "  sudo tail -f /var/log/nginx/error.log"
echo ""
echo "Test your site:"
echo "  curl http://localhost/api/tasks/"
echo "  curl http://localhost/health"
echo ""

