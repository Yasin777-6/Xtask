#!/bin/bash

# Comprehensive diagnostic and fix script
# Run this to diagnose and fix all issues

set -e

PROJECT_DIR="/var/www/xtask"
APP_USER="www-data"

echo "========================================="
echo "Diagnostic and Fix Script"
echo "========================================="

# Step 1: Check backend service
echo "[1/10] Checking backend service..."
if sudo systemctl is-active --quiet xtask; then
    echo "✓ Backend service is running"
else
    echo "✗ Backend service is NOT running"
    sudo systemctl status xtask --no-pager -l | head -20
    echo "Attempting to start..."
    sudo systemctl start xtask
    sleep 2
fi

# Step 2: Test backend directly
echo ""
echo "[2/10] Testing backend on port 8000..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/tasks/ | grep -q "200\|404"; then
    echo "✓ Backend is responding on port 8000"
    curl -s http://localhost:8000/api/tasks/ | head -5
else
    echo "✗ Backend is NOT responding on port 8000"
    echo "Checking if port is listening..."
    sudo netstat -tlnp | grep 8000 || sudo ss -tlnp | grep 8000 || echo "Port 8000 is not listening"
fi

# Step 3: Check frontend dist
echo ""
echo "[3/10] Checking frontend build..."
if [ -d "$PROJECT_DIR/frontend/dist" ] && [ -f "$PROJECT_DIR/frontend/dist/index.html" ]; then
    echo "✓ Frontend dist exists"
    ls -lh $PROJECT_DIR/frontend/dist/ | head -5
else
    echo "✗ Frontend dist is missing or incomplete"
    echo "Rebuilding frontend..."
    cd $PROJECT_DIR/frontend
    sudo chown -R $USER:$USER $PROJECT_DIR/frontend
    if [ ! -f ".env" ]; then
        echo "VITE_API_URL=/api" > .env
    fi
    npm run build
    sudo chown -R $APP_USER:$APP_USER $PROJECT_DIR/frontend/dist
fi

# Step 4: Check Nginx configuration
echo ""
echo "[4/10] Checking Nginx configuration..."
if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo "✓ Nginx configuration is valid"
else
    echo "✗ Nginx configuration has errors:"
    sudo nginx -t
fi

# Step 5: Check Nginx error log
echo ""
echo "[5/10] Recent Nginx errors:"
sudo tail -n 10 /var/log/nginx/error.log || echo "No error log found"

# Step 6: Check backend logs
echo ""
echo "[6/10] Recent backend errors:"
sudo journalctl -u xtask -n 20 --no-pager || echo "No backend logs found"

# Step 7: Verify Nginx is serving the correct config
echo ""
echo "[7/10] Checking active Nginx configuration..."
if [ -L "/etc/nginx/sites-enabled/xtask" ]; then
    echo "✓ Nginx site is enabled"
    echo "Configuration file:"
    grep -A 5 "location /" /etc/nginx/sites-available/xtask | head -10
else
    echo "✗ Nginx site is NOT enabled"
    echo "Enabling site..."
    sudo cp $PROJECT_DIR/nginx-xtask.conf /etc/nginx/sites-available/xtask
    sudo ln -sf /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
fi

# Step 8: Check file permissions
echo ""
echo "[8/10] Checking file permissions..."
echo "Frontend dist permissions:"
ls -ld $PROJECT_DIR/frontend/dist 2>/dev/null || echo "Frontend dist does not exist"
echo "Backend directory permissions:"
ls -ld $PROJECT_DIR

# Step 9: Test API through Nginx
echo ""
echo "[9/10] Testing API through Nginx..."
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/tasks/ || echo "000")
if [ "$API_RESPONSE" = "200" ] || [ "$API_RESPONSE" = "404" ]; then
    echo "✓ API is accessible through Nginx (HTTP $API_RESPONSE)"
    curl -s http://localhost/api/tasks/ | head -5
else
    echo "✗ API is NOT accessible through Nginx (HTTP $API_RESPONSE)"
fi

# Step 10: Test frontend through Nginx
echo ""
echo "[10/10] Testing frontend through Nginx..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✓ Frontend is accessible through Nginx (HTTP $FRONTEND_RESPONSE)"
    curl -s http://localhost/ | head -10
else
    echo "✗ Frontend is NOT accessible through Nginx (HTTP $FRONTEND_RESPONSE)"
    echo "Response:"
    curl -s http://localhost/ | head -20
fi

# Final fixes
echo ""
echo "========================================="
echo "Applying final fixes..."
echo "========================================="

# Ensure backend is running
sudo systemctl restart xtask
sleep 2

# Ensure Nginx is running
sudo systemctl restart nginx
sleep 1

# Final test
echo ""
echo "Final test results:"
echo "Backend direct: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/api/tasks/)"
echo "Backend via Nginx: $(curl -s -o /dev/null -w '%{http_code}' http://localhost/api/tasks/)"
echo "Frontend via Nginx: $(curl -s -o /dev/null -w '%{http_code}' http://localhost/)"

echo ""
echo "========================================="
echo "Diagnostic complete!"
echo "========================================="
echo ""
echo "If issues persist, check:"
echo "  1. sudo journalctl -u xtask -f"
echo "  2. sudo tail -f /var/log/nginx/error.log"
echo "  3. sudo netstat -tlnp | grep 8000"
echo ""

