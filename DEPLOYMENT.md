# 🚀 Xtask VPS Deployment Guide

Complete guide for deploying Xtask on Ubuntu VPS (AWS EC2, DigitalOcean, etc.)

## 📋 Prerequisites

- Ubuntu 20.04+ or 22.04 LTS
- Root or sudo access
- Domain name (optional, can use IP address)
- SSH access to server
- Git installed on server (usually pre-installed)
- GitHub repository: [https://github.com/Yasin777-6/Xtask](https://github.com/Yasin777-6/Xtask)

## 🎯 Quick Deployment

### Option 1: Automated Script (Recommended)

```bash
# 1. SSH into server
ssh user@13.60.60.1

# 2. Create /var/www directory if it doesn't exist
sudo mkdir -p /var/www
sudo chmod 755 /var/www

# 3. Clone repository from GitHub
# Option A: Clone directly to /var/www with sudo (recommended)
cd /var/www
sudo git clone https://github.com/Yasin777-6/Xtask.git xtask
sudo chown -R $USER:$USER /var/www/xtask  # Fix ownership
cd xtask

# Option B: Clone to home directory first, then move
# git clone https://github.com/Yasin777-6/Xtask.git ~/xtask
# sudo mv ~/xtask /var/www/xtask
# cd /var/www/xtask

# 4. Verify you're in the right place
pwd  # Should show: /var/www/xtask
ls -la  # Should show project files

# 5. Make script executable
chmod +x deploy.sh

# 6. Run deployment script
sudo ./deploy.sh
```

**Alternative: Upload via SCP**

```bash
# 1. Upload project files to server (from your local machine)
scp -r . user@13.60.60.1:/tmp/xtask

# 2. SSH into server
ssh user@13.60.60.1

# 3. Move files to deployment location
sudo mv /tmp/xtask /var/www/xtask
cd /var/www/xtask

# 4. Make script executable
chmod +x deploy.sh

# 5. Run deployment script
sudo ./deploy.sh
```

### Option 2: Step-by-Step Manual Deployment

Follow the steps below for manual deployment.

## 📦 Step-by-Step Deployment

### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    curl wget git build-essential \
    python3 python3-pip python3-venv python3-dev \
    nodejs npm \
    nginx postgresql postgresql-contrib \
    supervisor certbot python3-certbot-nginx \
    ufw
```

### 2. Install Node.js 18.x

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### 3. Configure Firewall

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 4. Clone Project from GitHub

```bash
# Create /var/www directory if it doesn't exist
sudo mkdir -p /var/www
sudo chmod 755 /var/www

# Clone the repository (use sudo since /var/www requires root permissions)
cd /var/www
sudo git clone https://github.com/Yasin777-6/Xtask.git xtask

# Fix ownership so you can work with the files
sudo chown -R $USER:$USER /var/www/xtask

# Navigate into the project
cd xtask

# Verify the repository was cloned successfully
ls -la
pwd  # Should show: /var/www/xtask
```

**Alternative Method** (if you prefer not to use sudo for git):

```bash
# Clone to your home directory first
cd ~
git clone https://github.com/Yasin777-6/Xtask.git xtask

# Create /var/www if it doesn't exist
sudo mkdir -p /var/www

# Move the cloned repository
sudo mv ~/xtask /var/www/xtask

# Fix ownership
sudo chown -R $USER:$USER /var/www/xtask

# Navigate into the project
cd /var/www/xtask
```

**Troubleshooting Permission Issues:**

If you get "Permission denied" errors:

```bash
# Check current permissions
ls -ld /var/www

# Fix permissions if needed
sudo chmod 755 /var/www

# If you cloned with sudo, fix ownership:
sudo chown -R $USER:$USER /var/www/xtask
```

**Alternative: Upload via SCP (if you prefer)**

```bash
# On your local machine
scp -r . user@13.60.60.1:/tmp/xtask

# Then on server
sudo mv /tmp/xtask /var/www/xtask
```

### 5. Backend Setup

```bash
# Navigate to project directory
cd /var/www/xtask

# Verify you're in the correct directory
pwd  # Should show: /var/www/xtask
ls -la  # Should show project files

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn psycopg2-binary

# Create .env file
cat > .env << EOF
DEBUG=False
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
ALLOWED_HOSTS=13.60.60.1,your-domain.com
DATABASE_URL=postgresql://xtask_user:xtask_pass@localhost/xtask_db
CORS_ALLOWED_ORIGINS=http://13.60.60.1,https://your-domain.com
EOF

# Update settings.py to read from .env (see below)

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser (optional)
python manage.py createsuperuser
```

### 6. Update Django Settings for Production

Edit `xtask/settings.py`:

```python
import os
from decouple import config

# Read from environment
DEBUG = config('DEBUG', default=False, cast=bool)
SECRET_KEY = config('SECRET_KEY')
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', default='xtask_db'),
        'USER': config('DB_USER', default='xtask_user'),
        'PASSWORD': config('DB_PASSWORD', default='xtask_pass'),
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Security settings for production
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
```

### 7. Database Setup

```bash
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

### 8. Create Gunicorn Service

```bash
sudo nano /etc/systemd/system/xtask.service
```

Paste the content from `xtask.service` file, then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable xtask
sudo systemctl start xtask
sudo systemctl status xtask
```

### 9. Frontend Setup

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

### 10. Configure Nginx

```bash
# Copy nginx configuration
sudo cp nginx-xtask.conf /etc/nginx/sites-available/xtask

# Edit configuration
sudo nano /etc/nginx/sites-available/xtask
# Update server_name with your domain or IP

# Enable site
sudo ln -s /etc/nginx/sites-available/xtask /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### 11. SSL Certificate (Optional but Recommended)

```bash
# If you have a domain name
sudo certbot --nginx -d your-domain.com

# Follow prompts to configure SSL
```

### 12. Set Permissions

```bash
sudo chown -R www-data:www-data /var/www/xtask
sudo chmod -R 755 /var/www/xtask
```

## 🔧 Service Management

### Gunicorn Service

```bash
# Start
sudo systemctl start xtask

# Stop
sudo systemctl stop xtask

# Restart
sudo systemctl restart xtask

# Status
sudo systemctl status xtask

# View logs
sudo journalctl -u xtask -f
```

### Nginx Service

```bash
# Restart
sudo systemctl restart nginx

# Reload configuration
sudo nginx -s reload

# Check status
sudo systemctl status nginx
```

## 📊 Monitoring

### View Logs

```bash
# Application logs
sudo tail -f /var/log/xtask/error.log
sudo tail -f /var/log/xtask/access.log

# System logs
sudo journalctl -u xtask -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Health Check

```bash
# Check if services are running
curl http://localhost:8000/api/tasks/
curl http://localhost/health
```

## 🔒 Security Checklist

- [ ] Change default database password
- [ ] Set strong SECRET_KEY in .env
- [ ] Configure ALLOWED_HOSTS properly
- [ ] Enable SSL/HTTPS
- [ ] Set up firewall rules
- [ ] Disable DEBUG mode
- [ ] Set up regular backups
- [ ] Configure log rotation
- [ ] Set up monitoring/alerts
- [ ] Keep system updated

## 🔄 Updates and Maintenance

### Update Application

```bash
cd /var/www/xtask

# Pull latest changes from GitHub
sudo git pull origin main

# Update backend
cd /var/www/xtask
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart xtask

# Update frontend
cd frontend
npm install
npm run build
sudo systemctl restart nginx
```

**Note**: If you encounter merge conflicts or need to reset:

```bash
# Backup current state
sudo cp -r /var/www/xtask /var/www/xtask.backup

# Reset to latest from GitHub (WARNING: This will discard local changes)
cd /var/www/xtask
sudo git fetch origin
sudo git reset --hard origin/main
```

### Backup Database

```bash
# Create backup
sudo -u postgres pg_dump xtask_db > backup_$(date +%Y%m%d).sql

# Restore backup
sudo -u postgres psql xtask_db < backup_YYYYMMDD.sql
```

## 🐛 Troubleshooting

### Backend not starting

```bash
# Check logs
sudo journalctl -u xtask -n 50

# Check if port is in use
sudo netstat -tlnp | grep 8000

# Test Gunicorn manually
cd /var/www/xtask/backend
source venv/bin/activate
gunicorn xtask.wsgi:application --bind 127.0.0.1:8000
```

### Frontend not loading

```bash
# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Verify build files exist
ls -la /var/www/xtask/frontend/dist

# Test Nginx configuration
sudo nginx -t
```

### Database connection errors

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection
sudo -u postgres psql -d xtask_db -U xtask_user
```

### Permission errors

```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/xtask

# Fix permissions
sudo chmod -R 755 /var/www/xtask
```

## 📝 Environment Variables

### Backend (.env)

```env
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=13.60.60.1,your-domain.com
DB_NAME=xtask_db
DB_USER=xtask_user
DB_PASSWORD=your-secure-password
CORS_ALLOWED_ORIGINS=http://13.60.60.1,https://your-domain.com
```

### Frontend (.env)

```env
VITE_API_URL=http://13.60.60.1/api
# Or for HTTPS:
# VITE_API_URL=https://your-domain.com/api
```

## 🌐 DNS Configuration

If using a domain name:

1. Add A record pointing to `13.60.60.1`
2. Wait for DNS propagation (usually 5-30 minutes)
3. Run certbot for SSL

## 📦 Git Repository Information

**Repository URL**: [https://github.com/Yasin777-6/Xtask](https://github.com/Yasin777-6/Xtask)

### Cloning the Repository

```bash
# Clone to default location
git clone https://github.com/Yasin777-6/Xtask.git

# Clone to specific directory
git clone https://github.com/Yasin777-6/Xtask.git /var/www/xtask

# Clone specific branch (if needed)
git clone -b main https://github.com/Yasin777-6/Xtask.git
```

### Keeping Repository Updated

```bash
# Check current status
cd /var/www/xtask
git status

# Fetch latest changes
git fetch origin

# View available branches
git branch -a

# Pull latest changes
git pull origin main

# View commit history
git log --oneline -10
```

### Working with Git on Server

If you need to make changes and push back to GitHub:

```bash
# Configure Git (if not already done)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Create a new branch for changes
git checkout -b server-changes

# Make your changes, then commit
git add .
git commit -m "Server configuration changes"

# Push to GitHub (if you have write access)
git push origin server-changes
```

## 📞 Support

For issues:
1. Check logs (see Monitoring section)
2. Verify all services are running
3. Check firewall rules
4. Review configuration files
5. Check GitHub repository for updates: [https://github.com/Yasin777-6/Xtask](https://github.com/Yasin777-6/Xtask)

## 🔗 Quick Links

- **GitHub Repository**: [https://github.com/Yasin777-6/Xtask](https://github.com/Yasin777-6/Xtask)
- **Clone Command**: `git clone https://github.com/Yasin777-6/Xtask.git`
- **Repository Structure**: 
  - `/backend` - Django REST Framework API
  - `/frontend` - React frontend application
  - `/deploy.sh` - Automated deployment script

---

**Deployment completed!** 🎉

Your application should now be accessible at:
- **Frontend**: http://13.60.60.1 (or https://your-domain.com)
- **Backend API**: http://13.60.60.1/api (or https://your-domain.com/api)
- **Admin Panel**: http://13.60.60.1/admin (or https://your-domain.com/admin)

**Repository**: All code is available at [https://github.com/Yasin777-6/Xtask](https://github.com/Yasin777-6/Xtask)

