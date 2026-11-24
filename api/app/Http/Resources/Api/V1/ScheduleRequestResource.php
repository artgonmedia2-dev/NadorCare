<?php

namespace App\Http\Resources\Api\V1;

use App\Models\ScheduleRequest;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Demande du soignant connecté sur son planning.
 *
 * @mixin ScheduleRequest
 */
class ScheduleRequestResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            /** `weekly` (nouvelle semaine type) ou `unavailability` (indisponibilité datée). */
            'kind' => $this->kind->value,
            /** `pending`, `accepted`, `refused` ou `cancelled`. */
            'status' => $this->status->value,
            /** Premier jour d'indisponibilité, `AAAA-MM-JJ`. */
            'starts_on' => $this->starts_on?->format('Y-m-d'),
            /** Dernier jour d'indisponibilité, compris. */
            'ends_on' => $this->ends_on?->format('Y-m-d'),
            /** Semaine proposée, heures de Nador. `weekday` : 0 = dimanche … 6 = samedi. */
            'slots' => $this->slots ?? [],
            'note' => $this->note,
            /** Motif donné par la coordination en cas de refus. */
            'decision_note' => $this->decision_note,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
