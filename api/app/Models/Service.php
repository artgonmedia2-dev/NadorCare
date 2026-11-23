<?php

namespace App\Models;

use App\Enums\DeliveryMode;
use App\Services\Settings\Settings;
use Database\Factories\ServiceFactory;
use Illuminate\Database\Eloquent\Builder;
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
 * @property DeliveryMode $delivery_mode
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
        'delivery_mode',
    ];

    /** Valeur de la colonne quand elle n'est pas renseignée : un soin se fait à domicile. */
    protected $attributes = ['delivery_mode' => 'home'];

    protected function casts(): array
    {
        return [
            'name' => 'array',
            'description' => 'array',
            'requires_prescription' => 'boolean',
            'allows_series' => 'boolean',
            'is_active' => 'boolean',
            'delivery_mode' => DeliveryMode::class,
        ];
    }

    /** Téléconsultation : le soin se fait par appel vidéo, sans déplacement. */
    public function isRemote(): bool
    {
        return $this->delivery_mode === DeliveryMode::Remote;
    }

    /**
     * Services proposés aux patients : actifs, et sans les téléconsultations tant qu'elles
     * ne sont pas ouvertes.
     *
     * @param  Builder<Service>  $query
     */
    public function scopeOffered(Builder $query): void
    {
        self::constrainToOffered($query);
    }

    /**
     * La même règle, pour une requête construite ailleurs (compte des services d'une catégorie).
     *
     * @param  Builder<covariant Model>  $query
     */
    public static function constrainToOffered(Builder $query): void
    {
        $query->where('is_active', true);

        if (! app(Settings::class)->bool(Settings::TELECONSULTATION_ENABLED)) {
            $query->where('delivery_mode', DeliveryMode::Home->value);
        }
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
