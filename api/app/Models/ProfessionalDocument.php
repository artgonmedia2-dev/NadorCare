<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
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
 * @property string|null $rejection_reason
 * @property-read File|null $file
 * @property-read Professional $professional
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
     * Justificatifs à renouveler : approuvés et arrivant à échéance sous `$days` jours, ou
     * périmés sans remplaçant approuvé du même type.
     *
     * @param  Builder<ProfessionalDocument>  $query
     */
    public static function constrainToNeedsRenewal(Builder $query, int $days): void
    {
        $query->whereNotNull('professional_documents.expires_at')
            ->where(fn (Builder $either) => $either
                ->where(fn (Builder $soon) => $soon
                    ->where('professional_documents.status', self::STATUS_APPROVED)
                    ->whereDate('professional_documents.expires_at', '<=', today()->addDays($days)->format('Y-m-d')))
                ->orWhere(fn (Builder $expired) => $expired
                    ->where('professional_documents.status', self::STATUS_EXPIRED)
                    ->whereRaw('NOT EXISTS (SELECT 1 FROM professional_documents newer
                        WHERE newer.professional_id = professional_documents.professional_id
                        AND newer.type = professional_documents.type
                        AND newer.id <> professional_documents.id
                        AND (newer.status = ? OR newer.created_at > professional_documents.created_at))', [self::STATUS_APPROVED])));
    }

    /**
     * @return BelongsTo<File, $this>
     */
    public function file(): BelongsTo
    {
        return $this->belongsTo(File::class);
    }

    /**
     * @return BelongsTo<Professional, $this>
     */
    public function professional(): BelongsTo
    {
        return $this->belongsTo(Professional::class);
    }
}
