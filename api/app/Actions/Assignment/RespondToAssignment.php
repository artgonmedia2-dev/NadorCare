<?php

namespace App\Actions\Assignment;

use App\Actions\Bookings\TransitionBooking;
use App\Enums\BookingStatus;
use App\Enums\DeclineReason;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Réponse du soignant à une affectation (modèle « agence », décision du 2026-11-23) : il
 * confirme la prise en charge, ou signale son indisponibilité avec un motif. Dans ce second
 * cas la demande retourne à la coordination, qui réaffecte.
 */
class RespondToAssignment
{
    public function __construct(private readonly TransitionBooking $transition) {}

    /**
     * Confirme la prise en charge. Sans effet si elle est déjà confirmée.
     */
    public function confirm(Booking $booking, User $actor): Booking
    {
        return DB::transaction(function () use ($booking, $actor) {
            $locked = $this->lockOwn($booking, $actor);

            if ($locked->status !== BookingStatus::Assigned) {
                throw new ApiException('assignment_not_pending', 409);
            }

            if ($locked->assignment_confirmed_at === null) {
                $locked->assignment_confirmed_at = now();
                $locked->save();
            }

            return $locked;
        });
    }

    /**
     * Signale une indisponibilité, tant que le soignant n'est pas parti. La réservation
     * revient « confirmée », sans soignant ; le motif reste visible de la coordination
     * jusqu'à la prochaine affectation.
     */
    public function decline(Booking $booking, User $actor, DeclineReason $reason, ?string $note = null): Booking
    {
        $note = trim((string) $note);

        if ($reason === DeclineReason::Other && $note === '') {
            throw new ApiException('decline_note_required');
        }

        return DB::transaction(function () use ($booking, $actor, $reason, $note) {
            $locked = $this->lockOwn($booking, $actor);
            $professionalId = $locked->professional_id;

            // La machine à états refuse si le soignant est déjà en route. L'historique ne garde
            // que le motif codé : la précision peut évoquer la santé du soignant.
            $released = $this->transition->handle($locked, BookingStatus::Confirmed, $actor, 'declined:'.$reason->value);

            $released->assignment_declined_at = now();
            $released->assignment_decline_reason = $reason->value;
            $released->assignment_decline_note = $note === '' ? null : $note;
            $released->assignment_declined_by = $professionalId;
            $released->save();

            return $released;
        });
    }

    /**
     * Relit la réservation, verrouillée, et vérifie qu'elle est bien affectée à ce soignant.
     */
    private function lockOwn(Booking $booking, User $actor): Booking
    {
        $locked = Booking::query()->lockForUpdate()->findOrFail($booking->getKey());
        $professionalId = $actor->professional()->value('id');

        if ($professionalId === null || $locked->professional_id !== $professionalId) {
            throw new ApiException('transition_forbidden', 403);
        }

        return $locked;
    }
}
