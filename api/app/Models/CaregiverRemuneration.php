<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

/**
 * Rémunération due à un soignant pour un mois. Saisie à la main par le comptable : aucune
 * règle de calcul tant que les contrats ne sont pas fixés (règle n° 6 du 2026-11-23).
 *
 * @property string $id
 * @property string $professional_id
 * @property Carbon $period premier jour du mois
 * @property int $amount centimes de dirham
 * @property string|null $note
 * @property string|null $set_by
 */
class CaregiverRemuneration extends Model
{
    use HasUlids;

    protected $fillable = ['professional_id', 'period', 'amount', 'note'];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'period' => 'date',
        ];
    }
}
