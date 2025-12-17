# Fix SQLite Database Permissions

## Quick Fix

Run these commands on your server:

```bash
cd /var/www/xtask

# Create database directory with proper permissions
sudo mkdir -p /var/www/xtask/db
sudo chown -R www-data:www-data /var/www/xtask
sudo chmod -R 755 /var/www/xtask
sudo chmod 777 /var/www/xtask  # Allow SQLite to create db.sqlite3

# Or better: create db directory and set permissions
sudo mkdir -p /var/www/xtask/db
sudo chown www-data:www-data /var/www/xtask/db
sudo chmod 775 /var/www/xtask/db

# Update settings.py to use this directory (see below)
```

## Update Django Settings

Edit `xtask/settings.py` to use a writable database location:

```python
# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db' / 'db.sqlite3',  # Use db/ subdirectory
    }
}
```

Or use an absolute path:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': '/var/www/xtask/db/db.sqlite3',
    }
}
```

## Alternative: Use /tmp or /var/lib (Recommended for Production)

For better security, use a dedicated directory:

```bash
# Create database directory
sudo mkdir -p /var/lib/xtask
sudo chown www-data:www-data /var/lib/xtask
sudo chmod 755 /var/lib/xtask
```

Then in settings.py:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': '/var/lib/xtask/db.sqlite3',
    }
}
```

## After Fixing Permissions

```bash
cd /var/www/xtask
source venv/bin/activate

# Run migrations
python manage.py migrate

# Restart service
sudo systemctl restart xtask
```

