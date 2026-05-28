FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpng-dev libpq-dev libzip-dev libonig-dev \
    libsodium-dev libicu-dev zip unzip git curl \
    && docker-php-ext-install \
        pdo pdo_pgsql pgsql mbstring bcmath gd zip intl sodium \
    && rm -rf /var/lib/apt/lists/*

# Enable mod_rewrite, fix MPM conflict
RUN a2dismod mpm_event mpm_worker 2>/dev/null || true \
    && a2enmod mpm_prefork rewrite

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

RUN mkdir -p storage/framework/{sessions,views,cache/data} bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

RUN composer install --optimize-autoloader --no-dev --no-interaction --no-scripts \
    && php artisan package:discover --ansi

# Point Apache document root to Laravel's public/
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's|</VirtualHost>|<Directory /var/www/html/public>\n    AllowOverride All\n    Require all granted\n</Directory>\n</VirtualHost>|g' /etc/apache2/sites-available/000-default.conf

# Use Railway's PORT env var for Apache
RUN printf '#!/bin/sh\nsed -i "s/Listen 80/Listen ${PORT:-80}/" /etc/apache2/ports.conf\nsed -i "s/:80>/:${PORT:-80}>/" /etc/apache2/sites-available/000-default.conf\nexec apache2-foreground\n' > /start.sh \
    && chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]
