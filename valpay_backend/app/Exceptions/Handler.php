<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
        'pin',
        'pin_code',
    ];

    public function register(): void
    {
        $this->renderable(function (ModelNotFoundException $e) {
            return response()->json(['message' => 'Ressource introuvable.'], 404);
        });

        $this->renderable(function (NotFoundHttpException $e) {
            return response()->json(['message' => 'Route introuvable.'], 404);
        });

        $this->renderable(function (AuthenticationException $e) {
            return response()->json(['message' => 'Non authentifié. Veuillez vous connecter.'], 401);
        });

        $this->renderable(function (ValidationException $e) {
            return response()->json([
                'message' => 'Données invalides.',
                'errors' => $e->errors(),
            ], 422);
        });
    }
}
