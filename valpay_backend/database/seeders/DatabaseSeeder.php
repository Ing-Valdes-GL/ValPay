<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::factory()->create([
            'name' => 'Valdes Test',
            'email' => 'test@valpay.cm',
            'phone_number' => '+237699000001',
            'password' => Hash::make('password'),
            'pin_code' => Hash::make('1234'),
        ]);

        $user->wallet()->create([
            'balance' => 50000.00,
            'currency' => 'XAF',
        ]);
    }
}
