#!/bin/sh

php artisan config:cache || echo "[warn] config:cache failed, continuing..."
php artisan route:cache  || echo "[warn] route:cache failed, continuing..."

exec php artisan serve --host=0.0.0.0 --port="${PORT:-8000}"
