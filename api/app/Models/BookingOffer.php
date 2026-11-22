<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Proposition de mission faite à un professionnel, avec un délai de réponse (cahier des charges §5).
 *
 * @property string $id
 * @property string $booking_id
 * @property string $professional_id
 * @property string $status
 * @property string $source
 * @property int|null $distance_m
 * @property Carbon|null $sent_at
 * @property Carbon|null $expires_at
 * @property Carbon|null $responded_at
 * @property-read Booking $booking
 * @property-read Professional $professional
 */
class BookingOffer extends Model
{
    use HasUlids;

    public const STATUS_PENDING = 'pending';

    public const STATUS_ACCEPTED = 'accepted';

    public const STATUS_DECLINED = 'declined';

    public const STATUS_EXPIRED = 'expired';

    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'booking_id', 'professional_id', 'status', 'source', 'offered_by', 'score', 'distance_m',
        'sent_at', 'expires_at', 'responded_at', 'decline_reason',
    ];

    protected function casts(): array
    {
        return [
            'sent_at' => 'datetime',
            'expires_at' => 'datetime',
            'responded_at' => 'datetime',
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
     * @return BelongsTo<Professional, $this>
     */
    public function professional(): BelongsTo
    {
        return $this->belongsTo(Professional::class);
    }

    public function isOpen(): bool
    {
        return $this->status === self::STATUS_PENDING && ($this->expires_at === null || $this->expires_at->isFuture());
    }
}
