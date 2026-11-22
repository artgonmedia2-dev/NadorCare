<?php

namespace App\Actions\Assignment;

use App\Actions\Bookings\TransitionBooking;
use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\User;
use App\Services\Notifications\MissionNotifier;

/**
 * Retire le professionnel d'une réservation : désistement du professionnel, ou réaffectation
 * décidée par la coordination. La réservation revient « confirmée », en recherche de soignant.
 */
class UnassignProfessional
{
    public function __construct(
        private readonly TransitionBooking $transition,
        private readonly MissionNotifier $notifier,
    ) {}

    public function handle(Booking $booking, User $actor, string $reason): Booking
    {
        $previous = $booking->professional_id ? Professional::query()->find($booking->professional_id) : null;

        $released = $this->transition->handle($booking, BookingStatus::Confirmed, $actor, $reason);

        // Le professionnel n'est prévenu que si la décision ne vient pas de lui.
        if ($previous && $previous->user_id !== $actor->getKey()) {
            $this->notifier->missionWithdrawn($previous, $released->getKey());
        }

        return $released;
    }
}
