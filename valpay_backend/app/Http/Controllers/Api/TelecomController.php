<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Services\ReloadlyService;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class TelecomController extends Controller
{
    public function __construct(
        private ReloadlyService $reloadly,
        private WalletService $walletService,
    ) {}

    /**
     * Liste les forfaits disponibles pour un opérateur
     */
    public function plans(Request $request): JsonResponse
    {
        $request->validate([
            'operator' => 'required|in:orange_cm,mtn_cm',
            'type' => 'sometimes|in:DATA,VOICE,ALL',
        ]);

        try {
            $plans = $this->reloadly->getPlans(
                $request->operator,
                $request->get('type', 'ALL')
            );

            return response()->json(['plans' => $plans, 'operator' => $request->operator]);
        } catch (\Exception $e) {
            Log::error('Telecom plans fetch failed', ['error' => $e->getMessage()]);
            return response()->json(['message' => 'Impossible de charger les forfaits.'], 503);
        }
    }

    /**
     * Achète un forfait télécom depuis le solde du wallet uniquement
     */
    public function purchase(Request $request): JsonResponse
    {
        $request->validate([
            'operator' => 'required|in:orange_cm,mtn_cm',
            'operator_id' => 'required|integer',
            'amount' => 'required|numeric|min:100',
            'phone' => ['required', 'string', 'regex:/^\+237[0-9]{9}$/'],
            'pin' => 'required|digits:4',
            'plan_name' => 'required|string',
        ]);

        try {
            $transaction = $this->walletService->debitForAirtime(
                $request->user()->wallet,
                $request->amount,
                $request->pin,
                [
                    'operator' => $request->operator,
                    'phone' => $request->phone,
                    'plan_name' => $request->plan_name,
                ]
            );

            // Appel Reloadly pour l'achat effectif
            $result = $this->reloadly->purchasePlan(
                $request->phone,
                $request->operator_id,
                $request->amount
            );

            $transaction->update([
                'status' => 'completed',
                'provider_reference' => $result['transactionId'] ?? null,
            ]);

            return response()->json([
                'message' => "Forfait {$request->plan_name} activé pour {$request->phone}.",
                'transaction' => $transaction->fresh(),
            ]);
        } catch (\RuntimeException $e) {
            // Rembourse si le débit a été effectué mais Reloadly a échoué
            if (isset($transaction) && $transaction->exists) {
                $transaction->markFailed();
                $request->user()->wallet->increment('balance', $request->amount);
            }
            return response()->json(['message' => $e->getMessage()], 422);
        } catch (\Exception $e) {
            if (isset($transaction) && $transaction->exists) {
                $transaction->markFailed();
                $request->user()->wallet->increment('balance', $request->amount);
            }
            Log::error('Telecom purchase failed', ['error' => $e->getMessage()]);
            return response()->json(['message' => 'Échec de l\'achat de forfait.'], 500);
        }
    }
}
