#!/bin/bash
set -e

cd /var/www/html

# Ensure environment file exists
if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    cp .env.example .env
  else
    cat <<'EOF' > .env
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=sqlite
DB_DATABASE=/database/database.sqlite
EOF
  fi
fi

# Ensure application key exists
KEY_VALUE=$(php -r 'echo preg_match("/^APP_KEY=\s*$/m", file_get_contents(".env")) ? "" : "exists";')

if [ -z "$KEY_VALUE" ]; then
  if ! php artisan key:generate --force --no-interaction; then
    echo "Failed to generate APP_KEY. Inserting placeholder value."
    sed -i 's/^APP_KEY=.*$/APP_KEY=base64:FAKEKEYFORDEV==/' .env || echo "APP_KEY=base64:FAKEKEYFORDEV==" >> .env
  fi
fi

# Ensure storage directories exist with correct permissions
mkdir -p storage/framework/{cache,views,sessions} \
  storage/logs \
  bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache || true
chmod -R 775 storage bootstrap/cache || true

DB_FILE="${DB_DATABASE:-/database/database.sqlite}"
DB_DIR="$(dirname "$DB_FILE")"

mkdir -p "$DB_DIR"
touch "$DB_FILE"
chown www-data:www-data "$DB_DIR" "$DB_FILE" || true
chmod 775 "$DB_DIR" || true
chmod 664 "$DB_FILE" || true

# Run migrations
php artisan migrate --force --no-interaction

# Start Apache
exec apache2-foreground

