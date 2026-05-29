<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use SimpleSoftwareIO\QrCode\Facades\QrCode;

class QrCodeController extends Controller
{
    /**
     * Génère un QR code contenant les infos du wallet (pour mobile)
     */
    public function generate(Request $request): Response
    {
        $user = $request->user();
        $wallet = $user->wallet;

        $payload = json_encode([
            'type' => 'valpay_payment',
            'wallet_id' => $wallet->id,
            'name' => $user->name,
            'phone' => $user->phone_number,
            'currency' => $wallet->currency,
        ]);

        $qrCode = QrCode::format('png')
            ->size(300)
            ->errorCorrection('H')
            ->generate($payload);

        return response($qrCode, 200, ['Content-Type' => 'image/png']);
    }

    /**
     * Génère les données du QR code en JSON (pour Flutter)
     */
    public function data(Request $request): JsonResponse
    {
        $user = $request->user();
        $wallet = $user->wallet;

        $frontendUrl = config('app.frontend_url', 'https://valpay-web.vercel.app');
        $paymentLink = "{$frontendUrl}/#/pay/{$wallet->id}";

        return response()->json([
            'wallet_id' => $wallet->id,
            'name' => $user->name,
            'phone' => $user->phone_number,
            'currency' => $wallet->currency,
            'payment_link' => $paymentLink,
            // Le QR encode directement l'URL de paiement :
            // - Un payeur externe scanne → navigateur ouvre la page de paiement
            // - L'app ValPay reconnaît l'URL et pré-remplit le destinataire
            'qr_payload' => $paymentLink,
        ]);
    }
}
