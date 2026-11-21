<?php

namespace App\Models;

use Database\Factories\ServiceFactory;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Service extends Model
{
    /** @use HasFactory<ServiceFactory> */
    use HasFactory, HasUlids, SoftDeletes;

    protected $fillable = [
        'service_category_id', 'professional_category_id', 'specialty_id', 'name', 'slug', 'description',
        'duration_minutes', 'base_price', 'requires_prescription', 'allows_series', 'is_active', 'sort',
    ];

    protected function casts(): array
    {
        return [
            'name' => 'array',
            'description' => 'array',
            'requires_prescription' => 'boolean',
            'allows_series' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class, 'service_category_id');
    }

    public function professionalCategory(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCategory::class);
    }
}
