<?php

namespace App\Actions\Health;

use App\Enums\AccessAction;
use App\Models\Booking;
use App\Models\PatientProfile;
use App\Models\User;
use App\Services\Health\AccessLogger;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\Gate;

/**
 * Seul point d'entrée pour lire les données de santé d'un profil patient :
 * vérifie le droit d'accès (cloisonnement par mission) puis journalise la lecture.
 */
class ReadPatientRecord
{
    public function __construct(private readonly AccessLogger $logger) {}

    /**
     * @throws AuthorizationException
     */
    public function handle(User $actor, PatientProfile $profile, ?Booking $booking = null): PatientProfile
    {
        Gate::forUser($actor)->authorize('viewHealthData', $profile);

        $this->logger->record(AccessAction::View, $profile, $profile->getKey(), $booking?->getKey(), $actor);

        return $profile;
    }
}
