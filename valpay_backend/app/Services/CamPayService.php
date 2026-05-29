<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class CamPayService
{
    private string $baseUrl;
    private string $username;
    private string $password;
    private ?string $token = null;

    public function __construct()
    {
        $this->baseUrl = config('services.campay.base_url');
        $this->username = config('services.campay.username');
        $this->password = config('services.campay.password');
    }

    private function client(): \Illuminate\Http\Client\PendingRequest
    {
        return Http::withHeaders([
            'Accept'          => 'application/json',
            'Content-Type'    => 'application/json',
            'User-Agent'      => 'ValPay/1.0 (+https://valpay.cm)',
        ])->timeout(30);
    }

    private function authenticate(): string
    {
        if ($this->token) {
            return $this->token;
        }

        $response = $this->client()->post("{$this->baseUrl}/token/", [
            'username' => $this->username,
            'password' => $this->password,
        ]);

        if ($response->failed()) {
            throw new \RuntimeException('CamPay authentication failed: ' . $response->body());
        }

        $this->token = $response->json('token');
        return $this->token;
    }

    /**
     * Initie une collecte de fonds (dépôt depuis Mobile Money)
     */
    public function collect(string $phone, float $amount, string $reference, string $description = 'Recharge ValPay'): array
    {
        $token = $this->authenticate();

        $response = $this->client()->withToken($token)
            ->post("{$this->baseUrl}/collect/", [
                'amount' => (string) intval($amount),
                'from' => $phone,
                'description' => $description,
                'external_reference' => $reference,
                'redirect_url' => config('services.campay.redirect_url'),
            ]);

        if ($response->failed()) {
            Log::error('CamPay collect failed', ['phone' => $phone, 'response' => $response->body()]);
            throw new \RuntimeException('CamPay collect request failed: ' . $response->body());
        }

        return $response->json();
    }

    /**
     * Vérifie le statut d'une transaction CamPay
     */
    public function checkStatus(string $campayReference): array
    {
        $token = $this->authenticate();

        $response = $this->client()->withToken($token)
            ->get("{$this->baseUrl}/transaction/{$campayReference}/");

        if ($response->failed()) {
            throw new \RuntimeException('CamPay status check failed: ' . $response->body());
        }

        return $response->json();
    }

    /**
     * Reversement (disbursement) vers Mobile Money — retrait
     */
    public function disburse(string $phone, float $amount, string $description = 'Retrait ValPay'): array
    {
        $token = $this->authenticate();

        $response = $this->client()->withToken($token)
            ->post("{$this->baseUrl}/transfer/", [
                'amount' => (string) intval($amount),
                'to' => $phone,
                'description' => $description,
            ]);

        if ($response->failed()) {
            Log::error('CamPay disburse failed', ['phone' => $phone, 'response' => $response->body()]);
            throw new \RuntimeException('CamPay disburse request failed: ' . $response->body());
        }

        return $response->json();
    }

    /**
     * Valide la signature du webhook CamPay
     */
    public function validateWebhookSignature(string $payload, string $signature): bool
    {
        $secret = config('services.campay.webhook_secret');
        $expected = hash_hmac('sha256', $payload, $secret);
        return hash_equals($expected, $signature);
    }

    /**
     * Récupère le solde disponible chez CamPay
     */
    public function getBalance(): array
    {
        $token = $this->authenticate();

        $response = $this->client()->withToken($token)
            ->get("{$this->baseUrl}/balance/");

        if ($response->failed()) {
            throw new \RuntimeException('CamPay balance check failed');
        }

        return $response->json();
    }
}
