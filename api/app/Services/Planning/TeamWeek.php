<?php

namespace App\Services\Planning;

use App\Enums\BookingStatus;
use App\Enums\ScheduleRequestKind;
use App\Enums\ScheduleRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\ScheduleRequest;
use App\Models\Service;
use App\Models\Zone;
use App\Support\Translated;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * Planning global de l'équipe sur une semaine : pour chaque soignant et chaque jour, ses heures
 * de travail (semaine type), ses indisponibilités acceptées et ses missions.
 *
 * Aucune donnée de patient n'en sort : une mission se résume à son heure, son soin et sa zone.
 */
class TeamWeek
{
    /**
     * @return array{
     *     days: list<CarbonImmutable>,
     *     rows: list<array{
     *         id: string, name: string, category: string|null, zones: list<string>,
     *         days: array<string, array{hours: list<string>, off: bool, missions: list<array{time: string, service: string|null, zone: string|null, reference: string, status: string, awaiting: bool}>}>
     *     }>
     * }
     */
    public function build(CarbonImmutable $anyDay): array
    {
        $timezone = (string) config('nadorcare.timezone');
        $monday = $anyDay->setTimezone($timezone)->startOfWeek(CarbonImmutable::MONDAY)->startOfDay();
        $days = array_map(fn (int $offset) => $monday->addDays($offset), range(0, 6));
        $sunday = $days[6];

        $professionals = Professional::query()
            ->with(['user:id,name', 'category:id,name', 'zones:id,name'])
            ->whereNotIn('verification_status', [VerificationStatus::Rejected, VerificationStatus::Suspended])
            ->get()
            ->sortBy(fn (Professional $professional) => mb_strtolower((string) $professional->user->name))
            ->values();

        $ids = $professionals->modelKeys();

        $slots = DB::table('availabilities')->whereIn('professional_id', $ids)
            ->orderBy('start_time')->get(['professional_id', 'weekday', 'start_time', 'end_time'])
            ->groupBy('professional_id');

        $absences = ScheduleRequest::query()
            ->whereIn('professional_id', $ids)
            ->where('kind', ScheduleRequestKind::Unavailability)
            ->where('status', ScheduleRequestStatus::Accepted)
            ->whereDate('starts_on', '<=', $sunday->format('Y-m-d'))
            ->whereDate('ends_on', '>=', $monday->format('Y-m-d'))
            ->get(['professional_id', 'starts_on', 'ends_on'])
            ->groupBy('professional_id');

        $missions = Booking::query()
            ->whereIn('professional_id', $ids)
            ->whereIn('status', [...BookingStatus::activeMission(), BookingStatus::Completed])
            ->where('scheduled_at', '>=', $monday->utc())
            ->where('scheduled_at', '<', $monday->addDays(7)->utc())
            ->orderBy('scheduled_at')
            ->get(['id', 'reference', 'professional_id', 'service_id', 'status', 'scheduled_at', 'address_snapshot', 'assignment_confirmed_at'])
            ->groupBy('professional_id');

        $serviceNames = Service::query()->withTrashed()
            ->whereIn('id', $missions->flatten(1)->pluck('service_id')->unique()->all())
            ->get(['id', 'name'])
            ->mapWithKeys(fn (Service $service) => [$service->id => Translated::pick($service->name)]);
        $zoneNames = Zone::query()->get(['id', 'name'])
            ->mapWithKeys(fn (Zone $zone) => [$zone->id => Translated::pick($zone->name)]);

        $rows = [];
        foreach ($professionals as $professional) {
            $week = [];
            foreach ($days as $day) {
                $date = $day->format('Y-m-d');
                $week[$date] = [
                    'hours' => collect($slots[$professional->id] ?? [])
                        ->filter(fn ($slot) => (int) $slot->weekday === $day->dayOfWeek)
                        ->map(fn ($slot) => substr((string) $slot->start_time, 0, 5).' – '.substr((string) $slot->end_time, 0, 5))
                        ->values()->all(),
                    'off' => collect($absences[$professional->id] ?? [])->contains(
                        fn (ScheduleRequest $absence) => $absence->starts_on?->format('Y-m-d') <= $date && $absence->ends_on?->format('Y-m-d') >= $date,
                    ),
                    'missions' => [],
                ];
            }

            foreach ($missions[$professional->id] ?? [] as $booking) {
                /** @var Booking $booking */
                $at = CarbonImmutable::instance($booking->scheduled_at)->setTimezone($timezone);
                $week[$at->format('Y-m-d')]['missions'][] = [
                    'time' => $at->format('H:i'),
                    'service' => $serviceNames[$booking->service_id] ?? null,
                    'zone' => $zoneNames[$booking->address_snapshot['zone_id'] ?? ''] ?? null,
                    'reference' => $booking->reference,
                    'status' => $booking->status->value,
                    // Affectée, mais le soignant n'a pas encore confirmé sa venue.
                    'awaiting' => $booking->awaitsConfirmation(),
                ];
            }

            $rows[] = [
                'id' => $professional->id,
                'name' => (string) $professional->user->name,
                'category' => Translated::pick($professional->category->name),
                'zones' => $professional->zones->map(fn (Zone $zone) => (string) Translated::pick($zone->name))->values()->all(),
                'days' => $week,
            ];
        }

        return ['days' => $days, 'rows' => $rows];
    }

    /**
     * Semaine type d'un soignant, relue en base.
     *
     * @return list<array{weekday: int, start_time: string, end_time: string}>
     */
    public static function slotsOf(string $professionalId): array
    {
        return DB::table('availabilities')->where('professional_id', $professionalId)
            ->orderByRaw('(weekday + 6) % 7')->orderBy('start_time')
            ->get(['weekday', 'start_time', 'end_time'])
            ->map(fn ($slot) => [
                'weekday' => (int) $slot->weekday,
                'start_time' => substr((string) $slot->start_time, 0, 5),
                'end_time' => substr((string) $slot->end_time, 0, 5),
            ])->all();
    }

    /**
     * Noms des jours dans la langue du back-office, du lundi au dimanche. 0 = dimanche … 6 = samedi.
     *
     * @return array<int, string>
     */
    public static function weekdayNames(): array
    {
        $names = [];
        foreach ([1, 2, 3, 4, 5, 6, 0] as $weekday) {
            // Le 1er janvier 2023 est un dimanche.
            $names[$weekday] = ucfirst(CarbonImmutable::create(2023, 1, 1 + $weekday)->locale(app()->getLocale())->isoFormat('dddd'));
        }

        return $names;
    }

    /**
     * Une ligne lisible par jour travaillé : « Lundi : 08:00 – 12:00, 14:00 – 18:00 ».
     *
     * @param  array<array-key, array{weekday: int|string, start_time: string, end_time: string}>  $slots
     * @return list<string>
     */
    public static function describe(array $slots): array
    {
        $lines = [];
        foreach (self::weekdayNames() as $weekday => $name) {
            $ranges = collect($slots)
                ->filter(fn (array $slot) => (int) $slot['weekday'] === $weekday)
                ->sortBy('start_time')
                ->map(fn (array $slot) => substr((string) $slot['start_time'], 0, 5).' – '.substr((string) $slot['end_time'], 0, 5))
                ->implode(', ');

            if ($ranges !== '') {
                $lines[] = $name.' : '.$ranges;
            }
        }

        return $lines;
    }
}
