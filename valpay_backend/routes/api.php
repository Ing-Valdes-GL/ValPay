<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\QrCodeController;
use App\Http\Controllers\Api\WalletController;
use Illuminate\Support\Facades\Route;

// Routes publiques
Route::prefix('v1')->group(function () {

    // Authentification
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
    });

    // Webhook CamPay (public, sécurisé par signature HMAC)
    Route::post('payments/campay/webhook', [PaymentController::class, 'campayWebhook'])
        ->name('campay.webhook');

    // Page de paiement par lien (accès public)
    // IMPORTANT: routes spécifiques avant les routes paramétriques
    Route::get('pay/receipt/{reference}', [PaymentController::class, 'downloadReceipt'])
        ->name('payment.receipt');
    Route::get('pay/{walletId}', [PaymentController::class, 'paymentLinkInfo'])
        ->name('payment.link.info');
    Route::get('pay/{walletId}/status/{reference}', [PaymentController::class, 'paymentStatus'])
        ->name('payment.link.status');
    Route::post('pay/{walletId}', [PaymentController::class, 'payByLink'])
        ->name('payment.link.pay');
});

// Routes protégées — authentification Sanctum requise
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {

    // Profil & PIN
    Route::prefix('auth')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
        Route::post('pin', [AuthController::class, 'setPin']);
        Route::post('pin/set', [AuthController::class, 'setPin']);
        Route::put('pin/update', [AuthController::class, 'updatePin']);
    });

    // Portefeuille
    Route::prefix('wallet')->group(function () {
        Route::get('balance', [WalletController::class, 'balance']);
        Route::get('transactions', [WalletController::class, 'transactions']);
        Route::get('transactions/{reference}', [WalletController::class, 'transactionDetail']);
        Route::get('export', [WalletController::class, 'exportTransactions']);
    });

    // QR Code
    Route::prefix('qr')->group(function () {
        Route::get('generate', [QrCodeController::class, 'generate']);
        Route::get('data', [QrCodeController::class, 'data']);
    });

    // Paiements (PIN requis)
    Route::prefix('payments')->middleware('pin')->group(function () {
        Route::post('deposit', [PaymentController::class, 'deposit']);
        Route::post('transfer', [PaymentController::class, 'transfer']);
        Route::post('withdraw', [PaymentController::class, 'withdraw']);
    });

});
