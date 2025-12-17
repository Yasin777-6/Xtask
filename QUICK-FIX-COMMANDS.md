# Quick Fix Commands - Copy and Paste

Run these commands **one by one** on your Ubuntu VPS server to fix all issues:

```bash
# Step 1: Navigate to project
cd /var/www/xtask

# Step 2: Fix Git ownership
sudo git config --global --add safe.directory /var/www/xtask

# Step 3: Stash local changes and pull latest code
git stash
git pull origin main

# Step 4: Fix file ownership
sudo chown -R www-data:www-data /var/www/xtask
sudo chmod -R 755 /var/www/xtask

# Step 5: Create database directory
sudo mkdir -p /var/www/xtask/db
sudo chown www-data:www-data /var/www/xtask/db
sudo chmod 775 /var/www/xtask/db

# Step 6: Install Python dependencies (if needed)
cd /var/www/xtask
source venv/bin/activate
pip install -r requirements.txt
pip install gunicorn
deactivate

# Step 7: Run migrations and collect static files
sudo -u www-data /var/www/xtask/venv/bin/python manage.py migrate
sudo -u www-data /var/www/xtask/venv/bin/python manage.py collectstatic --noinput

# Step 8: Build frontend
cd /var/www/xtask/frontend
sudo chown -R $USER:$USER /var/www/xtask/frontend
sudo rm -rf node_modules
npm install
echo "VITE_API_URL=/api" > .env
npm run build
sudo chown -R www-data:www-data /var/www/xtask/frontend/dist

# Step 9: Configure Nginx
sudo cp /var/www/xtask/nginx-xtask.conf /etc/nginx/sites-available/xtask
sudo ln -sf /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# Step 10: Configure systemd service
sudo cp /var/www/xtask/xtask.service /etc/systemd/system/xtask.service
sudo mkdir -p /var/log/xtask
sudo chown www-data:www-data /var/log/xtask
sudo systemctl daemon-reload
sudo systemctl enable xtask
sudo systemctl restart xtask

# Step 11: Restart Nginx
sudo systemctl restart nginx

# Step 12: Verify everything works
sudo systemctl status xtask
sudo systemctl status nginx
curl http://localhost/api/tasks/
```

## If you get errors, check logs:

```bash
# Check backend logs
sudo journalctl -u xtask -n 50

# Check Nginx error log
sudo tail -n 50 /var/log/nginx/error.log

# Check if frontend dist exists
ls -la /var/www/xtask/frontend/dist

# Check if backend is running
curl http://localhost:8000/api/tasks/
```

