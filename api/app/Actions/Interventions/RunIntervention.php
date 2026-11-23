<?php

namespace App\Actions\Interventions;

use App\Actions\Bookings\TransitionBooking;
use App\Actions\Teleconsultation\JoinTeleconsultation;
use App\Contracts\MapsService;
use App\Enums\BookingStatus;
use App\Events\ProfessionalLocationUpdated;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\Intervention;
use App\Models\InterventionReport;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Déroulement d'une mission côté professionnel (cahier des charges §5) : départ, partage de
 * position pendant le trajet, arrivée au domicile.
 */
class RunIntervention
{
    public function __construct(
        private readonly TransitionBooking $transition,
        private readonly MapsService $maps,
        private readonly JoinTeleconsultation $teleconsultation,
    ) {}

    /**
     * Le professionnel part : la réservation passe « en route » et le patient peut le suivre.
     */
    public function depart(Booking $booking, User $actor): Booking
    {
        return $this->transition->handle($booking, BookingStatus::EnRoute, $actor);
    }

    /**
     * Enregistre une position. Acceptée uniquement pendant le trajet : la position du
     * professionnel n'est jamais suivie en dehors (cahier des charges §5).
     *
     * @return int|null durée estimée du trajet restant, en secondes
     */
    public function recordLocation(Booking $booking, float $latitude, float $longitude, ?int $accuracy = null): ?int
    {
        if ($booking->status !== BookingStatus::EnRoute) {
            throw new ApiException('location_not_expected', 409);
        }

        DB::insert(
            'INSERT INTO location_pings (id, booking_id, professional_id, location, accuracy_m, recorded_at)
             VALUES (?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?, ?)',
            [(string) str()->ulid(), $booking->getKey(), $booking->professional_id, $longitude, $latitude, $accuracy, now()],
        );

        DB::update(
            'UPDATE professionals SET last_location = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, last_location_at = ? WHERE id = ?',
            [$longitude, $latitude, now(), $booking->professional_id],
        );

        $eta = $this->etaSeconds($booking, $latitude, $longitude);

        ProfessionalLocationUpdated::dispatch($booking->getKey(), $latitude, $longitude, $eta);

        return $eta;
    }

    /**
     * Pointage d'arrivée : la réservation passe « en cours » et l'intervention est ouverte,
     * avec un compte rendu en brouillon.
     */
    public function arrive(Booking $booking, User $actor, ?float $latitude = null, ?float $longitude = null): Intervention
    {
        return DB::transaction(function () use ($booking, $actor, $latitude, $longitude) {
            $booking = $this->transition->handle($booking, BookingStatus::InProgress, $actor);

            $intervention = Intervention::create([
                'booking_id' => $booking->getKey(),
                'professional_id' => $booking->professional_id,
                'arrived_at' => now(),
                'status' => Intervention::STATUS_IN_PROGRESS,
            ]);

            if ($latitude !== null && $longitude !== null) {
                DB::update(
                    'UPDATE interventions SET arrival_location = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography WHERE id = ?',
                    [$longitude, $latitude, $intervention->getKey()],
                );
            }

            InterventionReport::create([
                'intervention_id' => $intervention->getKey(),
                'version' => 1,
                'author_id' => $actor->getKey(),
            ]);

            return $intervention;
        });
    }

    /**
     * Durée estimée entre une position et le domicile du patient.
     */
    /**
     * Démarre une téléconsultation : le professionnel ouvre l'appel, la réservation passe « en
     * cours » et le compte rendu s'ouvre, comme au pointage d'arrivée d'un soin à domicile.
     */
    public function startRemote(Booking $booking, User $actor): Intervention
    {
        if (! $booking->service()->first()?->isRemote()) {
            throw new ApiException('not_a_teleconsultation', 409);
        }

        // On vérifie que la salle est ouverte avant de changer le statut.
        $this->teleconsultation->handle($booking, $actor);

        return DB::transaction(function () use ($booking, $actor) {
            $booking = $this->transition->handle($booking, BookingStatus::InProgress, $actor);

            $intervention = Intervention::create([
                'booking_id' => $booking->getKey(),
                'professional_id' => $booking->professional_id,
                'arrived_at' => now(),
                'status' => Intervention::STATUS_IN_PROGRESS,
            ]);

            InterventionReport::create([
                'intervention_id' => $intervention->getKey(),
                'version' => 1,
                'author_id' => $actor->getKey(),
            ]);

            return $intervention;
        });
    }

    public function etaSeconds(Booking $booking, float $latitude, float $longitude): ?int
    {
        $address = $booking->address_snapshot ?? [];

        if (! isset($address['latitude'], $address['longitude'])) {
            return null;
        }

        return $this->maps->estimateRoute($latitude, $longitude, (float) $address['latitude'], (float) $address['longitude'])->durationSeconds;
    }
}
