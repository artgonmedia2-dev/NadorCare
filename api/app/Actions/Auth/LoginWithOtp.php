<?php

namespace App\Actions\Auth;

use App\Enums\ClientApp;
use App\Enums\Role;
use App\Enums\UserStatus;
use App\Exceptions\ApiException;
use App\Models\Consent;
use App\Models\User;
use App\Services\Auth\OtpService;
use Illuminate\Support\Facades\DB;

/**
 * Connexion ou inscription par téléphone + code OTP.
 *
 * Un numéro inconnu crée un compte, à condition que les conditions générales, la politique de
 * confidentialité et le traitement des données de santé aient été acceptés : le consentement
 * est daté et conservé (loi 09-08).
 */
class LoginWithOtp
{
    public function __construct(private readonly OtpService $otp) {}

    /**
     * @return array{user: User, token: string, is_new_user: bool}
     */
    public function handle(
        string $phone,
        string $code,
        ClientApp $app,
        string $deviceName,
        bool $acceptTerms = false,
        ?string $locale = null,
        ?string $ip = null,
        ?string $userAgent = null,
    ): array {
        $otp = $this->otp->check($phone, $code);

        $user = User::query()->where('phone', $phone)->first();

        if ($user && ! $user->isActive()) {
            throw new ApiException('account_suspended', 403);
        }

        // Modèle « agence » (2026-11-23) : seul un numéro que l'agence a rattaché à son équipe ouvre
        // l'application professionnel. Personne ne s'y inscrit seul. L'état est relu en base.
        if ($app === ClientApp::Pro && ! ($user && $user->professional()->exists())) {
            throw new ApiException('pro_account_unknown', 403);
        }

        // Le code reste valable : l'application le renvoie avec accept_terms = true.
        if (! $user && ! $acceptTerms) {
            throw new ApiException('consent_required');
        }

        return DB::transaction(function () use ($otp, $user, $phone, $app, $deviceName, $locale, $ip, $userAgent) {
            $isNew = $user === null;

            if ($isNew) {
                $user = new User([
                    'phone' => $phone,
                    'locale' => $locale ?? app()->getLocale(),
                    'status' => UserStatus::Active,
                ]);
                $user->phone_verified_at = now();
                $user->save();

                $this->recordConsents($user, $app, $ip, $userAgent);
            }

            // Le rôle de l'application est ajouté s'il manque. Les rôles du back-office
            // ne s'obtiennent jamais par ce chemin.
            $role = $app->defaultRole();
            if (! $user->hasRole($role->value)) {
                $user->assignRole($role->value);
            }

            $user->forceFill([
                'last_login_at' => now(),
                'phone_verified_at' => $user->phone_verified_at ?? now(),
            ])->save();

            $this->otp->consume($otp);

            $expiration = config('sanctum.expiration');
            $token = $user->createToken(
                $deviceName,
                [$app->tokenAbility()],
                $expiration ? now()->addMinutes((int) $expiration) : null,
            );

            return ['user' => $user, 'token' => $token->plainTextToken, 'is_new_user' => $isNew];
        });
    }

    private function recordConsents(User $user, ClientApp $app, ?string $ip, ?string $userAgent): void
    {
        $types = [Consent::TYPE_TERMS, Consent::TYPE_PRIVACY];

        if ($app->defaultRole() === Role::Patient) {
            $types[] = Consent::TYPE_HEALTH_DATA;
        }

        foreach ($types as $type) {
            $user->consents()->create([
                'type' => $type,
                'document_version' => config('nadorcare.legal.documents_version'),
                'accepted_at' => now(),
                'ip' => $ip,
                'user_agent' => $userAgent,
            ]);
        }
    }
}
