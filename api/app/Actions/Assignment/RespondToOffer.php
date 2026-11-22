<?php

namespace App\Actions\Assignment;

use App\Actions\Bookings\TransitionBooking;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\BookingOffer;
use App\Models\User;
use App\Services\Assignment\ProfessionalMatcher;
use Illuminate\Support\Facades\DB;

/**
 * Réponse d'un professionnel à une proposition de mission : il accepte ou il refuse.
 */
class RespondToOffer
{
    public function __construct(
        private readonly TransitionBooking $transition,
        private readonly ProfessionalMatcher $matcher,
    ) {}

    public function accept(BookingOffer $offer, User $actor): Booking
    {
        return DB::transaction(function () use ($offer, $actor) {
            $offer = $this->lockOpen($offer);
            $booking = $offer->booking;

            // Entre la proposition et la réponse, l'assurance a pu expirer ou une autre mission arriver.
            if (! $this->matcher->isEligible($booking, $offer->professional)) {
                throw new ApiException('professional_not_eligible');
            }

            $assigned = $this->transition->handle(
                $booking,
                BookingStatus::Assigned,
                $actor,
                meta: ['professional_id' => $offer->professional_id, 'mode' => 'offer', 'offer_id' => $offer->getKey()],
            );

            $offer->update(['status' => BookingOffer::STATUS_ACCEPTED, 'responded_at' => now()]);

            return $assigned;
        });
    }

    public function decline(BookingOffer $offer, ?string $reason = null): BookingOffer
    {
        return DB::transaction(function () use ($offer, $reason) {
            $offer = $this->lockOpen($offer);
            $offer->update([
                'status' => BookingOffer::STATUS_DECLINED,
                'responded_at' => now(),
                'decline_reason' => $reason,
            ]);

            return $offer;
        });
    }

    /**
     * Verrouille la proposition et vérifie qu'on peut encore y répondre.
     */
    private function lockOpen(BookingOffer $offer): BookingOffer
    {
        $locked = BookingOffer::query()->lockForUpdate()->findOrFail($offer->getKey());

        if (! $locked->isOpen()) {
            throw new ApiException('offer_unavailable', 409);
        }

        return $locked;
    }
}
