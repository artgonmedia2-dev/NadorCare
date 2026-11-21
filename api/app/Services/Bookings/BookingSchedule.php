<?php

namespace App\Services\Bookings;

use App\Models\Service;
use App\Services\Settings\Settings;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;

/**
 * Créneaux réservables : dans les horaires de service, assez tôt pour laisser le temps
 * d'organiser le soin, et pas trop loin dans le futur. Les heures sont celles de Nador.
 *
 * La disponibilité des professionnels n'entre pas ici : c'est la coordination qui valide
 * la demande puis affecte un soignant.
 */
class BookingSchedule
{
    public function __construct(private readonly Settings $settings) {}

    public function timezone(): string
    {
        return (string) config('nadorcare.timezone');
    }

    /**
     * Débuts de créneau encore réservables un jour donné (`Y-m-d`, heure locale).
     *
     * @return list<CarbonImmutable>
     */
    public function slotsFor(string $date, Service $service, ?CarbonInterface $now = null): array
    {
        $now = CarbonImmutable::instance($now ?? now())->setTimezone($this->timezone());
        $day = CarbonImmutable::createFromFormat('!Y-m-d', $date, $this->timezone());

        if ($day === null || $day->greaterThan($this->lastBookableDay($now))) {
            return [];
        }

        [$opening, $lastStart] = $this->window($day, $service);
        $earliest = $now->addMinutes($this->settings->int(Settings::MIN_LEAD_MINUTES));
        $step = max(5, $this->settings->int(Settings::SLOT_MINUTES));

        $slots = [];
        for ($slot = $opening; $slot->lessThanOrEqualTo($lastStart); $slot = $slot->addMinutes($step)) {
            if ($slot->greaterThanOrEqualTo($earliest)) {
                $slots[] = $slot;
            }
        }

        return $slots;
    }

    /**
     * Le créneau demandé fait partie de ceux proposés.
     */
    public function isBookable(CarbonInterface $at, Service $service, ?CarbonInterface $now = null): bool
    {
        $local = CarbonImmutable::instance($at)->setTimezone($this->timezone());

        foreach ($this->slotsFor($local->format('Y-m-d'), $service, $now) as $slot) {
            if ($slot->equalTo($local)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Une demande « dès que possible » n'est acceptée que pendant les horaires de service.
     */
    public function isOpenNow(Service $service, ?CarbonInterface $now = null): bool
    {
        $now = CarbonImmutable::instance($now ?? now())->setTimezone($this->timezone());
        [$opening, $lastStart] = $this->window($now->startOfDay(), $service);

        return $now->betweenIncluded($opening, $lastStart);
    }

    private function lastBookableDay(CarbonImmutable $now): CarbonImmutable
    {
        return $now->startOfDay()->addDays($this->settings->int(Settings::MAX_DAYS_AHEAD));
    }

    /**
     * Premier et dernier début possible : le soin doit se terminer avant la fermeture.
     *
     * @return array{CarbonImmutable, CarbonImmutable}
     */
    private function window(CarbonImmutable $day, Service $service): array
    {
        $opening = $day->setTimeFromTimeString($this->settings->string(Settings::DAY_START));
        $closing = $day->setTimeFromTimeString($this->settings->string(Settings::DAY_END));

        return [$opening, $closing->subMinutes($service->duration_minutes)];
    }
}
