<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ReloadlyService
{
    private string $baseUrl;
    private string $authUrl;
    private string $clientId;
    private string $clientSecret;

    // IDs opérateurs Reloadly pour le Cameroun
    private const OPERATORS = [
        'orange_cm' => ['name' => 'Orange Cameroun', 'country' => 'CM'],
        'mtn_cm'    => ['name' => 'MTN Cameroun', 'country' => 'CM'],
    ];

    public function __construct()
    {
        $this->baseUrl = config('services.reloadly.base_url');
        $this->authUrl = config('services.reloadly.auth_url');
        $this->clientId = config('services.reloadly.client_id');
        $this->clientSecret = config('services.reloadly.client_secret');
    }

    private function getAccessToken(): string
    {
        return Cache::remember('reloadly_access_token', 3500, function () {
            $response = Http::post("{$this->authUrl}/oauth/token", [
                'client_id' => $this->clientId,
                'client_secret' => $this->clientSecret,
                'grant_type' => 'client_credentials',
                'audience' => $this->baseUrl,
            ]);

            if ($response->failed()) {
                throw new \RuntimeException('Reloadly auth failed: ' . $response->body());
            }

            return $response->json('access_token');
        });
    }

    /**
     * Récupère et met en cache la liste des forfaits disponibles pour le Cameroun
     */
    public function getPlans(string $operatorSlug, string $type = 'DATA'): array
    {
        $cacheKey = "reloadly_plans_{$operatorSlug}_{$type}";

        return Cache::remember($cacheKey, 3600, function () use ($operatorSlug, $type) {
            $token = $this->getAccessToken();

            $operatorId = $this->resolveOperatorId($operatorSlug);
            if (!$operatorId) {
                throw new \InvalidArgumentException("Opérateur inconnu: {$operatorSlug}");
            }

            $response = Http::withToken($token)
                ->withHeaders(['Accept' => 'application/com.reloadly.topups-v1+json'])
                ->get("{$this->baseUrl}/operators/{$operatorId}/bundles");

            if ($response->failed()) {
                Log::error('Reloadly get plans failed', ['operator' => $operatorSlug]);
                throw new \RuntimeException('Reloadly plans fetch failed: ' . $response->body());
            }

            $plans = collect($response->json())->filter(function ($plan) use ($type) {
                return $type === 'ALL' || str_contains(strtoupper($plan['description'] ?? ''), $type);
            });

            return $plans->values()->toArray();
        });
    }

    /**
     * Résout l'ID numérique de l'opérateur Reloadly via son slug
     */
    private function resolveOperatorId(string $slug): ?int
    {
        $cacheKey = "reloadly_operator_id_{$slug}";

        return Cache::remember($cacheKey, 86400, function () use ($slug) {
            $token = $this->getAccessToken();

            $response = Http::withToken($token)
                ->withHeaders(['Accept' => 'application/com.reloadly.topups-v1+json'])
                ->get("{$this->baseUrl}/operators/auto-detect/phone/+237699000000/countries/CM");

            $allOperators = Http::withToken($token)
                ->withHeaders(['Accept' => 'application/com.reloadly.topups-v1+json'])
                ->get("{$this->baseUrl}/operators?countryIsoCode=CM&type=BUNDLE&page=1&size=20")
                ->json('content', []);

            $mapping = [
                'orange_cm' => 'Orange Cameroon',
                'mtn_cm'    => 'MTN Cameroon',
            ];

            foreach ($allOperators as $op) {
                if (isset($mapping[$slug]) && str_contains($op['name'], $mapping[$slug])) {
                    return $op['id'];
                }
            }

            return null;
        });
    }

    /**
     * Effectue l'achat d'un forfait télécom
     */
    public function purchasePlan(string $phone, int $operatorId, float $amount, string $currency = 'XAF'): array
    {
        $token = $this->getAccessToken();

        $response = Http::withToken($token)
            ->withHeaders(['Accept' => 'application/com.reloadly.topups-v1+json'])
            ->post("{$this->baseUrl}/topups", [
                'recipientPhone' => [
                    'countryCode' => 'CM',
                    'number' => $phone,
                ],
                'amount' => $amount,
                'operatorId' => $operatorId,
                'senderCurrencyCode' => $currency,
                'recipientCurrencyCode' => $currency,
            ]);

        if ($response->failed()) {
            Log::error('Reloadly purchase failed', ['phone' => $phone, 'response' => $response->body()]);
            throw new \RuntimeException('Reloadly topup failed: ' . $response->body());
        }

        return $response->json();
    }
}
