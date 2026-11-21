<?php

namespace App\Services\Bookings;

use App\Models\Service;
use App\Models\Surcharge;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;

/**
 * Calcule le prix d'un soin : tarif de base plus les majorations actives qui s'appliquent
 * au créneau (nuit, jour férié).
 *
 * La majoration de distance existe dans le catalogue mais n'est pas appliquée : son mode de
 * calcul n'est pas défini dans le cahier des charges (distance depuis quel point ?).
 */
class PriceCalculator
{
    public function __construct(private readonly BookingSchedule $schedule) {}

    public function quote(Service $service, CarbonInterface $at): PriceQuote
    {
        $local = CarbonImmutable::instance($at)->setTimezone($this->schedule->timezone());
        $base = $service->base_price;
        $lines = [];

        foreach (Surcharge::query()->where('is_active', true)->orderBy('type')->orderBy('id')->get() as $surcharge) {
            if (! $this->applies($surcharge, $local)) {
                continue;
            }

            $lines[] = [
                'surcharge_id' => $surcharge->id,
                'type' => $surcharge->type,
                'name' => $surcharge->name,
                'amount' => $surcharge->mode === Surcharge::MODE_PERCENT
                    ? (int) round($base * $surcharge->value / 100)
                    : $surcharge->value,
            ];
        }

        return new PriceQuote($base, $lines);
    }

    private function applies(Surcharge $surcharge, CarbonImmutable $local): bool
    {
        return match ($surcharge->type) {
            Surcharge::TYPE_NIGHT => $this->isNight($local, $surcharge->config ?? []),
            Surcharge::TYPE_HOLIDAY => DB::table('holidays')->whereDate('date', $local->format('Y-m-d'))->exists(),
            default => false,
        };
    }

    /**
     * Plage de nuit, qui peut passer minuit (21:00 → 07:00).
     *
     * @param  array<string, mixed>  $config
     */
    private function isNight(CarbonImmutable $local, array $config): bool
    {
        $start = (string) ($config['start'] ?? '21:00');
        $end = (string) ($config['end'] ?? '07:00');
        $time = $local->format('H:i');

        return $start <= $end
            ? ($time >= $start && $time < $end)
            : ($time >= $start || $time < $end);
    }
}
