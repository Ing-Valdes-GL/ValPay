<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(\App\Services\CamPayService::class);
        $this->app->singleton(\App\Services\ReloadlyService::class);
        $this->app->singleton(\App\Services\WalletService::class);
    }

    public function boot(): void
    {
        //
    }
}
