<?php

namespace App\Http\Resources\Api\V1;

use App\Actions\Teleconsultation\JoinTeleconsultation;
use App\Models\Booking;
use App\Support\Translated;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Mission vue par le professionnel affecté : ce qu'il faut pour se rendre chez le patient
 * et réaliser le soin. La fiche détaillée ajoute les données de santé, et sa lecture est
 * journalisée par l'appelant.
 *
 * @mixin Booking
 */
class MissionResource extends JsonResource
{
    private bool $detailed = false;

    public function detailed(): static
    {
        $this->detailed = true;

        return $this;
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $timezone = (string) config('nadorcare.timezone');
        $start = $this->scheduled_at->copy()->setTimezone($timezone);
        $address = $this->address_snapshot ?? [];
        $patient = $this->patientProfile;

        return [
            'id' => $this->id,
            'reference' => $this->reference,
            'status' => $this->status->value,
            'service' => [
                'name' => Translated::pick($this->service->name),
                'duration_minutes' => $this->service->duration_minutes,
            ],
            'scheduled_at' => $this->scheduled_at->toIso8601String(),
            'scheduled_date' => $start->format('Y-m-d'),
            'scheduled_time' => $start->format('H:i'),
            'patient' => [
                'first_name' => $patient->first_name,
                'last_name' => $patient->last_name,
                /** @format date */
                'birth_date' => $this->when($this->detailed, fn () => $patient->birth_date?->format('Y-m-d')),
                'sex' => $this->when($this->detailed, fn () => $patient->sex),
                /** Informations utiles au soin (allergies, mobilité…). */
                'care_notes' => $this->when($this->detailed, fn () => $patient->care_notes),
            ],
            'address' => [
                'line' => $address['line'] ?? null,
                'city' => $address['city'] ?? null,
                'access_notes' => $address['access_notes'] ?? null,
                'latitude' => $address['latitude'] ?? null,
                'longitude' => $address['longitude'] ?? null,
            ],
            /** Montant à encaisser en espèces, en centimes de dirham. */
            'amount_to_collect' => $this->payment_method === 'cash' ? $this->total_price : 0,
            'payment_method' => $this->payment_method,
            'has_prescription' => $this->prescription_file_id !== null,
            /** `home` : à domicile ; `remote` : téléconsultation. */
            'delivery_mode' => $this->service->delivery_mode->value,
            /** Ouverture et fermeture de la salle vidéo. Absent pour un soin à domicile. */
            'teleconsultation' => $this->when($this->service->isRemote(), function () {
                [$opensAt, $closesAt] = app(JoinTeleconsultation::class)->window($this->resource);

                return ['opens_at' => $opensAt->toIso8601String(), 'closes_at' => $closesAt->toIso8601String()];
            }),
            'patient_note' => $this->when($this->detailed, fn () => $this->patient_note),
        ];
    }
}
