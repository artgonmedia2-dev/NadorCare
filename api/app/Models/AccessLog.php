<?php

namespace App\Models;

use App\Enums\AccessAction;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

/**
 * Journal des accès aux données de santé (loi 09-08). En insertion seule.
 */
class AccessLog extends Model
{
    use HasUlids;

    public const UPDATED_AT = null;

    protected $fillable = ['actor_id', 'actor_role', 'action', 'subject_type', 'subject_id', 'patient_profile_id', 'booking_id', 'ip', 'user_agent', 'route'];

    protected function casts(): array
    {
        return [
            'action' => AccessAction::class,
            'created_at' => 'datetime',
        ];
    }
}
