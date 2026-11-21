<?php

namespace App\Models;

use Clickbar\Magellan\Data\Geometries\Point;
use Database\Factories\AddressFactory;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property string $id
 * @property string $user_id
 * @property string|null $patient_profile_id
 * @property string|null $zone_id
 * @property string $label
 * @property string $line
 * @property string $city
 * @property Point $location
 * @property string|null $access_notes
 * @property-read Zone|null $zone
 */
class Address extends Model
{
    /** @use HasFactory<AddressFactory> */
    use HasFactory, HasUlids, SoftDeletes;

    protected $fillable = ['user_id', 'patient_profile_id', 'label', 'line', 'city', 'location', 'access_notes', 'zone_id'];

    protected function casts(): array
    {
        return [
            'location' => Point::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function zone(): BelongsTo
    {
        return $this->belongsTo(Zone::class);
    }
}
