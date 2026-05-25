<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function __construct(private WalletService $walletService) {}

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'phone_number' => ['required', 'string', 'unique:users', 'regex:/^\+237[0-9]{9}$/'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        $user = User::create($validated);
        $this->walletService->createForUser($user);

        $token = $user->createToken('valpay_token')->plainTextToken;

        return response()->json([
            'message' => 'Compte créé avec succès.',
            'user' => $user->load('wallet'),
            'token' => $token,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'phone_number' => 'required|string',
            'password' => 'required|string',
        ]);

        if (!Auth::attempt(['phone_number' => $request->phone_number, 'password' => $request->password])) {
            return response()->json(['message' => 'Identifiants incorrects.'], 401);
        }

        $user = Auth::user();
        $token = $user->createToken('valpay_token')->plainTextToken;

        return response()->json([
            'user' => $user->load('wallet'),
            'token' => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Déconnecté avec succès.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json($request->user()->load('wallet'));
    }

    public function setPin(Request $request): JsonResponse
    {
        $request->validate([
            'pin' => 'required|digits:4|confirmed',
        ]);

        $request->user()->update(['pin_code' => $request->pin]);

        return response()->json(['message' => 'Code PIN défini avec succès.']);
    }

    public function updatePin(Request $request): JsonResponse
    {
        $request->validate([
            'current_pin' => 'required|digits:4',
            'pin' => 'required|digits:4|confirmed',
        ]);

        if (!Hash::check($request->current_pin, $request->user()->pin_code)) {
            return response()->json(['message' => 'Code PIN actuel incorrect.'], 422);
        }

        $request->user()->update(['pin_code' => $request->pin]);

        return response()->json(['message' => 'Code PIN mis à jour.']);
    }
}
