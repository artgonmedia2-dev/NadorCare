<?php

namespace App\Actions\Assignment;

use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\BookingOffer;
use App\Models\Professional;
use App\Models\User;
use App\Services\Assignment\ProfessionalMatcher;
use App\Services\Notifications\MissionNotifier;
use App\Services\Settings\Settings;
use Illuminate\Support\Facades\DB;

/**
 * Propose une mission à un professionnel, qui a un délai paramétrable pour répondre (§5).
 * Une seule proposition est en attente à la fois pour une réservation.
 */
class OfferMission
{
    public function __construct(
        private readonly ProfessionalMatcher $matcher,
        private readonly MissionNotifier $notifier,
        private readonly Settings $settings,
    ) {}

    public function handle(Booking $booking, Professional $professional, User $actor): BookingOffer
    {
        if ($booking->status !== BookingStatus::Confirmed) {
            throw new ApiException('transition_not_allowed', 409, ['from' => $booking->status->value, 'to' => 'assigned']);
        }

        if (! $this->matcher->isEligible($booking, $professional)) {
            throw new ApiException('professional_not_eligible');
        }

        $offer = DB::transaction(function () use ($booking, $professional, $actor) {
            Booking::query()->whereKey($booking->getKey())->lockForUpdate()->first();

            $pending = BookingOffer::query()
                ->where('booking_id', $booking->getKey())
                ->where('status', BookingOffer::STATUS_PENDING)
                ->where(fn ($query) => $query->whereNull('expires_at')->orWhere('expires_at', '>', now()))
                ->exists();

            if ($pending) {
                throw new ApiException('offer_already_pending', 409);
            }

            $candidate = $this->matcher->candidatesFor($booking, 200)
                ->first(fn ($candidate) => $candidate->professional->getKey() === $professional->getKey());

            return BookingOffer::create([
                'booking_id' => $booking->getKey(),
                'professional_id' => $professional->getKey(),
                'status' => BookingOffer::STATUS_PENDING,
                'source' => 'coordinator',
                'offered_by' => $actor->getKey(),
                'distance_m' => $candidate?->distanceMeters,
                'sent_at' => now(),
                'expires_at' => now()->addSeconds($this->settings->int('offer.response_seconds')),
            ]);
        });

        $this->notifier->missionOffered($professional, $offer->getKey());

        return $offer;
    }
}
