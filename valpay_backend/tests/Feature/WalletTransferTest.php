<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class WalletTransferTest extends TestCase
{
    use RefreshDatabase;

    private function createUserWithWallet(string $phone, float $balance = 10000): array
    {
        $user = User::factory()->create([
            'phone_number' => $phone,
            'pin_code' => Hash::make('1234'),
        ]);
        $wallet = $user->wallet()->create(['balance' => $balance, 'currency' => 'XAF']);
        return [$user, $wallet];
    }

    public function test_p2p_transfer_debits_fee_from_sender(): void
    {
        [$sender, $senderWallet] = $this->createUserWithWallet('+237699000001', 10100);
        [$recipient, $recipientWallet] = $this->createUserWithWallet('+237699000002', 0);

        $response = $this->actingAs($sender)
            ->postJson('/api/v1/payments/transfer', [
                'recipient_phone' => '+237699000002',
                'amount' => 10000,
                'pin' => '1234',
            ]);

        $response->assertOk();

        // Sender paie 10000 + 100 (1%) = 10100
        $this->assertEquals(0, $senderWallet->fresh()->balance);
        // Recipient reçoit exactement 10000
        $this->assertEquals(10000, $recipientWallet->fresh()->balance);
    }

    public function test_transfer_fails_with_insufficient_balance(): void
    {
        [$sender, $senderWallet] = $this->createUserWithWallet('+237699000001', 500);
        [$recipient, $recipientWallet] = $this->createUserWithWallet('+237699000002', 0);

        $this->actingAs($sender)
            ->postJson('/api/v1/payments/transfer', [
                'recipient_phone' => '+237699000002',
                'amount' => 10000,
                'pin' => '1234',
            ])
            ->assertStatus(422);
    }

    public function test_transfer_fails_with_wrong_pin(): void
    {
        [$sender] = $this->createUserWithWallet('+237699000001', 50000);
        [$recipient] = $this->createUserWithWallet('+237699000002', 0);

        $this->actingAs($sender)
            ->postJson('/api/v1/payments/transfer', [
                'recipient_phone' => '+237699000002',
                'amount' => 1000,
                'pin' => '9999',
            ])
            ->assertStatus(422);
    }
}
