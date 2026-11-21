<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Paramètre de gestion modifiable dans le back-office. La lecture courante passe par
 * App\Services\Settings\Settings, qui connaît les valeurs par défaut.
 *
 * @property string $key
 * @property mixed $value
 */
class Setting extends Model
{
    protected $primaryKey = 'key';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = ['key', 'value'];

    protected function casts(): array
    {
        return ['value' => 'json'];
    }
}
