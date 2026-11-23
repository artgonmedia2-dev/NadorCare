<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Service;
use App\Support\Translated;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Service
 */
class ServiceResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'name' => Translated::pick($this->name),
            'description' => Translated::pick($this->description),
            'duration_minutes' => $this->duration_minutes,
            /** Tarif indicatif, hors majorations (nuit, jour férié, distance). */
            'price' => [
                /** Montant en centimes de dirham. */
                'amount' => $this->base_price,
                'currency' => 'MAD',
            ],
            /** Une ordonnance doit être déposée pour confirmer la réservation. */
            'requires_prescription' => $this->requires_prescription,
            /** Le soin peut être programmé en série (plusieurs séances). */
            'allows_series' => $this->allows_series,
            /** `home` : à domicile ; `remote` : téléconsultation par appel vidéo. */
            'delivery_mode' => $this->delivery_mode->value,
            'category' => [
                'slug' => $this->category->slug,
                'name' => Translated::pick($this->category->name),
            ],
            /** Profession du soignant qui réalise ce soin. */
            'professional_category' => Translated::pick($this->professionalCategory->name),
        ];
    }
}
