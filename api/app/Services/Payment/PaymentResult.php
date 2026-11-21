<?php

namespace App\Services\Payment;

final readonly class PaymentResult
{
    public const STATUS_PAID = 'paid';

    public const STATUS_FAILED = 'failed';

    public const STATUS_CANCELLED = 'cancelled';

    public function __construct(
        public string $eventId,
        public string $providerReference,
        public string $status,
        public int $amount,
    ) {}

    public function isPaid(): bool
    {
        return $this->status === self::STATUS_PAID;
    }
}
