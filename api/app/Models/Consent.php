<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Consent extends Model
{
    use HasUlids;

    public const TYPE_TERMS = 'cgu';

    public const TYPE_PRIVACY = 'privacy';

    public const TYPE_HEALTH_DATA = 'health_data';

    public $timestamps = false;

    protected $fillable = ['user_id', 'patient_profile_id', 'type', 'document_version', 'accepted_at', 'ip', 'user_agent', 'revoked_at'];

    protected function casts(): array
    {
        return [
            'accepted_at' => 'datetime',
            'revoked_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
