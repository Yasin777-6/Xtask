# ⚡ Quick Deployment Reference

Fast deployment steps for your Ubuntu VPS.

## 🚀 One-Command Deployment (After Upload)

```bash
# On your Ubuntu server
cd /var/www/xtask
sudo chmod +x deploy.sh
sudo ./deploy.sh
```

## 📤 Upload Files to Server

### Option 1: SCP (from your local machine)

```bash
# Upload entire project
scp -r . user@13.60.60.1:/tmp/xtask

# Then on server:
ssh user@13.60.60.1
sudo mv /tmp/xtask /var/www/xtask
```

### Option 2: Git (if you have a repository)

```bash
# On server
cd /var/www
sudo git clone YOUR_REPO_URL xtask
cd xtask
```

### Option 3: Manual Upload

Use SFTP client (FileZilla, WinSCP) to upload files to `/var/www/xtask`

## ⚙️ Pre-Deployment Configuration

Edit `deploy.sh` and update these variables:

```bash
DOMAIN_NAME="your-domain.com"  # Or leave empty for IP
EMAIL="your-email@example.com"  # For SSL
GIT_REPO="https://github.com/your-repo.git"  # Optional
```

## ✅ Post-Deployment Checklist

- [ ] Change database password in `.env`
- [ ] Update `ALLOWED_HOSTS` in Django settings
- [ ] Set up SSL certificate (if using domain)
- [ ] Test API: `curl http://13.60.60.1/api/tasks/`
- [ ] Test frontend: Open `http://13.60.60.1` in browser
- [ ] Create superuser: `python manage.py createsuperuser`

## 🔧 Common Commands

```bash
# Restart backend
sudo systemctl restart xtask

# Restart frontend (nginx)
sudo systemctl restart nginx

# View logs
sudo journalctl -u xtask -f

# Check status
sudo systemctl status xtask
```

## 🌐 Access URLs

- **Frontend**: http://13.60.60.1
- **API**: http://13.60.60.1/api
- **Admin**: http://13.60.60.1/admin

## 📝 Important Notes

1. **Database Password**: Change default password in production
2. **SECRET_KEY**: Ensure it's set in `.env` file
3. **Firewall**: Ports 22, 80, 443 should be open
4. **SSL**: Run certbot if you have a domain name

## 🆘 Quick Troubleshooting

```bash
# Backend not working?
sudo systemctl status xtask
sudo journalctl -u xtask -n 50

# Frontend not loading?
sudo nginx -t
sudo tail -f /var/log/nginx/error.log

# Permission issues?
sudo chown -R www-data:www-data /var/www/xtask
```

For detailed instructions, see `DEPLOYMENT.md`

