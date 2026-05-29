<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Convertir metadata de json → jsonb pour activer les index GIN et les opérateurs @>
        // jsonb est supérieur à json pour les requêtes (stockage binaire, déduplication des clés)
        DB::statement('ALTER TABLE transactions ALTER COLUMN metadata TYPE jsonb USING metadata::jsonb');

        // Index GIN sur metadata jsonb pour requêtes sur via_link, payer_name, etc.
        DB::statement('CREATE INDEX IF NOT EXISTS transactions_metadata_gin ON transactions USING GIN (metadata jsonb_path_ops)');

        // Index composite pour les lookups de dépôt par wallet (page de paiement par lien)
        DB::statement("CREATE INDEX IF NOT EXISTS transactions_link_lookup ON transactions (receiver_wallet_id, type, status) WHERE type = 'deposit'");
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS transactions_metadata_gin');
        DB::statement('DROP INDEX IF EXISTS transactions_link_lookup');
        DB::statement('ALTER TABLE transactions ALTER COLUMN metadata TYPE json USING metadata::text::json');
    }
};
