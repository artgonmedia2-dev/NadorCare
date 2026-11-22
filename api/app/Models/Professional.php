<?php

namespace App\Models;

use App\Enums\VerificationStatus;
use Database\Factories\ProfessionalFactory;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property string $id
 * @property string $user_id
 * @property string $professional_category_id
 * @property VerificationStatus $verification_status
 * @property bool $is_online
 * @property string|null $rating_avg
 * @property-read User $user
 * @property-read ProfessionalCategory $category
 */
class Professional extends Model
{
    /** @use HasFactory<ProfessionalFactory> */
    use HasFactory, HasUlids, SoftDeletes;

    protected $fillable = ['user_id', 'professional_category_id', 'verification_status', 'license_number', 'order_number', 'is_online', 'payout_details'];

    protected $hidden = ['payout_details', 'last_location'];

    protected function casts(): array
    {
        return [
            'verification_status' => VerificationStatus::class,
            'verified_at' => 'datetime',
            'is_online' => 'boolean',
            'last_location_at' => 'datetime',
            'payout_details' => 'encrypted:array',
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
     * @return BelongsTo<ProfessionalCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCategory::class, 'professional_category_id');
    }

    /**
     * Zones que le professionnel accepte de couvrir.
     *
     * @return BelongsToMany<Zone, $this>
     */
    public function zones(): BelongsToMany
    {
        return $this->belongsToMany(Zone::class, 'professional_zone');
    }

    /**
     * @return HasMany<ProfessionalDocument, $this>
     */
    public function documents(): HasMany
    {
        return $this->hasMany(ProfessionalDocument::class);
    }
}
