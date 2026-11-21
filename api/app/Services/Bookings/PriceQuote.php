<?php

namespace App\Services\Bookings;

/**
 * Prix d'un soin à un créneau donné : tarif de base et majorations appliquées.
 * Tous les montants sont en centimes de dirham.
 */
final readonly class PriceQuote
{
    /**
     * @param  list<array{surcharge_id: string, type: string, name: array<string, string>, amount: int}>  $surcharges
     */
    public function __construct(
        public int $base,
        public array $surcharges,
    ) {}

    public function surchargesTotal(): int
    {
        return array_sum(array_column($this->surcharges, 'amount'));
    }

    public function total(): int
    {
        return $this->base + $this->surchargesTotal();
    }

    /**
     * Forme conservée avec la réservation : le prix ne change plus si les tarifs évoluent.
     *
     * @return array<string, mixed>
     */
    public function toSnapshot(): array
    {
        return [
            'base' => $this->base,
            'surcharges' => $this->surcharges,
            'total' => $this->total(),
            'currency' => 'MAD',
        ];
    }
}
