#!/bin/bash

# Deployment script for Django on AWS Lightsail Bitnami
# Run this on your Lightsail instance after cloning the repo

echo "Starting deployment..."

# Set project directory
PROJECT_DIR="/var/www/TrashTrails"
cd $PROJECT_DIR

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install/Update dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create necessary directories
echo "Creating media and static directories..."
mkdir -p media staticfiles

# Set correct permissions
sudo chown -R bitnami:daemon $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput --settings=backend.settings.prod_vps

# Run migrations
echo "Running database migrations..."
python manage.py migrate --settings=backend.settings.prod_vps

# Create superuser (optional - comment out if not needed)
# echo "Creating superuser..."
# python manage.py createsuperuser --settings=backend.settings.prod_vps

echo "Deployment completed!"
echo "Remember to:"
echo "1. Configure Gunicorn service"
echo "2. Configure Apache/Nginx"
echo "3. Set up SSL certificate (optional but recommended)"