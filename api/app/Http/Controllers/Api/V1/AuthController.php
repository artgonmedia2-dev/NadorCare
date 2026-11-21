<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Auth\LoginWithOtp;
use App\Enums\ClientApp;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\RequestOtpRequest;
use App\Http\Requests\Api\V1\VerifyOtpRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Services\Auth\OtpService;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

#[Group('Authentification', weight: 1)]
class AuthController extends Controller
{
    /**
     * Demander un code OTP
     *
     * Envoie un code à usage unique par SMS. La réponse est identique que le numéro
     * ait déjà un compte ou non.
     *
     * @unauthenticated
     */
    public function requestOtp(RequestOtpRequest $request, OtpService $otp): JsonResponse
    {
        $ttl = $otp->send($request->validated('phone'), ip: $request->ip());

        return response()->json([
            'message' => __('api.otp.sent'),
            /** Durée de validité du code, en secondes. */
            'expires_in' => $ttl,
            /** Délai avant de pouvoir redemander un code, en secondes. */
            'resend_in' => (int) config('nadorcare.otp.resend_seconds'),
        ], 202);
    }

    /**
     * Vérifier le code et se connecter
     *
     * Renvoie un jeton d'accès à transmettre ensuite dans l'en-tête `Authorization: Bearer`.
     * Pour un numéro inconnu, `accept_terms` doit valoir `true` : le compte est alors créé
     * et le consentement enregistré. Sinon l'erreur `consent_required` est renvoyée et le
     * même code peut être renvoyé une seconde fois.
     *
     * @unauthenticated
     */
    public function verifyOtp(VerifyOtpRequest $request, LoginWithOtp $login): JsonResponse
    {
        $result = $login->handle(
            phone: $request->validated('phone'),
            code: $request->validated('code'),
            app: ClientApp::from($request->validated('app')),
            deviceName: $request->validated('device_name'),
            acceptTerms: $request->boolean('accept_terms'),
            locale: $request->validated('locale'),
            ip: $request->ip(),
            userAgent: $request->userAgent(),
        );

        return response()->json([
            'token' => $result['token'],
            'token_type' => 'Bearer',
            'is_new_user' => $result['is_new_user'],
            'user' => new UserResource($result['user']),
        ]);
    }

    /**
     * Se déconnecter
     *
     * Révoque le jeton utilisé pour cette requête.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => __('api.auth.logged_out')]);
    }
}
