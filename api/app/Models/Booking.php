<?php

namespace App\Models;

use App\Enums\BookingStatus;
use Database\Factories\BookingFactory;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * @property string $id
 * @property string $reference
 * @property string $user_id
 * @property string $patient_profile_id
 * @property string|null $professional_id
 * @property BookingStatus $status
 * @property string|null $patient_note
 * @property string|null $cancelled_by
 * @property string|null $cancellation_reason
 * @property Carbon $scheduled_at
 * @property Carbon|null $scheduled_end_at
 * @property string $type
 * @property int $base_price
 * @property int $surcharges_total
 * @property int $total_price
 * @property int $cancellation_fee
 * @property string $payment_method
 * @property string|null $prescription_file_id
 * @property array<string, mixed>|null $address_snapshot
 * @property array<string, mixed>|null $price_snapshot
 * @property-read Service $service
 * @property-read PatientProfile $patientProfile
 * @property-read Collection<int, BookingStatusHistory> $statusHistory
 */
class Booking extends Model
{
    /** @use HasFactory<BookingFactory> */
    use HasFactory, HasUlids;

    /**
     * `status` n'est volontairement pas dans cette liste : il ne change que par
     * App\Actions\Bookings\TransitionBooking, qui écrit l'historique.
     */
    protected $fillable = [
        'reference', 'user_id', 'patient_profile_id', 'address_id', 'address_snapshot', 'service_id', 'professional_id',
        'series_id', 'series_index', 'channel', 'created_by', 'type', 'scheduled_at', 'scheduled_end_at',
        'base_price', 'surcharges_total', 'total_price', 'price_snapshot', 'payment_method', 'patient_note',
        'prescription_file_id',
    ];

    protected $attributes = [
        'status' => 'pending',
    ];

    protected function casts(): array
    {
        return [
            'status' => BookingStatus::class,
            'scheduled_at' => 'datetime',
            'scheduled_end_at' => 'datetime',
            'escalated_at' => 'datetime',
            'address_snapshot' => 'array',
            'price_snapshot' => 'array',
            // Donnée de santé : chiffrée au repos.
            'patient_note' => 'encrypted',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<PatientProfile, $this>
     */
    public function patientProfile(): BelongsTo
    {
        return $this->belongsTo(PatientProfile::class);
    }

    /**
     * @return BelongsTo<Service, $this>
     */
    public function service(): BelongsTo
    {
        return $this->belongsTo(Service::class);
    }

    /**
     * @return BelongsTo<Professional, $this>
     */
    public function professional(): BelongsTo
    {
        return $this->belongsTo(Professional::class);
    }

    /**
     * @return HasMany<BookingStatusHistory, $this>
     */
    public function statusHistory(): HasMany
    {
        return $this->hasMany(BookingStatusHistory::class)->orderBy('created_at')->orderBy('id');
    }
}
