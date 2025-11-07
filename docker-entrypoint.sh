#!/bin/bash
set -e

# Run migrations
php artisan migrate --force

# Start Apache
exec apache2-foreground

