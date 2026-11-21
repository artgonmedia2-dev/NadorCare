<?php

namespace App\Services\Health;

use App\Enums\AccessAction;
use App\Models\AccessLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * Écrit le journal des accès aux données de santé (loi 09-08).
 * À appeler à chaque lecture, téléchargement, création, modification ou export d'une donnée de santé.
 */
class AccessLogger
{
    public function record(
        AccessAction $action,
        Model $subject,
        ?string $patientProfileId = null,
        ?string $bookingId = null,
        ?User $actor = null,
    ): AccessLog {
        $request = app()->runningInConsole() && ! app()->runningUnitTests() ? null : request();
        $actor ??= $request?->user();

        return AccessLog::create([
            'actor_id' => $actor?->getKey(),
            'actor_role' => $actor?->primaryRole(),
            'action' => $action,
            'subject_type' => $subject->getMorphClass(),
            'subject_id' => $subject->getKey(),
            'patient_profile_id' => $patientProfileId,
            'booking_id' => $bookingId,
            'ip' => $request?->ip(),
            'user_agent' => $request?->userAgent(),
            'route' => $request?->route()?->getName() ?? $request?->path(),
        ]);
    }
}
