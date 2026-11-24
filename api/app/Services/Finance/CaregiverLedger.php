<?php

namespace App\Services\Finance;

use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\CaregiverRemuneration;
use App\Models\CashHandover;
use App\Models\Service;
use App\Support\Translated;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * Relevé d'activité d'un soignant (modèle « agence ») : missions réalisées, espèces encaissées
 * pour l'agence, espèces remises, rémunération due. Tous les montants sont en centimes.
 *
 * Aucune donnée de patient n'en sort : le comptable ne voit ni nom, ni adresse, ni note.
 */
class CaregiverLedger
{
    /** @var array<string, array<string, array<string, int|null>>> résumés déjà calculés, par mois */
    private array $summaries = [];

    /**
     * Mois lisible par la base (`AAAA-MM`) → bornes du mois à Nador, en UTC pour les horodatages.
     *
     * @return array{CarbonImmutable, CarbonImmutable}
     */
    public static function bounds(string $period): array
    {
        $start = self::month($period);

        return [$start, $start->addMonth()];
    }

    public static function month(string $period): CarbonImmutable
    {
        $timezone = (string) config('nadorcare.timezone');
        $start = preg_match('/^\d{4}-\d{2}$/', $period) === 1
            ? CarbonImmutable::createFromFormat('!Y-m', $period, $timezone)
            : null;

        return ($start ?: CarbonImmutable::now($timezone))->startOfMonth();
    }

    public static function currentPeriod(): string
    {
        return CarbonImmutable::now((string) config('nadorcare.timezone'))->format('Y-m');
    }

