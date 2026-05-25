<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'name',
        'email',
        'phone_number',
        'password',
        'pin_code',
    ];

    protected $hidden = [
        'password',
        'pin_code',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'pin_code' => 'hashed',
        ];
    }

    public function wallet()
    {
        return $this->hasOne(Wallet::class);
    }

    public function sentTransactions()
    {
        return $this->hasManyThrough(Transaction::class, Wallet::class, 'user_id', 'sender_wallet_id');
    }

    public function receivedTransactions()
    {
        return $this->hasManyThrough(Transaction::class, Wallet::class, 'user_id', 'receiver_wallet_id');
    }
}
