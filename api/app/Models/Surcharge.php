<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

/**
 * Majoration du tarif (cahier des charges §6) : nuit, jour férié, distance.
 *
 * @property string $id
 * @property string $type
 * @property array<string, string> $name
 * @property string $mode
 * @property int $value pourcentage, ou montant en centimes si le mode est « fixed »
 * @property array<string, mixed>|null $config
 * @property bool $is_active
 */
class Surcharge extends Model
{
    use HasUlids;

    public const TYPE_NIGHT = 'night';

    public const TYPE_HOLIDAY = 'holiday';

    public const TYPE_DISTANCE = 'distance';

    public const MODE_PERCENT = 'percent';

    public const MODE_FIXED = 'fixed';

    protected $fillable = ['type', 'name', 'mode', 'value', 'config', 'is_active'];

    protected function casts(): array
    {
        return [
            'name' => 'array',
            'config' => 'array',
            'is_active' => 'boolean',
        ];
    }
}
