#!/bin/bash

# Complete fix script - handles all issues
set -e

PROJECT_DIR="/var/www/xtask"
APP_USER="www-data"
CURRENT_USER=$(whoami)

echo "========================================="
echo "Complete Fix Script"
echo "========================================="

# Step 1: Fix ownership for Git
echo "[1/9] Fixing Git permissions..."
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/.git
git config --global --add safe.directory $PROJECT_DIR

# Step 2: Pull latest code
echo "[2/9] Pulling latest code..."
cd $PROJECT_DIR
git stash || true
git pull origin main || {
    echo "Git pull failed, trying hard reset..."
    git fetch origin
    git reset --hard origin/main
}

# Step 3: Fix ownership for application
echo "[3/9] Setting application ownership..."
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR
# Keep .git for user
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/.git

# Step 4: Ensure db directory exists
echo "[4/9] Setting up database directory..."
sudo mkdir -p $PROJECT_DIR/db
sudo chown $APP_USER:$APP_USER $PROJECT_DIR/db
sudo chmod 775 $PROJECT_DIR/db

# Step 5: Run migrations
echo "[5/9] Running database migrations..."
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py makemigrations --noinput || true
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py migrate --noinput

# Verify migrations
echo "Verifying database..."
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py shell -c "
from tasks.models import Task
print(f'Database OK. Task count: {Task.objects.count()}')
" || echo "Database verification failed"

# Step 6: Collect static files
echo "[6/9] Collecting static files..."
sudo -u $APP_USER $PROJECT_DIR/venv/bin/python manage.py collectstatic --noinput

# Step 7: Build frontend
echo "[7/9] Building frontend..."
cd $PROJECT_DIR/frontend
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/frontend
if [ ! -f ".env" ]; then
    echo "VITE_API_URL=/api" > .env
fi
npm run build
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR/frontend/dist

# Step 8: Configure Nginx
echo "[8/9] Configuring Nginx..."
sudo cp $PROJECT_DIR/nginx-xtask.conf /etc/nginx/sites-available/xtask
sudo ln -sf /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# Step 9: Configure and restart services
echo "[9/9] Configuring systemd service..."
sudo cp $PROJECT_DIR/xtask.service /etc/systemd/system/xtask.service
sudo mkdir -p /var/log/xtask
sudo chown $APP_USER:$APP_USER /var/log/xtask
sudo systemctl daemon-reload

# Stop service first
sudo systemctl stop xtask || true
sleep 2

# Start service
sudo systemctl start xtask
sleep 3

# Check if it's running
if sudo systemctl is-active --quiet xtask; then
    echo "✓ Backend service is running"
else
    echo "✗ Backend service failed to start. Checking logs..."
    sudo journalctl -u xtask -n 30 --no-pager
    exit 1
fi

# Enable service
sudo systemctl enable xtask

# Restart Nginx
sudo systemctl restart nginx

# Final verification
echo ""
echo "========================================="
echo "Verification"
echo "========================================="

# Test backend directly
echo "Testing backend on port 8000..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/tasks/ | grep -q "200\|404"; then
    echo "✓ Backend is responding"
    curl -s http://localhost:8000/api/tasks/ | head -3
else
    echo "✗ Backend is NOT responding"
    echo "Checking service status..."
    sudo systemctl status xtask --no-pager -l | head -20
    echo "Checking logs..."
    sudo journalctl -u xtask -n 20 --no-pager
fi

# Test through Nginx
echo ""
echo "Testing API through Nginx..."
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/tasks/ || echo "000")
if [ "$API_CODE" = "200" ] || [ "$API_CODE" = "404" ]; then
    echo "✓ API accessible through Nginx (HTTP $API_CODE)"
else
    echo "✗ API NOT accessible through Nginx (HTTP $API_CODE)"
fi

# Test frontend
echo ""
echo "Testing frontend..."
FRONTEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
if [ "$FRONTEND_CODE" = "200" ]; then
    echo "✓ Frontend accessible (HTTP $FRONTEND_CODE)"
else
    echo "✗ Frontend NOT accessible (HTTP $FRONTEND_CODE)"
fi

echo ""
echo "========================================="
echo "Fix complete!"
echo "========================================="
echo ""
echo "Your website should be accessible at: http://13.60.60.1"
echo ""
echo "If issues persist:"
echo "  sudo journalctl -u xtask -f"
echo "  sudo tail -f /var/log/nginx/error.log"
echo ""

