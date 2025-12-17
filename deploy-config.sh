#!/bin/bash

###############################################################################
# Configuration script for Xtask deployment
# Run this before deploy.sh to set up your configuration
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Xtask Deployment Configuration${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get domain name
read -p "Enter your domain name (or press Enter to use IP address): " DOMAIN_NAME

# Get email for SSL
if [ -n "$DOMAIN_NAME" ]; then
    read -p "Enter your email for SSL certificate: " EMAIL
fi

# Get Git repository (optional)
read -p "Enter Git repository URL (or press Enter to skip): " GIT_REPO

# Create config file
cat > deploy.env << EOF
# Xtask Deployment Configuration
DOMAIN_NAME=${DOMAIN_NAME}
EMAIL=${EMAIL}
GIT_REPO=${GIT_REPO}
PROJECT_NAME=xtask
APP_USER=www-data
EOF

echo ""
echo -e "${GREEN}Configuration saved to deploy.env${NC}"
echo ""
echo "Configuration:"
echo "  Domain: ${DOMAIN_NAME:-'Not set (will use IP)'}"
echo "  Email: ${EMAIL:-'Not set'}"
echo "  Git Repo: ${GIT_REPO:-'Not set (manual file copy required)'}"
echo ""
echo "You can now run: sudo ./deploy.sh"

