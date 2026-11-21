<?php

namespace App\Policies;

use App\Enums\BookingStatus;
use App\Enums\Permission;
use App\Models\Booking;
use App\Models\PatientProfile;
use App\Models\User;

class PatientProfilePolicy
{
    public function view(User $user, PatientProfile $profile): bool
    {
        return $this->owns($user, $profile)
            || $user->can(Permission::PatientsView->value)
            || $this->hasMissionFor($user, $profile);
    }

    public function update(User $user, PatientProfile $profile): bool
    {
        return $this->owns($user, $profile);
    }

    public function delete(User $user, PatientProfile $profile): bool
    {
        return $this->owns($user, $profile);
    }

    /**
     * Accès aux données de santé du profil (notes de soin, ordonnances, comptes rendus).
     *
     * - le titulaire du compte ;
     * - la coordination, par permission explicite ;
     * - le professionnel affecté, uniquement pendant sa mission (cloisonnement par mission).
     */
    public function viewHealthData(User $user, PatientProfile $profile): bool
    {
        return $this->owns($user, $profile)
            || $user->can(Permission::HealthDataView->value)
            || $this->hasMissionFor($user, $profile);
    }

    private function owns(User $user, PatientProfile $profile): bool
    {
        return $profile->user_id === $user->getKey();
    }

    /**
     * Le professionnel est en mission pour ce patient : réservation affectée, en route ou en cours,
     * ou terminée depuis moins que la fenêtre laissée pour finir le compte rendu.
     */
    private function hasMissionFor(User $user, PatientProfile $profile): bool
    {
        $professionalId = $user->professional()->value('id');

        if (! $professionalId) {
            return false;
        }

        $window = now()->subHours((int) config('nadorcare.health.post_completion_access_hours'));

        return Booking::query()
            ->where('patient_profile_id', $profile->getKey())
            ->where('professional_id', $professionalId)
            ->where(function ($query) use ($window) {
                $query->whereIn('status', BookingStatus::activeMission())
                    ->orWhere(function ($completed) use ($window) {
                        $completed->where('status', BookingStatus::Completed)
                            ->whereHas('statusHistory', fn ($history) => $history
                                ->where('to_status', BookingStatus::Completed)
                                ->where('created_at', '>=', $window));
                    });
            })
            ->exists();
    }
}
