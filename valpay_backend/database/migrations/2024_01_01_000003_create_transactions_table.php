<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('reference')->unique()->comment('Format: VP-YYYYMMDD-RANDOM');
            $table->uuid('sender_wallet_id')->nullable();
            $table->uuid('receiver_wallet_id')->nullable();
            $table->enum('type', ['deposit', 'withdrawal', 'p2p_transfer', 'airtime_purchase']);
            $table->decimal('amount', 15, 2)->comment('Montant brut');
            $table->decimal('fee', 15, 2)->default(0.00)->comment('1% pour retraits et transferts');
            $table->decimal('net_amount', 15, 2)->comment('Montant net reçu');
            $table->enum('status', ['pending', 'completed', 'failed'])->default('pending');
            $table->string('provider')->nullable()->comment('campay, reloadly, internal');
            $table->string('provider_reference')->nullable()->comment('Référence externe du provider');
            $table->json('metadata')->nullable()->comment('Numéro cible, opérateur, etc.');
            $table->timestamps();

            $table->foreign('sender_wallet_id')->references('id')->on('wallets')->nullOnDelete();
            $table->foreign('receiver_wallet_id')->references('id')->on('wallets')->nullOnDelete();
            $table->index(['status', 'created_at']);
            $table->index('type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
