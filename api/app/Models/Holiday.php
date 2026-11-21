<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

/**
 * Jour férié. Saisi par l'administrateur : les fêtes religieuses changent de date chaque année.
 *
 * @property string $id
 * @property Carbon $date
 * @property array<string, string> $name
 */
class Holiday extends Model
{
    use HasUlids;

    protected $fillable = ['date', 'name'];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'name' => 'array',
        ];
    }
}
