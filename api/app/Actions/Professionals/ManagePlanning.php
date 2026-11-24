<?php

namespace App\Actions\Professionals;

use App\Enums\ScheduleRequestKind;
use App\Enums\ScheduleRequestStatus;
use App\Exceptions\ApiException;
use App\Models\Professional;
use App\Models\ScheduleRequest;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * Planning de l'équipe (modèle « agence », décision du 2026-11-23). La coordination fixe pour
 * chaque soignant ses zones et sa semaine type. Le soignant ne modifie rien lui-même : il
 * propose une nouvelle semaine ou signale une indisponibilité datée, et la coordination
 * accepte ou refuse. Tant qu'une demande n'est pas acceptée, le planning ne change pas.
 */
class ManagePlanning
{
    /** Demandes en attente qu'un soignant peut avoir en même temps. */
    public const MAX_PENDING = 5;

    /** Durée la plus longue d'une indisponibilité, en jours. */
    public const MAX_UNAVAILABILITY_DAYS = 60;

    public function __construct(
        private readonly UpdateProfessionalSchedule $schedule,
        private readonly AuditLogger $audit,
    ) {}

    /**
     * La coordination fixe les zones et la semaine type d'un soignant.
     *
     * @param  list<string>  $zoneIds
     * @param  list<array{weekday: int|string, start_time: string, end_time: string}>  $slots
     */
    public function set(Professional $professional, User $actor, array $zoneIds, array $slots): void
    {
        $slots = self::normalize($slots);

        DB::transaction(function () use ($professional, $actor, $zoneIds, $slots) {
            $this->schedule->setZones($professional, $zoneIds);
            $this->schedule->setAvailabilities($professional, $slots);

            $this->audit->record('planning.updated', $professional, $actor, null, [
                'zones' => count($zoneIds),
                'slots' => count($slots),
            ]);
        });
    }

    /**
     * Le soignant propose une nouvelle semaine type.
     *
     * @param  list<array{weekday: int|string, start_time: string, end_time: string}>  $slots
     */
    public function proposeWeek(Professional $professional, array $slots, ?string $note = null): ScheduleRequest
    {
        $slots = self::normalize($slots);
        $this->schedule->assertValidSlots($slots);
        $this->assertRoom($professional);

        return ScheduleRequest::query()->create([
            'professional_id' => $professional->id,
            'kind' => ScheduleRequestKind::Weekly,
            'slots' => $slots,
            'note' => self::clean($note),
        ]);
    }

    /**
     * Le soignant signale une indisponibilité : des journées entières, bornes comprises.
     */
    public function reportUnavailability(Professional $professional, string $startsOn, string $endsOn, ?string $note = null): ScheduleRequest
    {
        $timezone = (string) config('nadorcare.timezone');
        $start = CarbonImmutable::createFromFormat('!Y-m-d', $startsOn, $timezone);
        $end = CarbonImmutable::createFromFormat('!Y-m-d', $endsOn, $timezone);
        $today = CarbonImmutable::now($timezone)->startOfDay();

        if (! $start || ! $end || $end->lt($start) || $start->lt($today)
            || $start->diffInDays($end) >= self::MAX_UNAVAILABILITY_DAYS) {
            throw new ApiException('unavailability_invalid');
        }

        $this->assertRoom($professional);

        return ScheduleRequest::query()->create([
            'professional_id' => $professional->id,
            'kind' => ScheduleRequestKind::Unavailability,
            'starts_on' => $start->format('Y-m-d'),
            'ends_on' => $end->format('Y-m-d'),
            'note' => self::clean($note),
        ]);
    }

    /**
     * Le soignant retire une demande qui n'a pas encore reçu de réponse.
     */
    public function cancel(ScheduleRequest $request, Professional $professional): ScheduleRequest
    {
        if ($request->professional_id !== $professional->id) {
            throw new ApiException('not_found', 404);
        }

        return DB::transaction(function () use ($request) {
            $locked = $this->lockPending($request);
            $locked->status = ScheduleRequestStatus::Cancelled;
            $locked->save();

            return $locked;
        });
    }

    /**
     * La coordination accepte une demande. Une semaine proposée remplace alors la semaine type ;
     * une indisponibilité acceptée retire le soignant des disponibles sur ces journées.
     */
    public function accept(ScheduleRequest $request, User $actor): ScheduleRequest
    {
        return DB::transaction(function () use ($request, $actor) {
            $locked = $this->lockPending($request);

            if ($locked->kind === ScheduleRequestKind::Weekly) {
                $professional = Professional::query()->findOrFail($locked->professional_id);
                $this->schedule->setAvailabilities($professional, $locked->slots ?? []);
            }

            return $this->close($locked, $actor, ScheduleRequestStatus::Accepted, null);
        });
    }

    public function refuse(ScheduleRequest $request, User $actor, ?string $reason = null): ScheduleRequest
    {
        return DB::transaction(fn () => $this->close(
            $this->lockPending($request), $actor, ScheduleRequestStatus::Refused, self::clean($reason),
        ));
    }

    private function close(ScheduleRequest $request, User $actor, ScheduleRequestStatus $status, ?string $reason): ScheduleRequest
    {
        $request->status = $status;
        $request->decided_by = $actor->getKey();
        $request->decided_at = now();
        $request->decision_note = $reason;
        $request->save();

        // Le journal ne reprend ni la précision du soignant ni le motif : seulement la décision.
        $this->audit->record('planning.request_'.$status->value, $request, $actor, null, [
            'kind' => $request->kind->value,
            'professional_id' => $request->professional_id,
        ]);

        return $request;
    }

    /**
     * Relit la demande en base, verrouillée : deux coordinateurs peuvent décider en même temps.
     */
    private function lockPending(ScheduleRequest $request): ScheduleRequest
    {
        $locked = ScheduleRequest::query()->lockForUpdate()->findOrFail($request->getKey());

        if ($locked->status !== ScheduleRequestStatus::Pending) {
            throw new ApiException('schedule_request_closed', 409);
        }

        return $locked;
    }

    private function assertRoom(Professional $professional): void
    {
        $pending = ScheduleRequest::query()
            ->where('professional_id', $professional->id)
            ->where('status', ScheduleRequestStatus::Pending)
            ->count();

        if ($pending >= self::MAX_PENDING) {
            throw new ApiException('schedule_request_limit', 409);
        }
    }

    /**
     * Ramène les plages à une forme unique : jour entier, heures `HH:MM`.
     *
     * @param  array<array-key, array{weekday: int|string, start_time: string, end_time: string}>  $slots
     * @return list<array{weekday: int, start_time: string, end_time: string}>
     */
    private static function normalize(array $slots): array
    {
        return array_values(array_map(fn (array $slot) => [
            'weekday' => (int) $slot['weekday'],
            'start_time' => substr((string) $slot['start_time'], 0, 5),
            'end_time' => substr((string) $slot['end_time'], 0, 5),
        ], $slots));
    }

    private static function clean(?string $text): ?string
    {
        $text = trim((string) $text);

        return $text === '' ? null : $text;
    }
}
