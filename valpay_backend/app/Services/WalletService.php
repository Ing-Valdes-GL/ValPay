<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class WalletService
{
    private const FEE_RATE = 0.01; // 1%

    /**
     * Crée un portefeuille pour un nouvel utilisateur
     */
    public function createForUser(User $user): Wallet
    {
        return Wallet::create([
            'user_id' => $user->id,
            'balance' => 0.00,
            'currency' => 'XAF',
        ]);
    }

    /**
     * Crédite le portefeuille après confirmation CamPay (dépôt, frais 0%)
     */
    public function credit(Wallet $wallet, float $amount, string $reference, string $provider = 'campay', ?array $metadata = null): Transaction
    {
        return DB::transaction(function () use ($wallet, $amount, $reference, $provider, $metadata) {
            $wallet->lockForUpdate()->find($wallet->id);
            $wallet->increment('balance', $amount);

            return Transaction::create([
                'reference' => $reference,
                'receiver_wallet_id' => $wallet->id,
                'type' => 'deposit',
                'amount' => $amount,
                'fee' => 0.00,
                'net_amount' => $amount,
                'status' => 'completed',
                'provider' => $provider,
                'metadata' => $metadata,
            ]);
        });
    }

    /**
     * Transfert P2P interne — frais 1% à la charge de l'envoyeur
     * L'envoyeur paie montant + 1%, le récepteur reçoit le montant exact
     */
    public function transfer(Wallet $senderWallet, string $recipientPhone, float $amount, string $pin): Transaction
    {
        $fee = round($amount * self::FEE_RATE, 2);
        $totalDeducted = $amount + $fee;

        if (!$senderWallet->hasSufficientBalance($totalDeducted)) {
            throw new \RuntimeException("Solde insuffisant. Requis: {$totalDeducted} XAF, Disponible: {$senderWallet->balance} XAF");
        }

        if (!Hash::check($pin, $senderWallet->user->pin_code)) {
            throw new \RuntimeException('Code PIN incorrect.');
        }

        $recipient = User::where('phone_number', $recipientPhone)->first();
        if (!$recipient) {
            throw new \RuntimeException("Aucun compte ValPay trouvé pour le numéro {$recipientPhone}");
        }

        $recipientWallet = $recipient->wallet;
        if (!$recipientWallet) {
            throw new \RuntimeException("Le destinataire n'a pas de portefeuille actif.");
        }

        return DB::transaction(function () use ($senderWallet, $recipientWallet, $amount, $fee, $totalDeducted) {
            // Lock both wallets to prevent race conditions
            Wallet::lockForUpdate()->whereIn('id', [$senderWallet->id, $recipientWallet->id])->get();

            $senderWallet->decrement('balance', $totalDeducted);
            $recipientWallet->increment('balance', $amount);

            return Transaction::create([
                'reference' => Transaction::generateReference(),
                'sender_wallet_id' => $senderWallet->id,
                'receiver_wallet_id' => $recipientWallet->id,
                'type' => 'p2p_transfer',
                'amount' => $amount,
                'fee' => $fee,
                'net_amount' => $amount,
                'status' => 'completed',
                'provider' => 'internal',
                'metadata' => ['recipient_phone' => $recipientWallet->user->phone_number],
            ]);
        });
    }

    /**
     * Initie un retrait — frais 1% déduits du portefeuille
     */
    public function initiateWithdrawal(Wallet $wallet, float $amount, string $phone, string $pin): Transaction
    {
        $fee = round($amount * self::FEE_RATE, 2);
        $totalDeducted = $amount + $fee;

        if (!$wallet->hasSufficientBalance($totalDeducted)) {
            throw new \RuntimeException("Solde insuffisant. Requis: {$totalDeducted} XAF");
        }

        if (!Hash::check($pin, $wallet->user->pin_code)) {
            throw new \RuntimeException('Code PIN incorrect.');
        }

        return DB::transaction(function () use ($wallet, $amount, $fee, $totalDeducted, $phone) {
            Wallet::lockForUpdate()->find($wallet->id);

            $wallet->decrement('balance', $totalDeducted);

            return Transaction::create([
                'reference' => Transaction::generateReference(),
                'sender_wallet_id' => $wallet->id,
                'type' => 'withdrawal',
                'amount' => $amount,
                'fee' => $fee,
                'net_amount' => $amount,
                'status' => 'pending',
                'provider' => 'campay',
                'metadata' => ['destination_phone' => $phone],
            ]);
        });
    }

}
