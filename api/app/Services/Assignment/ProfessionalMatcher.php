<?php

namespace App\Services\Assignment;

use App\Enums\BookingStatus;
use App\Enums\ScheduleRequestKind;
use App\Enums\ScheduleRequestStatus;
use App\Enums\UserStatus;
use App\Enums\VerificationStatus;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\Service;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

/**
 * Trouve les professionnels qui peuvent prendre une réservation, et les classe.
 *
 * Conditions obligatoires (cahier des charges §3, §5) : compte actif et vérifié, profession
 * exigée par le service, aucune autre mission au même moment. L'assurance personnelle n'en fait
 * plus partie (modèle « agence », règle n° 8 du 2026-11-23) : c'est l'agence qui est assurée.
 *
 * Critères de classement (§6) : zone couverte, disponibilité sur le créneau, distance, note.
 * Ils orientent le choix sans l'interdire : le coordinateur peut toujours forcer.
 */
class ProfessionalMatcher
{
    /**
     * @return Collection<int, Candidate>
     */
    public function candidatesFor(Booking $booking, int $limit = 30): Collection
    {
        return $this->query($booking)->limit($limit)->get()->map($this->toCandidate(...));
    }

    public function isEligible(Booking $booking, Professional $professional): bool
    {
        return $this->query($booking)->whereKey($professional->getKey())->exists();
    }

    /**
     * @return Builder<Professional>
     */
    private function query(Booking $booking): Builder
    {
        // Lue directement en base : la réservation peut arriver avec un service chargé partiellement.
        $requiredCategoryId = Service::query()->withTrashed()->whereKey($booking->service_id)->value('professional_category_id');

        $timezone = (string) config('nadorcare.timezone');
        $start = CarbonImmutable::instance($booking->scheduled_at)->setTimezone($timezone);
        $end = CarbonImmutable::instance($booking->scheduled_end_at ?? $booking->scheduled_at)->setTimezone($timezone);

        $snapshot = $booking->address_snapshot ?? [];
        $zoneId = $snapshot['zone_id'] ?? null;
        $latitude = $snapshot['latitude'] ?? null;
        $longitude = $snapshot['longitude'] ?? null;

        return Professional::query()
            ->with('user:id,name,phone,status')
            ->select('professionals.*')
            // --- Conditions obligatoires ---
            ->where('verification_status', VerificationStatus::Verified)
            ->where('professional_category_id', $requiredCategoryId)
            ->whereHas('user', fn (Builder $user) => $user->where('status', UserStatus::Active))
            ->whereNotExists(fn ($busy) => $busy->from('bookings')
                ->whereColumn('bookings.professional_id', 'professionals.id')
                ->where('bookings.id', '!=', $booking->getKey())
                ->whereIn('bookings.status', array_map(fn (BookingStatus $status) => $status->value, BookingStatus::activeMission()))
                ->where('bookings.scheduled_at', '<', $booking->scheduled_end_at ?? $booking->scheduled_at)
                ->whereRaw('COALESCE(bookings.scheduled_end_at, bookings.scheduled_at) > ?', [$booking->scheduled_at]))
            // --- Critères de classement ---
            ->selectRaw(
                'EXISTS (SELECT 1 FROM professional_zone pz WHERE pz.professional_id = professionals.id AND pz.zone_id = ?) AS covers_zone',
                [$zoneId],
            )
            ->selectRaw(
                'EXISTS (SELECT 1 FROM availabilities a WHERE a.professional_id = professionals.id
                    AND a.weekday = ? AND a.start_time <= ? AND a.end_time >= ?)
                 AND NOT EXISTS (SELECT 1 FROM schedule_requests sr WHERE sr.professional_id = professionals.id
                    AND sr.kind = ? AND sr.status = ? AND sr.starts_on <= ? AND sr.ends_on >= ?) AS is_available',
                [
                    $start->dayOfWeek, $start->format('H:i:s'), $end->format('H:i:s'),
                    // Une indisponibilité acceptée par la coordination (congé, empêchement).
                    ScheduleRequestKind::Unavailability->value, ScheduleRequestStatus::Accepted->value,
                    $start->format('Y-m-d'), $start->format('Y-m-d'),
                ],
            )
            ->when(
                $latitude !== null && $longitude !== null,
                fn (Builder $query) => $query->selectRaw(
                    'ROUND(ST_Distance(last_location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)) AS distance_m',
                    [$longitude, $latitude],
                ),
                fn (Builder $query) => $query->selectRaw('NULL AS distance_m'),
            )
            ->orderByDesc('covers_zone')
            ->orderByDesc('is_available')
            ->orderByRaw('distance_m ASC NULLS LAST')
            ->orderByRaw('rating_avg DESC NULLS LAST')
            ->orderBy('professionals.id');
    }

    private function toCandidate(Professional $professional): Candidate
    {
        $distance = $professional->getAttribute('distance_m');

        return new Candidate(
            professional: $professional,
            coversZone: (bool) $professional->getAttribute('covers_zone'),
            available: (bool) $professional->getAttribute('is_available'),
            distanceMeters: $distance === null ? null : (int) $distance,
            rating: $professional->rating_avg === null ? null : (float) $professional->rating_avg,
        );
    }
}
