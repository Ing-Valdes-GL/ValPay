FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpng-dev libpq-dev libzip-dev libonig-dev \
    libsodium-dev libicu-dev zip unzip git curl \
    && docker-php-ext-install \
        pdo pdo_pgsql pgsql mbstring bcmath gd zip intl sodium \
    && rm -rf /var/lib/apt/lists/*

# mpm_prefork is compiled statically — only link its .conf (no .load)
# Remove all other MPM .load/.conf, then enable rewrite
RUN rm -f /etc/apache2/mods-enabled/mpm_*.load \
          /etc/apache2/mods-enabled/mpm_*.conf \
    && ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf \
    && ln -sf /etc/apache2/mods-available/rewrite.load     /etc/apache2/mods-enabled/rewrite.load

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

RUN mkdir -p storage/framework/{sessions,views,cache/data} bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

RUN composer install --optimize-autoloader --no-dev --no-interaction --no-scripts \
    && php artisan package:discover --ansi

# Point Apache at Laravel's public/ and allow .htaccess
RUN sed -i \
        -e 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|' \
        -e 's|</VirtualHost>|<Directory /var/www/html/public>\n    Options -Indexes\n    AllowOverride All\n    Require all granted\n</Directory>\n</VirtualHost>|' \
    /etc/apache2/sites-available/000-default.conf

# Adjust Apache to listen on Railway's dynamic PORT at runtime
RUN printf '#!/bin/sh\nPORT="${PORT:-80}"\nsed -i "s/Listen 80$/Listen ${PORT}/" /etc/apache2/ports.conf\nsed -i "s/:80>/:${PORT}>/" /etc/apache2/sites-available/000-default.conf\nexec apache2-foreground\n' > /start.sh \
    && chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]
