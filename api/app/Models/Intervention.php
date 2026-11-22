<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * Intervention au domicile : une par réservation réalisée (cahier des charges §9).
 *
 * @property string $id
 * @property string $booking_id
 * @property string $professional_id
 * @property Carbon|null $arrived_at
 * @property Carbon|null $ended_at
 * @property string $status
 * @property-read Booking $booking
 */
class Intervention extends Model
{
    use HasUlids;

    public const STATUS_IN_PROGRESS = 'in_progress';

    public const STATUS_VALIDATED = 'validated';

    protected $fillable = ['booking_id', 'professional_id', 'arrived_at', 'ended_at', 'status'];

    protected $hidden = ['arrival_location', 'end_location'];

    protected function casts(): array
    {
        return [
            'arrived_at' => 'datetime',
            'ended_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Booking, $this>
     */
    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    /**
     * Compte rendu et ses avenants, du plus ancien au plus récent.
     *
     * @return HasMany<InterventionReport, $this>
     */
    public function reports(): HasMany
    {
        return $this->hasMany(InterventionReport::class)->orderBy('version');
    }
}
