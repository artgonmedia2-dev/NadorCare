<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Position du professionnel pendant le trajet, diffusée sur le canal privé de la réservation :
 * seuls le demandeur, le professionnel affecté et la coordination peuvent l'écouter.
 */
class ProfessionalLocationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets;

    public function __construct(
        public readonly string $bookingId,
        public readonly float $latitude,
        public readonly float $longitude,
        public readonly ?int $etaSeconds,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('bookings.'.$this->bookingId);
    }

    public function broadcastAs(): string
    {
        return 'booking.location-updated';
    }

    /**
     * @return array{booking_id: string, latitude: float, longitude: float, eta_seconds: int|null, at: string}
     */
    public function broadcastWith(): array
    {
        return [
            'booking_id' => $this->bookingId,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'eta_seconds' => $this->etaSeconds,
            'at' => now()->toIso8601String(),
        ];
    }
}
