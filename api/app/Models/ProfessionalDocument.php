<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Justificatif d'un professionnel (cahier des charges §3) : identité, diplôme, autorisation
 * d'exercice, inscription à l'Ordre, assurance responsabilité civile professionnelle.
 *
 * @property string $id
 * @property string $professional_id
 * @property string $type
 * @property string $file_id
 * @property Carbon|null $expires_at
 * @property string $status
 */
class ProfessionalDocument extends Model
{
    use HasUlids;

    public const TYPE_RC_INSURANCE = 'rc_insurance';

    public const STATUS_PENDING = 'pending';

    public const STATUS_APPROVED = 'approved';

    public const STATUS_REJECTED = 'rejected';

    public const STATUS_EXPIRED = 'expired';

    protected $fillable = ['professional_id', 'type', 'file_id', 'expires_at', 'status', 'reviewed_by', 'reviewed_at', 'rejection_reason'];

    protected function casts(): array
    {
        return [
            'expires_at' => 'date',
            'reviewed_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Professional, $this>
     */
    public function professional(): BelongsTo
    {
        return $this->belongsTo(Professional::class);
    }
}
