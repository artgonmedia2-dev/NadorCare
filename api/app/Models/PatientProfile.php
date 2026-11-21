<?php

namespace App\Models;

use Database\Factories\PatientProfileFactory;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

/**
 * @property string $id
 * @property string $user_id
 * @property string $relationship
 * @property string $first_name
 * @property string $last_name
 * @property Carbon|null $birth_date
 * @property string|null $sex
 * @property string|null $phone
 * @property string|null $care_notes
 * @property-read User $user
 */
class PatientProfile extends Model
{
    /** @use HasFactory<PatientProfileFactory> */
    use HasFactory, HasUlids, SoftDeletes;

    protected $fillable = ['user_id', 'relationship', 'first_name', 'last_name', 'birth_date', 'sex', 'phone', 'care_notes', 'default_address_id'];

    protected function casts(): array
    {
        return [
            'birth_date' => 'date',
            // Donnée de santé : chiffrée au repos.
            'care_notes' => 'encrypted',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(Address::class);
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }
}
