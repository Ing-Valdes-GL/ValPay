<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Services\CamPayService;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function __construct(
        private CamPayService $camPay,
        private WalletService $walletService,
    ) {}

    /**
     * Initie une recharge via CamPay (frais 0%)
     */
    public function deposit(Request $request): JsonResponse
    {
        $request->validate([
            'amount' => 'required|numeric|min:10|max:1000000',
            'phone' => ['required', 'string', 'regex:/^\+237[0-9]{9}$/'],
        ]);

        $user = $request->user();
        $reference = Transaction::generateReference();

        try {
            // Crée la transaction en pending avant d'appeler CamPay
            Transaction::create([
                'reference' => $reference,
                'receiver_wallet_id' => $user->wallet->id,
                'type' => 'deposit',
                'amount' => $request->amount,
                'fee' => 0.00,
                'net_amount' => $request->amount,
                'status' => 'pending',
                'provider' => 'campay',
                'metadata' => ['phone' => $request->phone],
            ]);

            $result = $this->camPay->collect($request->phone, $request->amount, $reference);

            return response()->json([
                'message' => 'Demande de paiement envoyée. Veuillez valider sur votre téléphone.',
                'reference' => $reference,
                'campay_reference' => $result['reference'] ?? null,
                'ussd_code' => $result['ussd_code'] ?? null,
            ]);
        } catch (\Exception $e) {
            Transaction::where('reference', $reference)->update(['status' => 'failed']);
            Log::error('Deposit initiation failed', ['error' => $e->getMessage(), 'user' => $user->id]);
            return response()->json(['message' => 'Échec de la demande de paiement: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Webhook CamPay — reçoit la confirmation de paiement
     * Route publique — sécurisée par signature HMAC
     */
    public function campayWebhook(Request $request): JsonResponse
    {
        $payload = $request->getContent();
        $signature = $request->header('X-CamPay-Signature', '');

        // Skip signature validation in demo mode or when secret is not properly configured
        $secret = config('services.campay.webhook_secret', '');
        $isProperSecret = $secret && !str_starts_with($secret, 'http');
        if ($isProperSecret && !$this->camPay->validateWebhookSignature($payload, $signature)) {
            Log::warning('Invalid CamPay webhook signature', ['ip' => $request->ip()]);
            return response()->json(['message' => 'Signature invalide'], 403);
        }

        $data = $request->json()->all();
        $externalRef = $data['external_reference'] ?? null;
        $status = strtolower($data['status'] ?? '');

        if (!$externalRef) {
            return response()->json(['message' => 'Référence manquante'], 400);
        }

        $transaction = Transaction::where('reference', $externalRef)
            ->where('type', 'deposit')
            ->whereIn('status', ['pending', 'failed'])
            ->first();

        if (!$transaction) {
            return response()->json(['message' => 'Transaction introuvable'], 404);
        }

        if ($status === 'successful') {
            $wallet = $transaction->receiverWallet;
            \Illuminate\Support\Facades\DB::transaction(function () use ($wallet, $transaction, $data) {
                $wallet->lockForUpdate()->find($wallet->id);
                $wallet->increment('balance', $transaction->amount);
                $transaction->update([
                    'status' => 'completed',
                    'metadata' => array_merge((array) ($transaction->metadata ?? []), $data),
                ]);
            });
        } elseif ($status === 'failed') {
            $transaction->markFailed();
        }

        return response()->json(['message' => 'Webhook traité.']);
    }

    /**
     * Transfert P2P interne
     */
    public function transfer(Request $request): JsonResponse
    {
        $request->validate([
            'recipient_phone' => ['required', 'string', 'regex:/^\+237[0-9]{9}$/'],
            'amount' => 'required|numeric|min:100',
            'pin' => 'required|digits:4',
        ]);

        try {
            $transaction = $this->walletService->transfer(
                $request->user()->wallet,
                $request->recipient_phone,
                $request->amount,
                $request->pin,
            );

            return response()->json([
                'message' => 'Transfert effectué avec succès.',
                'transaction' => $transaction,
            ]);
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Initie un retrait vers Mobile Money via CamPay (frais 1%)
     */
    public function withdraw(Request $request): JsonResponse
    {
        $request->validate([
            'amount' => 'required|numeric|min:10',
            'phone' => ['required', 'string', 'regex:/^\+237[0-9]{9}$/'],
            'pin' => 'required|digits:4',
        ]);

        try {
            $transaction = $this->walletService->initiateWithdrawal(
                $request->user()->wallet,
                $request->amount,
                $request->phone,
                $request->pin,
            );
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        // Appel CamPay pour le reversement — si ça échoue, on rembourse le wallet
        try {
            $result = $this->camPay->disburse($request->phone, $request->amount);
            $transaction->update([
                'provider_reference' => $result['reference'] ?? null,
                'status' => isset($result['reference']) ? 'completed' : 'pending',
            ]);

            return response()->json([
                'message' => 'Retrait initié. Les fonds seront crédités sous quelques minutes.',
                'transaction' => $transaction->fresh(),
                'fee' => $transaction->fee,
                'total_debited' => $transaction->amount + $transaction->fee,
            ]);
        } catch (\Exception $e) {
            // CamPay a échoué : rembourser le wallet et marquer failed
            $wallet = $request->user()->wallet;
            \Illuminate\Support\Facades\DB::transaction(function () use ($wallet, $transaction) {
                $wallet->lockForUpdate()->find($wallet->id);
                $wallet->increment('balance', $transaction->amount + $transaction->fee);
                $transaction->update(['status' => 'failed']);
            });
            Log::error('Withdrawal disburse failed', ['error' => $e->getMessage(), 'transaction' => $transaction->reference]);
            return response()->json(['message' => 'Échec du retrait. Votre solde a été restitué.'], 502);
        }
    }

    /**
     * Page de paiement publique par lien — retourne les infos du wallet destinataire
     */
    public function paymentLinkInfo(string $walletId): JsonResponse
    {
        $wallet = \App\Models\Wallet::with('user:id,name')->findOrFail($walletId);

        return response()->json([
            'wallet_id' => $wallet->id,
            'recipient_name' => $wallet->user->name,
            'currency' => $wallet->currency,
        ]);
    }

    /**
     * Traite un paiement depuis un lien public (tiers sans compte ValPay)
     */
    public function payByLink(Request $request, string $walletId): JsonResponse
    {
        $request->validate([
            'amount' => 'required|numeric|min:100',
            'phone' => ['required', 'string', 'regex:/^\+237[0-9]{9}$/'],
            'payer_name' => 'required|string|max:255',
        ]);

        $wallet = \App\Models\Wallet::findOrFail($walletId);
        $reference = Transaction::generateReference();

        try {
            Transaction::create([
                'reference' => $reference,
                'receiver_wallet_id' => $wallet->id,
                'type' => 'deposit',
                'amount' => $request->amount,
                'fee' => 0.00,
                'net_amount' => $request->amount,
                'status' => 'pending',
                'provider' => 'campay',
                'metadata' => ['phone' => $request->phone, 'payer_name' => $request->payer_name, 'via_link' => true],
            ]);

            $result = $this->camPay->collect($request->phone, $request->amount, $reference, "Paiement ValPay à {$wallet->user->name}");

            return response()->json([
                'message' => 'Demande de paiement envoyée.',
                'reference' => $reference,
                'ussd_code' => $result['ussd_code'] ?? null,
            ]);
        } catch (\Exception $e) {
            Transaction::where('reference', $reference)->update(['status' => 'failed']);
            return response()->json(['message' => 'Échec: ' . $e->getMessage()], 500);
        }
    }
}
