<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Diffusé sur le canal privé de la réservation. Ne transporte aucune donnée de santé :
 * les clients rechargent le détail par l'API, qui applique les droits d'accès.
 */
class BookingStatusChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets;

    public function __construct(
        public readonly string $bookingId,
        public readonly string $from,
        public readonly string $to,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('bookings.'.$this->bookingId);
    }

    public function broadcastAs(): string
    {
        return 'booking.status-changed';
    }

    /**
     * @return array{booking_id: string, from: string, to: string, at: string}
     */
    public function broadcastWith(): array
    {
        return [
            'booking_id' => $this->bookingId,
            'from' => $this->from,
            'to' => $this->to,
            'at' => now()->toIso8601String(),
        ];
    }
}
