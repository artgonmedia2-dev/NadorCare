<?php

namespace App\Actions\Assignment;

use App\Actions\Bookings\TransitionBooking;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\BookingOffer;
use App\Models\Professional;
use App\Models\User;
use App\Services\Assignment\ProfessionalMatcher;
use App\Services\Notifications\MissionNotifier;
use Illuminate\Support\Facades\DB;

/**
 * Affectation directe par la coordination : le coordinateur désigne le professionnel,
 * sans attendre son acceptation (« le coordinateur peut toujours forcer un choix », §6).
 *
 * Les conditions obligatoires restent vérifiées : même forcée, une mission ne va jamais
 * à un compte non vérifié, non assuré, d'une autre profession ou déjà occupé.
 */
class AssignProfessional
{
    public function __construct(
        private readonly ProfessionalMatcher $matcher,
        private readonly TransitionBooking $transition,
        private readonly MissionNotifier $notifier,
    ) {}

    public function handle(Booking $booking, Professional $professional, User $actor): Booking
    {
        if (! $this->matcher->isEligible($booking, $professional)) {
            throw new ApiException('professional_not_eligible');
        }

        $booking = DB::transaction(function () use ($booking, $professional, $actor) {
            $assigned = $this->transition->handle(
                $booking,
                BookingStatus::Assigned,
                $actor,
                meta: ['professional_id' => $professional->getKey(), 'mode' => 'direct'],
            );

            // Les propositions encore en attente pour cette réservation n'ont plus d'objet.
            BookingOffer::query()
                ->where('booking_id', $assigned->getKey())
                ->where('status', BookingOffer::STATUS_PENDING)
                ->update(['status' => BookingOffer::STATUS_CANCELLED, 'responded_at' => now()]);

            return $assigned;
        });

        $this->notifier->missionAssigned($professional, $booking->getKey());

        return $booking;
    }
}