    /**
     * Chiffres du mois pour chaque soignant qui en a.
     *
     * @return array<string, array{missions: int, missions_value: int, collected: int, uncollected: int, handed_over: int, balance: int, remuneration: int|null}>
     */
    public function summaries(string $period): array
    {
        if (isset($this->summaries[$period])) {
            /** @var array<string, array{missions: int, missions_value: int, collected: int, uncollected: int, handed_over: int, balance: int, remuneration: int|null}> */
            return $this->summaries[$period];
        }

        [$start, $end] = self::bounds($period);
        $rows = [];
        $row = function (string $id) use (&$rows): void {
            $rows[$id] ??= [
                'missions' => 0, 'missions_value' => 0, 'collected' => 0, 'uncollected' => 0,
                'handed_over' => 0, 'balance' => 0, 'remuneration' => null,
            ];
        };

        // Missions réalisées dans le mois (date du soin).
        $missions = Booking::query()
            ->where('status', BookingStatus::Completed)
            ->whereNotNull('professional_id')
            ->where('scheduled_at', '>=', $start->utc())
            ->where('scheduled_at', '<', $end->utc())
            ->groupBy('professional_id')
            ->selectRaw('professional_id, COUNT(*) AS missions, COALESCE(SUM(total_price), 0) AS missions_value')
            ->toBase()->get();
        foreach ($missions as $line) {
            $row($line->professional_id);
            $rows[$line->professional_id]['missions'] = (int) $line->missions;
            $rows[$line->professional_id]['missions_value'] = (int) $line->missions_value;
        }

        // Espèces de ces missions : encaissées par le soignant, ou restées dues par le patient.
        $cash = DB::table('payments')
            ->join('bookings', 'bookings.id', '=', 'payments.booking_id')
            ->where('payments.method', 'cash')
            ->whereNotNull('bookings.professional_id')
            ->where('bookings.scheduled_at', '>=', $start->utc())
            ->where('bookings.scheduled_at', '<', $end->utc())
            ->groupBy('bookings.professional_id')
            ->selectRaw("bookings.professional_id,
                COALESCE(SUM(CASE WHEN payments.status = 'paid' THEN payments.amount ELSE 0 END), 0) AS collected,
                COALESCE(SUM(CASE WHEN payments.status = 'pending' THEN payments.amount ELSE 0 END), 0) AS uncollected")
            ->get();
        foreach ($cash as $line) {
            $row($line->professional_id);
            $rows[$line->professional_id]['collected'] = (int) $line->collected;
            $rows[$line->professional_id]['uncollected'] = (int) $line->uncollected;
        }

        $handovers = CashHandover::query()
            ->whereDate('handed_on', '>=', $start->format('Y-m-d'))
            ->whereDate('handed_on', '<', $end->format('Y-m-d'))
            ->groupBy('professional_id')
            ->selectRaw('professional_id, COALESCE(SUM(amount), 0) AS handed_over')
            ->toBase()->get();
        foreach ($handovers as $line) {
            $row($line->professional_id);
            $rows[$line->professional_id]['handed_over'] = (int) $line->handed_over;
        }

        $remunerations = CaregiverRemuneration::query()
            ->whereDate('period', $start->format('Y-m-d'))
            ->get(['professional_id', 'amount']);
        foreach ($remunerations as $line) {
            $row($line->professional_id);
            $rows[$line->professional_id]['remuneration'] = $line->amount;
        }

        foreach ($this->balances() as $id => $balance) {
            $row($id);
            $rows[$id]['balance'] = $balance;
        }

        return $this->summaries[$period] = $rows;
    }

    /**
     * Chiffres du mois d'un soignant ; des zéros s'il n'a rien eu.
     *
     * @return array{missions: int, missions_value: int, collected: int, uncollected: int, handed_over: int, balance: int, remuneration: int|null}
     */
    public function summary(string $professionalId, string $period): array
    {
        return $this->summaries($period)[$professionalId] ?? [
            'missions' => 0, 'missions_value' => 0, 'collected' => 0, 'uncollected' => 0,
            'handed_over' => 0, 'balance' => 0, 'remuneration' => null,
        ];
    }

    /**
     * Espèces que le soignant détient encore pour l'agence, toutes périodes confondues : ce
     * qu'il a encaissé, moins ce qu'il a remis.
     */
    public function balance(string $professionalId): int
    {
        return $this->collectedBy($professionalId) - (int) CashHandover::query()->where('professional_id', $professionalId)->sum('amount');
    }

    /**
     * Missions réalisées dans le mois, de la plus ancienne à la plus récente.
     *
     * @return list<array{reference: string, date: string, time: string, service: string|null, amount: int, payment: string}>
     */
    public function missions(string $professionalId, string $period): array
    {
        [$start, $end] = self::bounds($period);
        $timezone = (string) config('nadorcare.timezone');

        $bookings = Booking::query()
            ->where('professional_id', $professionalId)
            ->where('status', BookingStatus::Completed)
            ->where('scheduled_at', '>=', $start->utc())
            ->where('scheduled_at', '<', $end->utc())
            ->orderBy('scheduled_at')
            ->get(['id', 'reference', 'service_id', 'scheduled_at', 'total_price', 'payment_method']);

        $services = Service::query()->withTrashed()->whereIn('id', $bookings->pluck('service_id')->unique()->all())
            ->get(['id', 'name'])->mapWithKeys(fn (Service $service) => [$service->id => Translated::pick($service->name)]);
        $cash = DB::table('payments')->whereIn('booking_id', $bookings->modelKeys())->where('method', 'cash')
            ->pluck('status', 'booking_id');

        return $bookings->map(function (Booking $booking) use ($services, $cash, $timezone) {
            $at = CarbonImmutable::instance($booking->scheduled_at)->setTimezone($timezone);

            return [
                'reference' => $booking->reference,
                'date' => $at->format('d/m/Y'),
                'time' => $at->format('H:i'),
                'service' => $services[$booking->service_id] ?? null,
                'amount' => $booking->total_price,
                // `card`, `cash_collected` (encaissé par le soignant) ou `cash_due` (resté dû).
                'payment' => $booking->payment_method !== 'cash'
                    ? 'card'
                    : (($cash[$booking->id] ?? 'pending') === 'paid' ? 'cash_collected' : 'cash_due'),
            ];
        })->values()->all();
    }

    /**
     * Remises d'espèces du mois, de la plus ancienne à la plus récente.
     *
     * @return list<array{date: string, amount: int, note: string|null}>
     */
    public function handovers(string $professionalId, string $period): array
    {
        [$start, $end] = self::bounds($period);

        return CashHandover::query()
            ->where('professional_id', $professionalId)
            ->whereDate('handed_on', '>=', $start->format('Y-m-d'))
            ->whereDate('handed_on', '<', $end->format('Y-m-d'))
            ->orderBy('handed_on')->orderBy('id')
            ->get()
            ->map(fn (CashHandover $handover) => [
                'date' => $handover->handed_on->format('d/m/Y'),
                'amount' => $handover->amount,
                'note' => $handover->note,
            ])->all();
    }

    /**
     * Oublie les résumés calculés : à appeler après une écriture.
     */
    public function forget(): void
    {
        $this->summaries = [];
    }

    private function collectedBy(string $professionalId): int
    {
        return (int) DB::table('payments')
            ->where('method', 'cash')->where('status', 'paid')
            ->where('collected_by', $professionalId)
            ->sum('amount');
    }

    /**
     * @return array<string, int>
     */
    private function balances(): array
    {
        $balances = [];

        $collected = DB::table('payments')
            ->where('method', 'cash')->where('status', 'paid')->whereNotNull('collected_by')
            ->groupBy('collected_by')->selectRaw('collected_by, SUM(amount) AS total')->get();
        foreach ($collected as $line) {
            $balances[$line->collected_by] = (int) $line->total;
        }

        $handed = CashHandover::query()->groupBy('professional_id')
            ->selectRaw('professional_id, SUM(amount) AS total')->toBase()->get();
        foreach ($handed as $line) {
            $balances[$line->professional_id] = ($balances[$line->professional_id] ?? 0) - (int) $line->total;
        }

        return $balances;
    }
}
