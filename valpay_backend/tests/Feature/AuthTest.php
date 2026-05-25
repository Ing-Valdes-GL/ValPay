<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Jean Dupont',
            'email' => 'jean@test.cm',
            'phone_number' => '+237699123456',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email', 'wallet']]);
    }

    public function test_user_can_login(): void
    {
        $user = User::factory()->create([
            'phone_number' => '+237699123456',
            'password' => bcrypt('Password123!'),
        ]);
        $user->wallet()->create(['balance' => 0, 'currency' => 'XAF']);

        $response = $this->postJson('/api/v1/auth/login', [
            'phone_number' => '+237699123456',
            'password' => 'Password123!',
        ]);

        $response->assertOk()->assertJsonStructure(['token', 'user']);
    }

    public function test_login_fails_with_wrong_credentials(): void
    {
        $this->postJson('/api/v1/auth/login', [
            'phone_number' => '+237699123456',
            'password' => 'wrong_password',
        ])->assertStatus(401);
    }
}
