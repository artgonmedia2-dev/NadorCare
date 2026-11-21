<?php

namespace App\Services\Payment;

use App\Contracts\PaymentGateway;
use Illuminate\Support\Str;
use InvalidArgumentException;

/**
 * Fournisseur de paiement factice pour le développement et les tests.
 * Le vrai pilote Payzone le remplacera une fois le contrat signé (PAYMENT_DRIVER=payzone).
 */
class FakePaymentGateway implements PaymentGateway
{
    /** @var list<array{reference: string, amount: int}> */
    public array $refunds = [];

    public function name(): string
    {
        return 'fake';
    }

    public function createSession(string $paymentId, int $amount, string $currency, string $returnUrl, string $locale): PaymentSession
    {
        $reference = 'fake-pay-'.Str::ulid();

        return new PaymentSession(
            providerReference: $reference,
            redirectUrl: $returnUrl.(str_contains($returnUrl, '?') ? '&' : '?').'reference='.$reference,
        );
    }

    public function parseNotification(array $payload, array $headers = []): PaymentResult
    {
        foreach (['event_id', 'reference', 'status', 'amount'] as $key) {
            if (! array_key_exists($key, $payload)) {
                throw new InvalidArgumentException("Notification de paiement incomplète : [$key] manquant.");
            }
        }

        return new PaymentResult(
            eventId: (string) $payload['event_id'],
            providerReference: (string) $payload['reference'],
            status: (string) $payload['status'],
            amount: (int) $payload['amount'],
        );
    }

    public function refund(string $providerReference, int $amount): string
    {
        $this->refunds[] = ['reference' => $providerReference, 'amount' => $amount];

        return 'fake-refund-'.Str::ulid();
    }
}
