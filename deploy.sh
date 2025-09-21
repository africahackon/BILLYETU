#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting Billyetu deployment...${NC}"

# Install dependencies
echo -e "\n${YELLOW}📦 Installing dependencies...${NC}"
composer install --optimize-autoloader --no-dev
npm install
npm run build

# Clear caches
echo -e "\n${YELLOW}🧹 Clearing caches...${NC}"
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# Cache configurations
echo -e "\n${YELLOW}⚡ Caching configurations...${NC}"
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run migrations
echo -e "\n${YELLOW}🔄 Running migrations...${NC}"
php artisan migrate --force

# Restart queue workers
echo -e "\n${YELLOW}🔄 Restarting queue workers...${NC}"
php artisan queue:restart

# Setup supervisor for MikroTik queue worker
echo -e "\n${YELLOW}👷 Setting up supervisor for MikroTik queue...${NC}"
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart mikrotik-worker

# Setup scheduled tasks
echo -e "\n${YELLOW}⏰ Setting up scheduled tasks...${NC}"
(crontab -l 2>/dev/null; echo "* * * * * cd $(pwd) && php artisan schedule:run >> /dev/null 2>&1") | crontab -

# Set proper permissions
echo -e "\n${YELLOW}🔒 Setting permissions...${NC}"
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data .

# Sync all users to MikroTik
echo -e "\n${YELLOW}🔄 Syncing users to MikroTik routers...${NC}"
php artisan mikrotik:sync --all

echo -e "\n${GREEN}✅ Deployment completed successfully!${NC}"
