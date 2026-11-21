<?php

namespace App\Actions\Bookings;

use App\Enums\BookingStatus;
use App\Enums\Permission;
use App\Events\BookingStatusChanged;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Machine à états des réservations : seul endroit où `bookings.status` change.
 *
 * Vérifie que la transition existe, que l'auteur y est autorisé, écrit l'historique
 * horodaté et attribué, puis émet l'événement temps réel.
 */
class TransitionBooking
{
    /**
     * @param  array<string, mixed>  $meta
     */
    public function handle(Booking $booking, BookingStatus $target, User $actor, ?string $reason = null, array $meta = []): Booking
    {
        return DB::transaction(function () use ($booking, $target, $actor, $reason, $meta) {
            // Verrou de ligne : deux transitions concurrentes ne peuvent pas partir du même statut.
            $booking = Booking::query()->lockForUpdate()->findOrFail($booking->getKey());
            $from = $booking->status;

            if (! $from->canTransitionTo($target)) {
                throw new ApiException('transition_not_allowed', 409, ['from' => $from->value, 'to' => $target->value]);
            }

            // L'affectation désigne un professionnel : son identifiant est obligatoire.
            $assignee = $target === BookingStatus::Assigned ? ($meta['professional_id'] ?? null) : null;

            if ($target === BookingStatus::Assigned && ! is_string($assignee)) {
                throw new ApiException('professional_required');
            }

            if (! $this->actorMay($actor, $booking, $from, $target, $assignee)) {
                throw new ApiException('transition_forbidden', 403, ['from' => $from->value, 'to' => $target->value]);
            }

            $booking->status = $target;

            if ($assignee !== null) {
                $booking->professional_id = $assignee;
            }

            if ($target === BookingStatus::Cancelled) {
                $booking->cancelled_by = $actor->getKey();
                $booking->cancellation_reason = $reason;
            }

            // Retour en recherche de professionnel : l'affectation est levée.
            if ($target === BookingStatus::Confirmed && in_array($from, [BookingStatus::Assigned, BookingStatus::EnRoute], true)) {
                $meta['previous_professional_id'] = $booking->professional_id;
                $booking->professional_id = null;
            }

            $booking->save();

            $booking->statusHistory()->create([
                'from_status' => $from,
                'to_status' => $target,
                'actor_id' => $actor->getKey(),
                'actor_role' => $actor->primaryRole(),
                'reason' => $reason,
                'meta' => $meta ?: null,
            ]);

            DB::afterCommit(fn () => BookingStatusChanged::dispatch($booking->getKey(), $from->value, $target->value));

            return $booking;
        });
    }

    private function actorMay(User $actor, Booking $booking, BookingStatus $from, BookingStatus $target, ?string $assignee): bool
    {
        $isBooker = $booking->user_id === $actor->getKey();
        $actorProfessionalId = $actor->professional()->value('id');
        $isAssignedProfessional = $booking->professional_id !== null
            && $booking->professional_id === $actorProfessionalId;

        // Un professionnel ne s'affecte lui-même que s'il répond à une offre de mission en attente.
        $acceptsOwnOffer = $assignee !== null
            && $assignee === $actorProfessionalId
            && DB::table('booking_offers')
                ->where('booking_id', $booking->getKey())
                ->where('professional_id', $assignee)
                ->where('status', 'pending')
                ->where(fn ($query) => $query->whereNull('expires_at')->orWhere('expires_at', '>', now()))
                ->exists();

        return match ($target) {
            // Décision du 2026-11-21 : la confirmation est toujours faite par la coordination.
            BookingStatus::Confirmed => $from === BookingStatus::Pending
                ? $actor->can(Permission::BookingsConfirm->value)
                : ($from === BookingStatus::Assigned && $isAssignedProfessional) || $actor->can(Permission::BookingsAssign->value),

            BookingStatus::Assigned => $acceptsOwnOffer || $actor->can(Permission::BookingsAssign->value),

            BookingStatus::EnRoute, BookingStatus::InProgress => $isAssignedProfessional || $actor->can(Permission::BookingsAssign->value),

            BookingStatus::Completed => $from === BookingStatus::Disputed
                ? $actor->can(Permission::DisputesManage->value)
                : $isAssignedProfessional || $actor->can(Permission::BookingsAssign->value),

            BookingStatus::Cancelled => $from === BookingStatus::Disputed
                ? $actor->can(Permission::DisputesManage->value)
                : $isBooker || $actor->can(Permission::BookingsCancel->value),

            BookingStatus::Disputed => $actor->can(Permission::DisputesManage->value),

            BookingStatus::Pending => false,
        };
    }
}
