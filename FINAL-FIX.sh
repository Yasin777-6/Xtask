#!/bin/bash

# Final fix script for all remaining issues
# Run this on your Ubuntu VPS server

set -e

PROJECT_DIR="/var/www/xtask"
APP_USER="www-data"

echo "========================================="
echo "Final Fix Script"
echo "========================================="

# Step 1: Fix Git permissions
echo "[1/7] Fixing Git permissions..."
cd $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR/.git
sudo git config --global --add safe.directory $PROJECT_DIR

# Step 2: Pull latest code
echo "[2/7] Pulling latest code..."
git stash || true
git pull origin main

# Step 3: Fix project ownership
echo "[3/7] Fixing project ownership..."
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR

# Step 4: Ensure db directory exists
echo "[4/7] Ensuring database directory exists..."
sudo mkdir -p $PROJECT_DIR/db
sudo chown $APP_USER:$APP_USER $PROJECT_DIR/db
sudo chmod 775 $PROJECT_DIR/db

# Step 5: Run migrations
echo "[5/7] Running migrations..."
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py makemigrations --noinput || true
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py migrate --noinput

# Step 6: Verify frontend dist exists
echo "[6/7] Verifying frontend build..."
if [ ! -d "$PROJECT_DIR/frontend/dist" ] || [ -z "$(ls -A $PROJECT_DIR/frontend/dist)" ]; then
    echo "Frontend dist is missing or empty. Rebuilding..."
    cd $PROJECT_DIR/frontend
    sudo chown -R $USER:$USER $PROJECT_DIR/frontend
    sudo rm -rf node_modules
    npm install
    if [ ! -f ".env" ]; then
        echo "VITE_API_URL=/api" > .env
    fi
    npm run build
    sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR/frontend/dist
else
    echo "Frontend dist exists and is not empty."
fi

# Step 7: Update Nginx config and restart services
echo "[7/7] Updating Nginx and restarting services..."
sudo cp $PROJECT_DIR/nginx-xtask.conf /etc/nginx/sites-available/xtask
sudo ln -sf /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# Update systemd service
sudo cp $PROJECT_DIR/xtask.service /etc/systemd/system/xtask.service
sudo mkdir -p /var/log/xtask
sudo chown $APP_USER:$APP_USER /var/log/xtask
sudo systemctl daemon-reload

# Restart services
sudo systemctl restart xtask
sudo systemctl enable xtask
sudo systemctl restart nginx

echo ""
echo "========================================="
echo "Fix completed!"
echo "========================================="
echo ""
echo "Verifying services..."
sudo systemctl status xtask --no-pager -l | head -15
echo ""
echo "Testing API..."
curl -s http://localhost/api/tasks/ | head -20
echo ""
echo "Check if frontend dist exists:"
ls -la $PROJECT_DIR/frontend/dist/ | head -10
echo ""
echo "If you see errors, check logs:"
echo "  sudo journalctl -u xtask -n 50"
echo "  sudo tail -n 50 /var/log/nginx/error.log"
echo ""

