<?php

namespace App\Actions\Patients;

use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\PatientProfile;

/**
 * Retire un profil de patient du compte. Refusé tant qu'un soin est en cours pour ce patient.
 *
 * Le profil est masqué, pas effacé : l'historique des soins et les comptes rendus doivent
 * rester lisibles. L'effacement définitif des données passe par une demande de suppression
 * (droits loi 09-08, tâche 4.13).
 */
class DeletePatientProfile
{
    public function handle(PatientProfile $profile): void
    {
        $hasOpenBooking = $profile->bookings()
            ->whereNotIn('status', [BookingStatus::Completed, BookingStatus::Cancelled])
            ->exists();

        if ($hasOpenBooking) {
            throw new ApiException('profile_in_use', 409);
        }

        $profile->delete();
    }
}
