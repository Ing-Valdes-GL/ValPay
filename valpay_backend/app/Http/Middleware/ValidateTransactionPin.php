<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class ValidateTransactionPin
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (!$user->pin_code) {
            return response()->json([
                'message' => 'Vous devez définir un code PIN avant d\'effectuer des transactions.',
                'code' => 'PIN_NOT_SET',
            ], 403);
        }

        return $next($request);
    }
}
