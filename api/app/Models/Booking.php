<?php

namespace App\Models;

use App\Enums\BookingStatus;
use Database\Factories\BookingFactory;
use Illuminate\Database\Eloquent\Builder;
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
 * @property string $service_id
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
 * @property Carbon|null $assignment_confirm_by
 * @property Carbon|null $assignment_confirmed_at
 * @property Carbon|null $assignment_declined_at
 * @property string|null $assignment_decline_reason
 * @property string|null $assignment_decline_note
 * @property string|null $assignment_declined_by
 * @property-read Professional|null $professional
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
            'assignment_confirm_by' => 'datetime',
            'assignment_confirmed_at' => 'datetime',
            'assignment_declined_at' => 'datetime',
            // Précision du soignant sur son indisponibilité : peut évoquer sa santé.
            'assignment_decline_note' => 'encrypted',
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
     * Mission affectée dont le soignant n'a pas encore confirmé la prise en charge.
     */
    public function awaitsConfirmation(): bool
    {
        return $this->status === BookingStatus::Assigned && $this->assignment_confirmed_at === null;
    }

    /**
     * Le délai de confirmation est dépassé : la coordination doit relancer ou réaffecter.
     */
    public function confirmationOverdue(): bool
    {
        return $this->awaitsConfirmation()
            && $this->assignment_confirm_by !== null
            && $this->assignment_confirm_by->isPast();
    }

    /**
     * Demande rendue par un soignant indisponible, pas encore réaffectée.
     */
    public function wasDeclined(): bool
    {
        return $this->status === BookingStatus::Confirmed && $this->assignment_declined_at !== null;
    }

    /**
     * Réservations qui demandent une action de la coordination sur l'affectation : rendues par
     * un soignant indisponible, ou restées sans confirmation après le délai.
     *
     * @param  Builder<Booking>  $query
     */
    public function scopeNeedsReassignment(Builder $query): void
    {
        self::constrainToNeedsReassignment($query);
    }

    /**
     * Même condition, pour une requête reçue telle quelle (filtre du back-office).
     *
     * @param  Builder<Booking>  $query
     */
    public static function constrainToNeedsReassignment(Builder $query): void
    {
        $query->where(fn (Builder $either) => $either
            ->where(fn (Builder $declined) => $declined
                ->where('status', BookingStatus::Confirmed)
                ->whereNotNull('assignment_declined_at'))
            ->orWhere(fn (Builder $overdue) => $overdue
                ->where('status', BookingStatus::Assigned)
                ->whereNull('assignment_confirmed_at')
                ->where('assignment_confirm_by', '<', now())));
    }

    /**
     * @return HasMany<BookingStatusHistory, $this>
     */
    public function statusHistory(): HasMany
    {
        return $this->hasMany(BookingStatusHistory::class)->orderBy('created_at')->orderBy('id');
    }
}
