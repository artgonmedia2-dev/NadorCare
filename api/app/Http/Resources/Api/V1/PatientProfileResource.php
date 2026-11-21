<?php

namespace App\Http\Resources\Api\V1;

use App\Models\PatientProfile;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin PatientProfile
 */
class PatientProfileResource extends JsonResource
{
    /**
     * Les notes de soin ne sortent que sur demande explicite (fiche détaillée, création,
     * modification), jamais dans une liste : chaque sortie est journalisée par l'appelant.
     */
    private bool $withCareNotes = false;

    public function withCareNotes(): static
    {
        $this->withCareNotes = true;

        return $this;
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'relationship' => $this->relationship,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            /** @format date */
            'birth_date' => $this->birth_date?->format('Y-m-d'),
            'sex' => $this->sex,
            'phone' => $this->phone,
            'has_care_notes' => $this->care_notes !== null && $this->care_notes !== '',
            'care_notes' => $this->when($this->withCareNotes, fn () => $this->care_notes),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
