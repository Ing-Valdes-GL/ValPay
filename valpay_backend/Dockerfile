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

# Start server immediately — no cache commands at runtime so Railway health check passes instantly
RUN printf '#!/bin/sh\nexec php -d memory_limit=256M -S 0.0.0.0:${PORT:-8000} -t public/ public/router.php\n' > /start.sh \
    && chmod +x /start.sh

CMD ["/start.sh"]
