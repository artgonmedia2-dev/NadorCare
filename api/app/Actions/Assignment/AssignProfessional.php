<?php

namespace App\Actions\Assignment;

use App\Actions\Bookings\TransitionBooking;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\User;
use App\Services\Assignment\ProfessionalMatcher;
use App\Services\Notifications\MissionNotifier;
use App\Services\Settings\Settings;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Affectation par la coordination : le coordinateur désigne le soignant, qui a ensuite un
 * délai pour confirmer la prise en charge ou signaler son indisponibilité
 * (`RespondToAssignment`). Passé ce délai, le back-office signale la mission « sans réponse ».
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
        private readonly Settings $settings,
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

            $assigned->assignment_confirm_by = $this->confirmBy($assigned);
            $assigned->assignment_confirmed_at = null;
            // L'indisponibilité signalée par le soignant précédent n'a plus d'objet.
            $assigned->assignment_declined_at = null;
            $assigned->assignment_decline_reason = null;
            $assigned->assignment_decline_note = null;
            $assigned->assignment_declined_by = null;
            $assigned->save();

            return $assigned;
        });

        $this->notifier->missionAssigned($professional, $booking->getKey());

        return $booking;
    }

    /**
     * Heure limite de la confirmation : plus courte pour un soin du jour même (jour de Nador).
     */
    private function confirmBy(Booking $booking): Carbon
    {
        $timezone = (string) config('nadorcare.timezone');
        $sameDay = $booking->scheduled_at->copy()->setTimezone($timezone)->isSameDay(Carbon::now($timezone));

        return Carbon::now()->addMinutes(max(1, $this->settings->int(
            $sameDay ? Settings::ASSIGNMENT_CONFIRM_MINUTES_SAME_DAY : Settings::ASSIGNMENT_CONFIRM_MINUTES_LATER,
        )));
    }
}
