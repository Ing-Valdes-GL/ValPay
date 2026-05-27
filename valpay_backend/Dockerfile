FROM php:8.2-cli

RUN apt-get update && apt-get install -y \
    libpng-dev libpq-dev libzip-dev libonig-dev \
    libsodium-dev libicu-dev zip unzip git curl \
    && docker-php-ext-install \
        pdo pdo_pgsql pgsql mbstring bcmath gd zip intl sodium \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

RUN mkdir -p storage/framework/{sessions,views,cache/data} bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

RUN composer install --optimize-autoloader --no-dev --no-interaction --no-scripts \
    && php artisan package:discover --ansi

# Write startup script inline to avoid CRLF issues from Windows git
RUN printf '#!/bin/sh\nphp artisan config:cache || true\nphp artisan route:cache || true\nexec php artisan serve --host=0.0.0.0 --port="${PORT:-8000}"\n' > /start.sh \
    && chmod +x /start.sh

EXPOSE 8000
CMD ["/start.sh"]
