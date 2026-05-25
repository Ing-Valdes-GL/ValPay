<?php

use Illuminate\Support\Facades\Facade;

return [

    'name' => env('APP_NAME', 'ValPay'),
    'env' => env('APP_ENV', 'production'),
    'debug' => (bool) env('APP_DEBUG', false),
    'url' => env('APP_URL', 'http://localhost'),
    'timezone' => env('APP_TIMEZONE', 'Africa/Douala'),
    'locale' => env('APP_LOCALE', 'fr'),
    'fallback_locale' => env('APP_FALLBACK_LOCALE', 'fr'),
    'faker_locale' => env('APP_FAKER_LOCALE', 'fr_CM'),
    'cipher' => 'AES-256-CBC',
    'key' => env('APP_KEY'),
    'previous_keys' => array_filter(
        explode(',', env('APP_PREVIOUS_KEYS', ''))
    ),
    'maintenance' => [
        'driver' => 'file',
    ],
    'providers' => \Illuminate\Support\ServiceProvider::defaultProviders()->merge([
        App\Providers\AppServiceProvider::class,
    ])->toArray(),

];
