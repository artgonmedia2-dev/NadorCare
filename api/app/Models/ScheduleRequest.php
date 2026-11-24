<?php

namespace App\Models;

use App\Enums\ScheduleRequestKind;
use App\Enums\ScheduleRequestStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Demande d'un soignant sur son planning : nouvelle semaine type ou indisponibilité datée.
 * Elle ne se crée et ne se décide que par `Actions\Professionals\ManagePlanning`.
 *
 * @property string $id
 * @property string $professional_id
 * @property ScheduleRequestKind $kind
 * @property ScheduleRequestStatus $status
 * @property Carbon|null $starts_on
 * @property Carbon|null $ends_on
 * @property list<array{weekday: int, start_time: string, end_time: string}>|null $slots
 * @property string|null $note
 * @property string|null $decided_by
 * @property Carbon|null $decided_at
 * @property string|null $decision_note
 * @property Carbon $created_at
 * @property-read Professional $professional
 */
class ScheduleRequest extends Model
{
    use HasUlids;

    protected $fillable = ['professional_id', 'kind', 'starts_on', 'ends_on', 'slots', 'note'];

    protected $attributes = [
        'status' => 'pending',
    ];

    protected function casts(): array
    {
        return [
            'kind' => ScheduleRequestKind::class,
            'status' => ScheduleRequestStatus::class,
            'starts_on' => 'date',
            'ends_on' => 'date',
            'slots' => 'array',
            'note' => 'encrypted',
            'decided_at' => 'datetime',
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
