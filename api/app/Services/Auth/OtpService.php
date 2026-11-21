<?php

namespace App\Services\Auth;

use App\Contracts\SmsGateway;
use App\Exceptions\ApiException;
use App\Models\OtpCode;
use Illuminate\Support\Facades\DB;

/**
 * Génération, envoi et vérification des codes OTP.
 * Le code n'est jamais stocké en clair : seule son empreinte HMAC est conservée.
 */
class OtpService
{
    public function __construct(private readonly SmsGateway $sms) {}

    /**
     * Envoie un nouveau code au numéro donné. Renvoie sa durée de validité en secondes.
     */
    public function send(string $phone, string $purpose = 'login', ?string $ip = null): int
    {
        $resend = (int) config('nadorcare.otp.resend_seconds');
        $ttl = (int) config('nadorcare.otp.ttl_seconds');

        $latest = OtpCode::query()
            ->where('phone', $phone)->where('purpose', $purpose)->whereNull('consumed_at')
            ->latest('created_at')->first();

        if ($latest && $latest->created_at->diffInSeconds(now()) < $resend) {
            $retryAfter = (int) ceil($resend - $latest->created_at->diffInSeconds(now()));

            throw new ApiException('otp_too_soon', 429, ['retry_after' => $retryAfter], ['seconds' => $retryAfter]);
        }

        $code = $this->generateCode();

        DB::transaction(function () use ($phone, $purpose, $code, $ttl, $ip) {
            // Un seul code actif par numéro : les précédents sont invalidés.
            OtpCode::query()->where('phone', $phone)->where('purpose', $purpose)->whereNull('consumed_at')->delete();

            OtpCode::create([
                'phone' => $phone,
                'purpose' => $purpose,
                'code_hash' => $this->hash($phone, $code),
                'expires_at' => now()->addSeconds($ttl),
                'ip' => $ip,
            ]);
        });

        $this->sms->send($phone, __('api.otp.sms', ['code' => $code, 'minutes' => (int) ceil($ttl / 60)]));

        return $ttl;
    }

    /**
     * Vérifie un code sans le consommer. Lève une ApiException s'il est faux, expiré ou bloqué.
     */
    public function check(string $phone, string $code, string $purpose = 'login'): OtpCode
    {
        $otp = OtpCode::query()
            ->where('phone', $phone)->where('purpose', $purpose)->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->latest('created_at')->first();

        if (! $otp) {
            throw new ApiException('otp_invalid');
        }

        if ($otp->attempts >= (int) config('nadorcare.otp.max_attempts')) {
            throw new ApiException('otp_locked', 429);
        }

        if (! $this->matches($phone, $code, $otp)) {
            $otp->increment('attempts');

            throw new ApiException('otp_invalid');
        }

        return $otp;
    }

    public function consume(OtpCode $otp): void
    {
        $otp->forceFill(['consumed_at' => now()])->save();
    }

    private function matches(string $phone, string $code, OtpCode $otp): bool
    {
        $static = config('nadorcare.otp.static_code');

        if (! app()->isProduction() && is_string($static) && $static !== '' && hash_equals($static, $code)) {
            return true;
        }

        return hash_equals($otp->code_hash, $this->hash($phone, $code));
    }

    private function generateCode(): string
    {
        $length = max(4, (int) config('nadorcare.otp.length'));

        return str_pad((string) random_int(0, (10 ** $length) - 1), $length, '0', STR_PAD_LEFT);
    }

    private function hash(string $phone, string $code): string
    {
        return hash_hmac('sha256', $phone.'|'.$code, (string) config('app.key'));
    }
}
