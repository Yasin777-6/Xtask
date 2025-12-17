#!/bin/bash

# Complete fix and rebuild script
set -e

PROJECT_DIR="/var/www/xtask"
FRONTEND_DIR="$PROJECT_DIR/frontend"
APP_USER="www-data"
CURRENT_USER=$(whoami)

echo "========================================="
echo "Fix Permissions and Rebuild Frontend"
echo "========================================="

# Step 1: Change ownership to current user for Git operations
echo "[1/6] Fixing ownership for Git operations..."
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/.git

# Step 2: Pull latest code
echo "[2/6] Pulling latest code..."
cd $PROJECT_DIR
git stash || true
git pull origin main || {
    echo "Git pull failed, trying hard reset..."
    git fetch origin
    git reset --hard origin/main
}

# Step 3: Fix frontend ownership for npm
echo "[3/6] Fixing frontend ownership for npm..."
sudo chown -R $CURRENT_USER:$CURRENT_USER $FRONTEND_DIR

# Step 4: Clean build artifacts
echo "[4/6] Cleaning build artifacts..."
cd $FRONTEND_DIR
rm -rf node_modules/.vite dist
rm -f vite.config.js.timestamp-* 2>/dev/null || true

# Step 5: Rebuild frontend
echo "[5/6] Rebuilding frontend..."
if [ ! -f ".env" ]; then
    echo "VITE_API_URL=/api" > .env
fi
npm run build

# Step 6: Set correct ownership
echo "[6/6] Setting correct ownership..."
sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR
sudo chown -R $APP_USER:$APP_USER $FRONTEND_DIR/dist
# Keep .git for user for future pulls
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/.git

# Restart Nginx
echo ""
echo "Restarting Nginx..."
sudo systemctl restart nginx

echo ""
echo "========================================="
echo "Complete! Frontend rebuilt successfully!"
echo "========================================="
echo ""

