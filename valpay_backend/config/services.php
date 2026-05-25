<?php

return [

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'campay' => [
        'username' => env('CAMPAY_APP_USERNAME'),
        'password' => env('CAMPAY_APP_PASSWORD'),
        'base_url' => env('CAMPAY_BASE_URL', 'https://demo.campay.net/api'),
        'webhook_secret' => env('CAMPAY_WEBHOOK_SECRET'),
        'redirect_url' => env('CAMPAY_REDIRECT_URL'),
    ],

    'reloadly' => [
        'client_id' => env('RELOADLY_CLIENT_ID'),
        'client_secret' => env('RELOADLY_CLIENT_SECRET'),
        'base_url' => env('RELOADLY_BASE_URL', 'https://topups.reloadly.com'),
        'auth_url' => env('RELOADLY_AUTH_URL', 'https://auth.reloadly.com'),
    ],

];
