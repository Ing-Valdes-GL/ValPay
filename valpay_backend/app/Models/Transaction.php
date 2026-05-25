<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasUuids;

    protected $fillable = [
        'reference',
        'sender_wallet_id',
        'receiver_wallet_id',
        'type',
        'amount',
        'fee',
        'net_amount',
        'status',
        'provider',
        'provider_reference',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'fee' => 'decimal:2',
            'net_amount' => 'decimal:2',
            'metadata' => 'array',
        ];
    }

    public function senderWallet()
    {
        return $this->belongsTo(Wallet::class, 'sender_wallet_id');
    }

    public function receiverWallet()
    {
        return $this->belongsTo(Wallet::class, 'receiver_wallet_id');
    }

    public static function generateReference(): string
    {
        return 'VP-' . date('Ymd') . '-' . strtoupper(substr(uniqid(), -8));
    }

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function markCompleted(): void
    {
        $this->update(['status' => 'completed']);
    }

    public function markFailed(): void
    {
        $this->update(['status' => 'failed']);
    }
}
