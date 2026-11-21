<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Address;
use App\Support\Translated;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Address
 */
class AddressResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $zone = $this->zone;

        return [
            'id' => $this->id,
            'label' => $this->label,
            'line' => $this->line,
            'city' => $this->city,
            'latitude' => $this->location->getLatitude(),
            'longitude' => $this->location->getLongitude(),
            'access_notes' => $this->access_notes,
            'patient_profile_id' => $this->patient_profile_id,
            /** Zone qui contient l'adresse, ou `null` si aucune. */
            'zone' => $zone ? ['id' => $zone->id, 'name' => Translated::pick($zone->name)] : null,
            /** `true` si l'adresse est dans une zone où le service est ouvert. */
            'is_covered' => (bool) $zone?->is_active,
        ];
    }
}
