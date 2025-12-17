#!/bin/bash

# Fix permissions and deploy script
# This script handles the permission dance correctly

set -e

PROJECT_DIR="/var/www/xtask"
APP_USER="www-data"
CURRENT_USER=$(whoami)

echo "========================================="
echo "Fix Permissions and Deploy"
echo "========================================="

# Step 1: Change ownership to current user for Git operations
echo "[1/8] Changing ownership to $CURRENT_USER for Git operations..."
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/.git

# Step 2: Fix Git safe directory
echo "[2/8] Configuring Git..."
sudo git config --global --add safe.directory $PROJECT_DIR
git config --global --add safe.directory $PROJECT_DIR

# Step 3: Stash and pull
echo "[3/8] Pulling latest code..."
cd $PROJECT_DIR
git stash || true
git pull origin main || {
    echo "Git pull failed. Trying to reset..."
    git fetch origin
    git reset --hard origin/main
}

# Step 4: Change ownership back to www-data for application files
echo "[4/8] Changing ownership to $APP_USER for application..."
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR

# But keep .git accessible to current user for future pulls
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/.git

# Step 5: Ensure db directory exists with correct permissions
echo "[5/8] Setting up database directory..."
sudo mkdir -p $PROJECT_DIR/db
sudo chown $APP_USER:$APP_USER $PROJECT_DIR/db
sudo chmod 775 $PROJECT_DIR/db

# Step 6: Run migrations
echo "[6/8] Running migrations..."
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py makemigrations --noinput || true
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py migrate --noinput

# Step 7: Collect static files
echo "[7/8] Collecting static files..."
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py collectstatic --noinput

# Step 8: Rebuild frontend if needed
echo "[8/8] Building frontend..."
cd $PROJECT_DIR/frontend

# Temporarily change ownership for npm operations
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/frontend

# Build
if [ ! -f ".env" ]; then
    echo "VITE_API_URL=/api" > .env
fi
npm run build

# Change ownership back
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR/frontend/dist

# Step 9: Update Nginx config
echo "[9/9] Configuring Nginx..."
sudo cp $PROJECT_DIR/nginx-xtask.conf /etc/nginx/sites-available/xtask
sudo ln -sf /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# Step 10: Update systemd service
echo "[10/10] Configuring systemd service..."
sudo cp $PROJECT_DIR/xtask.service /etc/systemd/system/xtask.service
sudo mkdir -p /var/log/xtask
sudo chown $APP_USER:$APP_USER /var/log/xtask
sudo systemctl daemon-reload

# Step 11: Restart services
echo "Restarting services..."
sudo systemctl restart xtask
sudo systemctl enable xtask
sleep 2
sudo systemctl restart nginx

# Step 12: Verify
echo ""
echo "========================================="
echo "Deployment completed!"
echo "========================================="
echo ""
echo "Checking service status..."
sudo systemctl status xtask --no-pager -l | head -20
echo ""
echo "Testing API..."
curl -s http://localhost/api/tasks/ || echo "API test failed"
echo ""
echo "Checking backend directly..."
curl -s http://localhost:8000/api/tasks/ || echo "Direct backend test failed"
echo ""
echo "If you see errors, check logs:"
echo "  sudo journalctl -u xtask -n 50"
echo "  sudo tail -n 50 /var/log/nginx/error.log"
echo ""

