#!/bin/bash

# Script to rebuild frontend with proper permissions
set -e

PROJECT_DIR="/var/www/xtask"
FRONTEND_DIR="$PROJECT_DIR/frontend"
APP_USER="www-data"
CURRENT_USER=$(whoami)

echo "========================================="
echo "Rebuilding Frontend"
echo "========================================="

# Step 1: Fix Git issues
echo "[1/5] Fixing Git and pulling latest code..."
cd $PROJECT_DIR
sudo chown -R $CURRENT_USER:$CURRENT_USER $PROJECT_DIR/.git
git stash || true
git pull origin main

# Step 2: Fix frontend ownership for npm operations
echo "[2/5] Fixing frontend ownership..."
sudo chown -R $CURRENT_USER:$CURRENT_USER $FRONTEND_DIR

# Step 3: Clean any build artifacts with wrong permissions
echo "[3/5] Cleaning build artifacts..."
cd $FRONTEND_DIR
rm -rf node_modules/.vite
rm -f vite.config.js.timestamp-* 2>/dev/null || true
rm -rf dist

# Step 4: Rebuild frontend
echo "[4/5] Rebuilding frontend..."
if [ ! -f ".env" ]; then
    echo "VITE_API_URL=/api" > .env
fi
npm run build

# Step 5: Fix ownership of dist directory
echo "[5/5] Setting correct ownership..."
sudo chown -R $APP_USER:$APP_USER $FRONTEND_DIR/dist

echo ""
echo "========================================="
echo "Frontend rebuild complete!"
echo "========================================="
echo ""
echo "Restarting Nginx..."
sudo systemctl restart nginx
echo ""
echo "Frontend should now be updated with centered task cards!"
echo ""

