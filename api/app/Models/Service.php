<?php

namespace App\Models;

use Database\Factories\ServiceFactory;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property string $id
 * @property array<string, string> $name
 * @property array<string, string>|null $description
 * @property string $slug
 * @property int $duration_minutes
 * @property int $base_price
 * @property bool $requires_prescription
 * @property bool $allows_series
 * @property bool $is_active
 * @property-read ServiceCategory $category
 * @property-read ProfessionalCategory $professionalCategory
 */
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

    /**
     * @return BelongsTo<ServiceCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class, 'service_category_id');
    }

    /**
     * @return BelongsTo<ProfessionalCategory, $this>
     */
    public function professionalCategory(): BelongsTo
    {
        return $this->belongsTo(ProfessionalCategory::class);
    }
}
