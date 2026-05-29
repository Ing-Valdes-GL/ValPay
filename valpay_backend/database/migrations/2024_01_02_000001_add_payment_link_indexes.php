<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Index GIN sur metadata (jsonb) pour requêtes via_link rapides
        DB::statement('CREATE INDEX IF NOT EXISTS transactions_metadata_gin ON transactions USING GIN (metadata jsonb_path_ops)');

        // Index composite pour les lookups de paiement par lien (type + receiver + status)
        DB::statement('CREATE INDEX IF NOT EXISTS transactions_link_lookup ON transactions (receiver_wallet_id, type, status) WHERE type = \'deposit\'');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS transactions_metadata_gin');
        DB::statement('DROP INDEX IF EXISTS transactions_link_lookup');
    }
};
