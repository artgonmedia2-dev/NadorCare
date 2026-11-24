<?php

namespace App\Actions\Finance;

use App\Exceptions\ApiException;
use App\Models\CaregiverRemuneration;
use App\Models\CashHandover;
use App\Models\Professional;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Services\Finance\CaregiverLedger;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * Compte d'un soignant tenu par le comptable (modèle « agence », règles n° 6 et 10 du
 * 2026-11-23) : il pointe les espèces remises à l'agence et saisit la rémunération due pour
 * un mois. Rien n'est calculé ni versé automatiquement ; la paie se fait hors de l'application.
 */
class ManageCaregiverAccount
{
    public function __construct(
        private readonly CaregiverLedger $ledger,
        private readonly AuditLogger $audit,
    ) {}

    /**
     * Pointe une remise d'espèces. Elle ne peut pas dépasser ce que le soignant détient encore,
     * ni porter une date à venir.
     *
     * @param  int  $amount  centimes de dirham
     * @param  string  $handedOn  jour de la remise, `AAAA-MM-JJ`
     */
    public function recordHandover(Professional $professional, User $actor, int $amount, string $handedOn, ?string $note = null): CashHandover
    {
        $timezone = (string) config('nadorcare.timezone');
        $day = CarbonImmutable::createFromFormat('!Y-m-d', $handedOn, $timezone);

        if ($amount <= 0 || ! $day || $day->gt(CarbonImmutable::now($timezone)->startOfDay())) {
            throw new ApiException('handover_invalid');
        }

        return DB::transaction(function () use ($professional, $actor, $amount, $day, $note) {
            // Verrou sur la fiche : deux remises saisies en même temps ne dépassent pas le solde.
            Professional::query()->lockForUpdate()->findOrFail($professional->getKey());

            if ($amount > $this->ledger->balance($professional->id)) {
                throw new ApiException('handover_exceeds_balance');
            }

            $handover = new CashHandover([
                'professional_id' => $professional->id,
                'amount' => $amount,
                'handed_on' => $day->format('Y-m-d'),
                'note' => self::clean($note),
            ]);
            $handover->recorded_by = $actor->getKey();
            $handover->save();

            $this->audit->record('finance.cash_handed_over', $handover, $actor, null, [
                'professional_id' => $professional->id,
                'amount' => $amount,
            ]);
            $this->ledger->forget();

            return $handover;
        });
    }

    /**
     * Saisit, ou corrige, la rémunération due à un soignant pour un mois (`AAAA-MM`).
     *
     * @param  int  $amount  centimes de dirham
     */
    public function setRemuneration(Professional $professional, User $actor, string $period, int $amount, ?string $note = null): CaregiverRemuneration
    {
        if ($amount < 0 || preg_match('/^\d{4}-\d{2}$/', $period) !== 1) {
            throw new ApiException('remuneration_invalid');
        }

        $month = CaregiverLedger::month($period)->format('Y-m-d');

        return DB::transaction(function () use ($professional, $actor, $month, $amount, $note) {
            $remuneration = CaregiverRemuneration::query()
                ->where('professional_id', $professional->id)
                ->whereDate('period', $month)
                ->lockForUpdate()
                ->first();
            $previous = $remuneration?->amount;

            $remuneration ??= new CaregiverRemuneration(['professional_id' => $professional->id, 'period' => $month]);
            $remuneration->fill(['amount' => $amount, 'note' => self::clean($note)]);
            $remuneration->set_by = $actor->getKey();
            $remuneration->save();

            $this->audit->record('finance.remuneration_set', $remuneration, $actor,
                $previous === null ? null : ['amount' => $previous],
                ['professional_id' => $professional->id, 'period' => $month, 'amount' => $amount],
            );
            $this->ledger->forget();

            return $remuneration;
        });
    }

    private static function clean(?string $text): ?string
    {
        $text = trim((string) $text);

        return $text === '' ? null : $text;
    }
}
