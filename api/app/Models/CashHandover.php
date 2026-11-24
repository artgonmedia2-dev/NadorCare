<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

/**
 * Espèces remises à l'agence par un soignant, pointées par le comptable.
 * S'enregistre par `Actions\Finance\ManageCaregiverAccount`.
 *
 * @property string $id
 * @property string $professional_id
 * @property int $amount centimes de dirham
 * @property Carbon $handed_on
 * @property string|null $note
 * @property string|null $recorded_by
 */
class CashHandover extends Model
{
    use HasUlids;

    protected $fillable = ['professional_id', 'amount', 'handed_on', 'note'];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'handed_on' => 'date',
        ];
    }
}
