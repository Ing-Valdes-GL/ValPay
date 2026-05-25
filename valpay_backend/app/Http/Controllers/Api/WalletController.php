<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function balance(Request $request): JsonResponse
    {
        $wallet = $request->user()->wallet;

        return response()->json([
            'balance' => $wallet->balance,
            'currency' => $wallet->currency,
            'wallet_id' => $wallet->id,
        ]);
    }

    public function transactions(Request $request): JsonResponse
    {
        $wallet = $request->user()->wallet;

        $transactions = Transaction::where(function ($q) use ($wallet) {
            $q->where('sender_wallet_id', $wallet->id)
              ->orWhere('receiver_wallet_id', $wallet->id);
        })
        ->when($request->type, fn($q) => $q->where('type', $request->type))
        ->when($request->status, fn($q) => $q->where('status', $request->status))
        ->when($request->from, fn($q) => $q->where('created_at', '>=', $request->from))
        ->when($request->to, fn($q) => $q->where('created_at', '<=', $request->to))
        ->latest()
        ->paginate(20);

        return response()->json($transactions);
    }

    public function transactionDetail(Request $request, string $reference): JsonResponse
    {
        $wallet = $request->user()->wallet;

        $transaction = Transaction::where('reference', $reference)
            ->where(function ($q) use ($wallet) {
                $q->where('sender_wallet_id', $wallet->id)
                  ->orWhere('receiver_wallet_id', $wallet->id);
            })
            ->firstOrFail();

        return response()->json($transaction);
    }

    public function exportTransactions(Request $request): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $wallet = $request->user()->wallet;

        $transactions = Transaction::where(function ($q) use ($wallet) {
            $q->where('sender_wallet_id', $wallet->id)
              ->orWhere('receiver_wallet_id', $wallet->id);
        })
        ->when($request->from, fn($q) => $q->where('created_at', '>=', $request->from))
        ->when($request->to, fn($q) => $q->where('created_at', '<=', $request->to))
        ->latest()
        ->get();

        $filename = 'valpay_releve_' . date('Ymd_His') . '.csv';

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        return response()->stream(function () use ($transactions, $wallet) {
            $handle = fopen('php://output', 'w');
            fputs($handle, "\xEF\xBB\xBF"); // BOM UTF-8 pour Excel
            fputcsv($handle, ['Référence', 'Date', 'Type', 'Montant (XAF)', 'Frais (XAF)', 'Net (XAF)', 'Statut', 'Sens']);

            foreach ($transactions as $tx) {
                $direction = $tx->sender_wallet_id === $wallet->id ? 'Débit' : 'Crédit';
                fputcsv($handle, [
                    $tx->reference,
                    $tx->created_at->format('d/m/Y H:i'),
                    $tx->type,
                    number_format($tx->amount, 2, ',', ' '),
                    number_format($tx->fee, 2, ',', ' '),
                    number_format($tx->net_amount, 2, ',', ' '),
                    $tx->status,
                    $direction,
                ]);
            }

            fclose($handle);
        }, 200, $headers);
    }
}
