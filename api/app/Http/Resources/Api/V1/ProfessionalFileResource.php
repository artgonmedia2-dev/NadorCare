<?php

namespace App\Http\Resources\Api\V1;

use App\Actions\Professionals\ManageProfessionalFile;
use App\Enums\VerificationStatus;
use App\Models\Professional;
use App\Models\ProfessionalDocument;
use App\Models\Zone;
use App\Support\Translated;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\DB;

/**
 * Dossier du professionnel connecté : profession, justificatifs, état de la vérification,
 * zones et agenda.
 *
 * @mixin Professional
 */
class ProfessionalFileResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $file = app(ManageProfessionalFile::class);
        $missing = $file->missingTypes($this->resource);
        $editable = in_array($this->verification_status, [VerificationStatus::Draft, VerificationStatus::Rejected], true);

        // Le dépôt le plus récent de chaque type.
        $documents = $this->documents()->orderByDesc('created_at')->orderByDesc('id')->get()->unique('type')->values();

        return [
            'id' => $this->id,
            /** `draft`, `submitted`, `under_review`, `verified`, `rejected` ou `suspended`. */
            'verification_status' => $this->verification_status->value,
            /** Motif du refus ou de la suspension. */
            'status_reason' => $this->suspension_reason,
            'category' => [
                'id' => $this->professional_category_id,
                'code' => $this->category->code,
                'name' => Translated::pick($this->category->name),
            ],
            'license_number' => $this->license_number,
            'order_number' => $this->order_number,
            'is_online' => $this->is_online,
            /** Justificatifs exigés pour cette profession. */
            'required_documents' => $file->requiredTypes($this->resource),
            /** Justificatifs exigés qui restent à déposer. */
            'missing_documents' => $missing,
            /** @var list<array{id: string, type: string, status: string, expires_at: string|null, rejection_reason: string|null}> */
            'documents' => $documents->map(fn (ProfessionalDocument $document) => [
                'id' => $document->id,
                'type' => $document->type,
                'status' => $document->status,
                'expires_at' => $document->expires_at?->format('Y-m-d'),
                'rejection_reason' => $document->rejection_reason,
            ])->all(),
            /** Le dossier est complet et peut être soumis. */
            'can_submit' => $editable && $missing === [],
            /** @var list<array{id: string, name: string|null}> */
            'zones' => $this->zones()->get(['zones.id', 'zones.name'])
                ->map(fn (Zone $zone) => ['id' => $zone->id, 'name' => Translated::pick($zone->name)])->all(),
            /** Agenda hebdomadaire, heures de Nador. `weekday` : 0 = dimanche … 6 = samedi. */
            'availabilities' => DB::table('availabilities')
                ->where('professional_id', $this->id)
                ->orderBy('weekday')->orderBy('start_time')
                ->get(['weekday', 'start_time', 'end_time'])
                ->map(fn ($slot) => [
                    'weekday' => (int) $slot->weekday,
                    'start_time' => substr((string) $slot->start_time, 0, 5),
                    'end_time' => substr((string) $slot->end_time, 0, 5),
                ])->all(),
        ];
    }
}
