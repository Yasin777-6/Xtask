# Quick Fix Steps for Server Deployment

Run these commands **on your Ubuntu VPS server** (via SSH) to fix all deployment issues:

## Step 1: Navigate to project directory
```bash
cd /var/www/xtask
```

## Step 2: Fix Git and pull latest code
```bash
sudo git config --global --add safe.directory /var/www/xtask
git stash
git pull origin main
```

## Step 3: Fix file ownership
```bash
sudo chown -R www-data:www-data /var/www/xtask
sudo chmod -R 755 /var/www/xtask
```

## Step 4: Create database directory
```bash
sudo mkdir -p /var/www/xtask/db
sudo chown www-data:www-data /var/www/xtask/db
sudo chmod 775 /var/www/xtask/db
```

## Step 5: Install Python dependencies
```bash
cd /var/www/xtask
source venv/bin/activate
pip install -r requirements.txt
pip install gunicorn
deactivate
```

## Step 6: Run migrations and collect static files
```bash
sudo -u www-data /var/www/xtask/venv/bin/python manage.py migrate
sudo -u www-data /var/www/xtask/venv/bin/python manage.py collectstatic --noinput
```

## Step 7: Build frontend
```bash
cd /var/www/xtask/frontend

# Fix ownership for npm install
sudo chown -R $USER:$USER /var/www/xtask/frontend

# Remove old node_modules if it exists
sudo rm -rf node_modules

# Install dependencies
npm install

# Create .env file for production
echo "VITE_API_URL=/api" > .env

# Build frontend
npm run build

# Fix ownership of dist
sudo chown -R www-data:www-data /var/www/xtask/frontend/dist
```

## Step 8: Configure Nginx
```bash
# Copy Nginx config
sudo cp /var/www/xtask/nginx-xtask.conf /etc/nginx/sites-available/xtask

# Enable site
sudo ln -sf /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t
```

## Step 9: Configure systemd service
```bash
# Copy service file
sudo cp /var/www/xtask/xtask.service /etc/systemd/system/xtask.service

# Create log directory
sudo mkdir -p /var/log/xtask
sudo chown www-data:www-data /var/log/xtask

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
sudo systemctl enable xtask
sudo systemctl restart xtask
```

## Step 10: Restart Nginx
```bash
sudo systemctl restart nginx
```

## Step 11: Verify everything is working
```bash
# Check service status
sudo systemctl status xtask
sudo systemctl status nginx

# Test API
curl http://localhost/api/tasks/

# Test frontend
curl http://localhost/

# Check logs if there are issues
sudo journalctl -u xtask -f
sudo tail -f /var/log/nginx/error.log
```

## Troubleshooting

### If you get "no such table: tasks_task"
```bash
# Make sure migrations ran
sudo -u www-data /var/www/xtask/venv/bin/python manage.py migrate
```

### If you get permission errors
```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/xtask
sudo chmod -R 755 /var/www/xtask
sudo chmod 775 /var/www/xtask/db
```

### If frontend build fails
```bash
# Make sure you're running as your user (not www-data)
cd /var/www/xtask/frontend
sudo chown -R $USER:$USER .
npm install
npm run build
sudo chown -R www-data:www-data dist
```

### If Nginx returns 500 error
```bash
# Check Nginx error log
sudo tail -f /var/log/nginx/error.log

# Check if frontend dist exists
ls -la /var/www/xtask/frontend/dist

# Check if backend is running
curl http://localhost:8000/api/tasks/
```

