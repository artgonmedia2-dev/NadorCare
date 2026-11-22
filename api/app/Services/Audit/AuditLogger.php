<?php

namespace App\Services\Audit;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * Journal des actions sensibles (cahier des charges §6) : vérification d'un professionnel,
 * contrôle d'un justificatif, suspension… Ne jamais y mettre de donnée de santé.
 */
class AuditLogger
{
    /**
     * @param  array<string, mixed>|null  $old
     * @param  array<string, mixed>|null  $new
     */
    public function record(string $event, Model $subject, ?User $actor = null, ?array $old = null, ?array $new = null): AuditLog
    {
        $request = app()->runningInConsole() && ! app()->runningUnitTests() ? null : request();

        return AuditLog::create([
            'actor_id' => ($actor ?? $request?->user())?->getKey(),
            'event' => $event,
            'auditable_type' => $subject->getMorphClass(),
            'auditable_id' => $subject->getKey(),
            'old_values' => $old,
            'new_values' => $new,
            'ip' => $request?->ip(),
        ]);
    }
}
