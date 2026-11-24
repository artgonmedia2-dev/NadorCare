<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Assurance de l'agence (responsabilité civile professionnelle de Nador Care). Elle s'enregistre
 * et se met à jour par `Actions\Agency\ManageAgencyInsurance`.
 *
 * @property string $id
 * @property string $insurer
 * @property string $policy_number
 * @property Carbon $expires_on
 * @property string|null $file_id
 * @property string|null $created_by
 * @property-read File|null $file
 */
class AgencyInsurance extends Model
{
    use HasUlids;

    /** Nombre de jours avant l'échéance à partir duquel le back-office alerte. */
    public const ALERT_DAYS = 30;

    protected $fillable = ['insurer', 'policy_number', 'expires_on'];

    protected function casts(): array
    {
        return [
            'expires_on' => 'date',
        ];
    }

    /**
     * @return BelongsTo<File, $this>
     */
    public function file(): BelongsTo
    {
        return $this->belongsTo(File::class);
    }

    /**
     * Contrats encore valables à la date donnée (aujourd'hui par défaut).
     *
     * @param  Builder<AgencyInsurance>  $query
     */
    public function scopeValidOn(Builder $query, ?Carbon $day = null): void
    {
        $query->whereDate('expires_on', '>=', ($day ?? today())->format('Y-m-d'));
    }

    /**
     * L'agence n'a aucun contrat valable au-delà du délai d'alerte : il faut renouveler.
     */
    public static function needsAttention(): bool
    {
        return ! self::query()->validOn(today()->addDays(self::ALERT_DAYS))->exists();
    }
}
