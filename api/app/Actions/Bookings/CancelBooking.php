<?php

namespace App\Actions\Bookings;

use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\User;
use App\Services\Settings\Settings;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;

/**
 * Annulation d'une réservation (cahier des charges §4) : gratuite jusqu'à un délai paramétrable
 * avant le créneau, avec des frais au-delà.
 *
 * Le taux des frais vaut 0 % par défaut : son montant et la façon de les percevoir quand le
 * paiement est prévu en espèces restent à décider par le client.
 */
class CancelBooking
{
    public function __construct(
        private readonly TransitionBooking $transition,
        private readonly Settings $settings,
    ) {}

    public function handle(Booking $booking, User $actor, ?string $reason = null): Booking
    {
        return DB::transaction(function () use ($booking, $actor, $reason) {
            $fee = $this->feeFor($booking);

            $booking = $this->transition->handle($booking, BookingStatus::Cancelled, $actor, $reason, ['cancellation_fee' => $fee]);
            $booking->forceFill(['cancellation_fee' => $fee])->save();

            return $booking;
        });
    }

    /**
     * Dernier moment pour annuler sans frais.
     */
    public function freeUntil(Booking $booking): CarbonInterface
    {
        return $booking->scheduled_at->copy()->subMinutes($this->settings->int(Settings::FREE_CANCELLATION_MINUTES));
    }

    /**
     * Frais dus si la réservation était annulée maintenant, en centimes.
     * Une demande que la coordination n'a pas encore confirmée s'annule toujours sans frais.
     */
    public function feeFor(Booking $booking): int
    {
        if ($booking->status === BookingStatus::Pending || now()->lessThanOrEqualTo($this->freeUntil($booking))) {
            return 0;
        }

        return (int) round($booking->total_price * $this->settings->int(Settings::LATE_CANCELLATION_FEE_PERCENT) / 100);
    }
}
