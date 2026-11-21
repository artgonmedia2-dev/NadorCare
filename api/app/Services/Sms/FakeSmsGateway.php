<?php

namespace App\Services\Sms;

use App\Contracts\SmsGateway;
use App\Support\PhoneNumber;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Passerelle SMS factice : garde les messages en mémoire (pour les tests) et,
 * hors production, les écrit dans le journal pour pouvoir lire un code OTP en développement.
 */
class FakeSmsGateway implements SmsGateway
{
    /** @var list<array{to: string, message: string, id: string}> */
    public array $sent = [];

    public function send(string $to, string $message): string
    {
        $id = 'fake-sms-'.Str::ulid();
        $this->sent[] = ['to' => $to, 'message' => $message, 'id' => $id];

        if (! app()->isProduction()) {
            Log::info('[SMS factice] '.$to.' : '.$message);
        } else {
            Log::warning('[SMS factice] message non envoyé à '.PhoneNumber::mask($to).' : aucun fournisseur configuré');
        }

        return $id;
    }

    public function lastMessageTo(string $phone): ?string
    {
        foreach (array_reverse($this->sent) as $sms) {
            if ($sms['to'] === $phone) {
                return $sms['message'];
            }
        }

        return null;
    }
}
