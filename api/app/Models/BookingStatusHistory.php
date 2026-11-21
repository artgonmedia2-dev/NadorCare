<?php

namespace App\Models;

use App\Enums\BookingStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Historique des statuts d'une réservation. En insertion seule (déclencheur PostgreSQL).
 */
class BookingStatusHistory extends Model
{
    use HasUlids;

    public const UPDATED_AT = null;

    protected $table = 'booking_status_history';

    protected $fillable = ['booking_id', 'from_status', 'to_status', 'actor_id', 'actor_role', 'reason', 'meta'];

    protected function casts(): array
    {
        return [
            'from_status' => BookingStatus::class,
            'to_status' => BookingStatus::class,
            'meta' => 'array',
            'created_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }
}
