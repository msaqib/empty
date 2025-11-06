########## Stage 1: Build PHP extensions and install Composer deps ##########
FROM php:8.2-cli AS build
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
COPY composer.* ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

########## Stage 2: PHP-Apache runtime ##########
FROM php:8.2-apache
WORKDIR /var/www/html

# System deps for runtime (match needed libs for extensions)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libzip4 libxml2 \
    && rm -rf /var/lib/apt/lists/*

# Enable required PHP extensions and Apache modules, set Laravel docroot
RUN docker-php-ext-install \
        bcmath \
        mbstring \
        pdo \
        pdo_mysql \
        xml \
    && a2enmod rewrite \
    && sed -ri 's#DocumentRoot /var/www/html#DocumentRoot /var/www/html/public#g' /etc/apache2/sites-available/000-default.conf \
    && printf '<Directory /var/www/html/public>\n\tAllowOverride All\n\tRequire all granted\n</Directory>\n' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel

# Copy application source
COPY . .

# Copy vendor from build stage
COPY --from=build /app/vendor ./vendor

EXPOSE 80