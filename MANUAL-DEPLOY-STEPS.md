# Manual Deployment Steps for Xtask

Complete these steps on your server to get the website running.

## Step 1: Fix Git and Pull Latest Code

```bash
cd /var/www/xtask

# Stash local changes to deploy.sh
git stash

# Pull latest code
git pull origin main

# Verify files are there
ls -la
```

## Step 2: Complete Backend Setup

```bash
cd /var/www/xtask

# Activate virtual environment (if not already active)
source venv/bin/activate

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser (optional)
python manage.py createsuperuser
```

## Step 3: Setup Database

```bash
# Create PostgreSQL database
sudo -u postgres psql << EOF
CREATE DATABASE xtask_db;
CREATE USER xtask_user WITH PASSWORD 'CHANGE_THIS_PASSWORD';
ALTER ROLE xtask_user SET client_encoding TO 'utf8';
ALTER ROLE xtask_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE xtask_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE xtask_db TO xtask_user;
\q
EOF
```

## Step 4: Create .env File

```bash
cd /var/www/xtask

cat > .env << EOF
DEBUG=False
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
ALLOWED_HOSTS=13.60.60.1,localhost,127.0.0.1
DB_NAME=xtask_db
DB_USER=xtask_user
DB_PASSWORD=CHANGE_THIS_PASSWORD
CORS_ALLOWED_ORIGINS=http://13.60.60.1,https://13.60.60.1
EOF
```

## Step 5: Update Django Settings

Edit `xtask/settings.py` to read from .env (or use the production settings example).

## Step 6: Build Frontend

```bash
cd /var/www/xtask/frontend

# Install dependencies
npm install

# Create .env file
cat > .env << EOF
VITE_API_URL=http://13.60.60.1/api
EOF

# Build for production
npm run build
```

## Step 7: Create Gunicorn Service

```bash
sudo nano /etc/systemd/system/xtask.service
```

Paste this content:

```ini
[Unit]
Description=Xtask Gunicorn daemon
After=network.target postgresql.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/xtask
Environment="PATH=/var/www/xtask/venv/bin"
Environment="DJANGO_SETTINGS_MODULE=xtask.settings"
ExecStart=/var/www/xtask/venv/bin/gunicorn \
    --workers 3 \
    --worker-class sync \
    --timeout 120 \
    --bind 127.0.0.1:8000 \
    --access-logfile /var/log/xtask/access.log \
    --error-logfile /var/log/xtask/error.log \
    --log-level info \
    --capture-output \
    xtask.wsgi:application

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable xtask
sudo systemctl start xtask
sudo systemctl status xtask
```

## Step 8: Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/xtask
```

Paste this configuration:

```nginx
upstream xtask_backend {
    server 127.0.0.1:8000;
    keepalive 32;
}

server {
    listen 80;
    server_name 13.60.60.1;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Frontend - React SPA
    location / {
        root /var/www/xtask/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|webp)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
    }

    # Backend API
    location /api {
        proxy_pass http://xtask_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_cache_bypass $http_upgrade;
        proxy_redirect off;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PATCH, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-CSRFToken" always;
        
        if ($request_method = OPTIONS) {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PATCH, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-CSRFToken";
            add_header Access-Control-Max-Age 3600;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }

    # Django admin static files
    location /static/ {
        alias /var/www/xtask/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

## Step 9: Set Permissions

```bash
sudo chown -R www-data:www-data /var/www/xtask
sudo chmod -R 755 /var/www/xtask
```

## Step 10: Test Everything

```bash
# Check backend service
sudo systemctl status xtask

# Check nginx
sudo systemctl status nginx

# Test API
curl http://localhost:8000/api/tasks/

# Test frontend
curl http://localhost/
```

## Step 11: Access Your Website

Open in browser:
- **Frontend**: http://13.60.60.1
- **API**: http://13.60.60.1/api
- **Admin**: http://13.60.60.1/admin

## Troubleshooting

If website is still empty:

```bash
# Check if frontend was built
ls -la /var/www/xtask/frontend/dist

# Check nginx logs
sudo tail -f /var/log/nginx/error.log

# Check backend logs
sudo journalctl -u xtask -f

# Restart services
sudo systemctl restart xtask
sudo systemctl restart nginx
```

