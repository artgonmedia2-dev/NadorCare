<?php

namespace App\Http\Resources\Api\V1;

use App\Actions\Bookings\CancelBooking;
use App\Actions\Interventions\RunIntervention;
use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\BookingStatusHistory;
use App\Support\Translated;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * @mixin Booking
 */
class BookingResource extends JsonResource
{
    /**
     * La fiche détaillée ajoute la note du patient et l'historique des statuts.
     * La note est une donnée de santé : l'appelant journalise sa lecture.
     */
    private bool $detailed = false;

    public function detailed(): static
    {
        $this->detailed = true;

        return $this;
    }

    /**
     * Dernière position connue du soignant, seulement pendant qu'il est en route et si elle
     * date de moins de dix minutes.
     *
     * @return array{latitude: float, longitude: float, eta_minutes: int|null, updated_at: string}|null
     */
    private function tracking(): ?array
    {
        if ($this->status !== BookingStatus::EnRoute || $this->professional_id === null) {
            return null;
        }

        $position = DB::selectOne(
            'SELECT ST_Y(last_location::geometry) AS latitude, ST_X(last_location::geometry) AS longitude, last_location_at
             FROM professionals WHERE id = ? AND last_location IS NOT NULL AND last_location_at >= ?',
            [$this->professional_id, now()->subMinutes(10)],
        );

        if (! $position) {
            return null;
        }

        $eta = app(RunIntervention::class)->etaSeconds($this->resource, (float) $position->latitude, (float) $position->longitude);

        return [
            'latitude' => (float) $position->latitude,
            'longitude' => (float) $position->longitude,
            'eta_minutes' => $eta === null ? null : (int) ceil($eta / 60),
            'updated_at' => Carbon::parse($position->last_location_at)->toIso8601String(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $cancellation = app(CancelBooking::class);
        $cancellable = $this->status->canTransitionTo(BookingStatus::Cancelled);
        $snapshot = $this->price_snapshot ?? [];
        $timezone = (string) config('nadorcare.timezone');

        return [
            'id' => $this->id,
            /** Numéro lisible, à donner au téléphone : `NC-2026-000123`. */
            'reference' => $this->reference,
            'status' => $this->status->value,
            'type' => $this->type,
            'scheduled_at' => $this->scheduled_at->toIso8601String(),
            'scheduled_end_at' => $this->scheduled_end_at?->toIso8601String(),
            /** Jour du soin à Nador (`AAAA-MM-JJ`), à afficher tel quel quel que soit le fuseau du téléphone. */
            'scheduled_date' => $this->scheduled_at->copy()->setTimezone($timezone)->format('Y-m-d'),
            /** Heure du soin à Nador (`HH:MM`). */
            'scheduled_time' => $this->scheduled_at->copy()->setTimezone($timezone)->format('H:i'),
            'service' => [
                'id' => $this->service_id,
                'slug' => $this->service->slug,
                'name' => Translated::pick($this->service->name),
            ],
            'patient' => [
                'id' => $this->patient_profile_id,
                'first_name' => $this->patientProfile->first_name,
                'last_name' => $this->patientProfile->last_name,
            ],
            /** Adresse telle qu'elle était au moment de la demande. */
            'address' => [
                'label' => $this->address_snapshot['label'] ?? null,
                'line' => $this->address_snapshot['line'] ?? null,
                'city' => $this->address_snapshot['city'] ?? null,
            ],
            /** Prix figé à la demande, en centimes de dirham. */
            'price' => [
                'base' => $this->base_price,
                /** @var list<array{label: string|null, amount: int}> */
                'surcharges' => array_map(fn (array $line) => [
                    'label' => Translated::pick($line['name'] ?? null),
                    'amount' => (int) $line['amount'],
                ], $snapshot['surcharges'] ?? []),
                'total' => $this->total_price,
                'currency' => 'MAD',
            ],
            /** Soignant affecté, dès qu'il y en a un. */
            'professional' => $this->professional ? [
                'name' => $this->professional->user->name,
                'profession' => Translated::pick($this->professional->category->name),
            ] : null,
            /** Position du soignant et durée estimée avant son arrivée. Présent uniquement pendant le trajet. */
            'tracking' => $this->tracking(),
            /** Le compte rendu de l'intervention est disponible. */
            'has_report' => $this->status === BookingStatus::Completed,
            'payment_method' => $this->payment_method,
            'has_prescription' => $this->prescription_file_id !== null,
            'can_cancel' => $cancellable,
            /** Dernier moment pour annuler sans frais. */
            'free_cancellation_until' => $cancellable ? $cancellation->freeUntil($this->resource)->toIso8601String() : null,
            /** Frais dus si la réservation était annulée maintenant. */
            'cancellation_fee_if_cancelled_now' => $cancellable ? $cancellation->feeFor($this->resource) : null,
            /** Frais retenus, une fois la réservation annulée. */
            'cancellation_fee' => $this->status === BookingStatus::Cancelled ? $this->cancellation_fee : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'patient_note' => $this->when($this->detailed, fn () => $this->patient_note),
            /** @var list<array{status: string, at: string}> */
            'history' => $this->when($this->detailed, fn () => $this->statusHistory
                ->map(fn (BookingStatusHistory $row) => [
                    'status' => $row->to_status->value,
                    'at' => $row->created_at->toIso8601String(),
                ])->all()),
        ];
    }
}
