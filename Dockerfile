########## Stage 1: Build PHP extensions and install Composer deps ##########
FROM php:8.2-apache AS build
WORKDIR /app

# System deps for PHP extensions
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git unzip libzip-dev libxml2-dev libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions required by Laravel
RUN docker-php-ext-install \
        bcmath \
        mbstring \
        pdo \
        pdo_mysql \
        xml

# Copy Composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install only production dependencies
COPY artisan composer.* .
COPY bootstrap/ ./bootstrap
COPY routes/ ./routes/
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

########## Stage 2: PHP-Apache runtime ##########
FROM php:8.2-apache
WORKDIR /var/www/html

# System deps for runtime (match needed libs for extensions)

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libzip5 libxml2 libonig5 libzip-dev libxml2-dev libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# Enable required PHP extensions and Apache modules
RUN docker-php-ext-install \
        bcmath \
        mbstring \
        pdo \
        pdo_mysql \
        xml \
    && a2enmod rewrite

# Configure Apache for Laravel (set DocumentRoot to public directory)
RUN printf '<VirtualHost *:80>\n\tServerAdmin webmaster@localhost\n\tDocumentRoot /var/www/html/public\n\t\n\t<Directory /var/www/html/public>\n\t\tOptions Indexes FollowSymLinks\n\t\tAllowOverride All\n\t\tRequire all granted\n\t</Directory>\n\t\n\tErrorLog ${APACHE_LOG_DIR}/error.log\n\tCustomLog ${APACHE_LOG_DIR}/access.log combined\n</VirtualHost>\n' > /etc/apache2/sites-available/000-default.conf \
    && a2ensite 000-default.conf

# Copy application source
COPY . .

# Copy vendor from build stage
COPY --from=build /app/vendor ./vendor

# Create Laravel storage and cache directories and set permissions
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && mkdir -p database \
    && touch database/database.sqlite \
    && chown -R www-data:www-data /var/www/html/storage \
    && chown -R www-data:www-data /var/www/html/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/database \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache \
    && chmod 664 /var/www/html/database/database.sqlite

# Clear Laravel config and route cache to ensure changes take effect
RUN rm -f bootstrap/cache/*.php 2>/dev/null || true \
    && find bootstrap/cache -type f -name "*.php" -delete 2>/dev/null || true

# Set environment variable to ensure file-based sessions are used
ENV SESSION_DRIVER=file

EXPOSE 80