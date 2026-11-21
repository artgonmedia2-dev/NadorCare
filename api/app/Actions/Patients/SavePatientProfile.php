<?php

namespace App\Actions\Patients;

use App\Enums\AccessAction;
use App\Enums\PatientRelationship;
use App\Exceptions\ApiException;
use App\Models\PatientProfile;
use App\Models\User;
use App\Services\Health\AccessLogger;
use Illuminate\Support\Facades\DB;

/**
 * Crée ou modifie un profil de patient. Un compte gère plusieurs profils (soi-même, parent,
 * enfant), mais un seul profil « soi-même ». Chaque écriture est journalisée : le profil
 * porte des données de santé.
 */
class SavePatientProfile
{
    public function __construct(private readonly AccessLogger $logger) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public function create(User $owner, array $data): PatientProfile
    {
        return DB::transaction(function () use ($owner, $data) {
            // Verrou sur le compte : deux créations simultanées ne contournent pas les limites.
            User::query()->whereKey($owner->getKey())->lockForUpdate()->first();

            if ($owner->patientProfiles()->count() >= (int) config('nadorcare.limits.patient_profiles')) {
                throw new ApiException('profile_limit_reached');
            }

            $this->ensureSingleSelfProfile($owner, $data['relationship'] ?? null);

            $profile = $owner->patientProfiles()->create($data);
            $this->logger->record(AccessAction::Create, $profile, $profile->getKey(), actor: $owner);

            return $profile;
        });
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function update(User $actor, PatientProfile $profile, array $data): PatientProfile
    {
        return DB::transaction(function () use ($actor, $profile, $data) {
            $this->ensureSingleSelfProfile($profile->user, $data['relationship'] ?? null, $profile);

            $profile->update($data);
            $this->logger->record(AccessAction::Update, $profile, $profile->getKey(), actor: $actor);

            return $profile;
        });
    }

    private function ensureSingleSelfProfile(User $owner, ?string $relationship, ?PatientProfile $except = null): void
    {
        if ($relationship !== PatientRelationship::Self->value) {
            return;
        }

        $exists = $owner->patientProfiles()
            ->where('relationship', PatientRelationship::Self->value)
            ->when($except, fn ($query) => $query->whereKeyNot($except->getKey()))
            ->exists();

        if ($exists) {
            throw new ApiException('self_profile_exists');
        }
    }
}
