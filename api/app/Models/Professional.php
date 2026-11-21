<?php

namespace App\Models;

use App\Enums\VerificationStatus;
use Database\Factories\ProfessionalFactory;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

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

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCategory::class, 'professional_category_id');
    }
}
