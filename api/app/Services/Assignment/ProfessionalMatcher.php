<?php

namespace App\Services\Assignment;

use App\Enums\BookingStatus;
use App\Enums\UserStatus;
use App\Enums\VerificationStatus;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\ProfessionalDocument;
use App\Models\Service;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

/**
 * Trouve les professionnels qui peuvent prendre une réservation, et les classe.
 *
 * Conditions obligatoires (cahier des charges §3, §5) : compte actif et vérifié, assurance
 * responsabilité civile approuvée et valable le jour du soin, profession exigée par le service,
 * aucune autre mission au même moment.
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
            ->whereHas('documents', fn (Builder $document) => $document
                ->where('type', ProfessionalDocument::TYPE_RC_INSURANCE)
                ->where('status', ProfessionalDocument::STATUS_APPROVED)
                ->whereDate('expires_at', '>=', $start->format('Y-m-d')))
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
                    AND a.weekday = ? AND a.start_time <= ? AND a.end_time >= ?) AS is_available',
                [$start->dayOfWeek, $start->format('H:i:s'), $end->format('H:i:s')],
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
