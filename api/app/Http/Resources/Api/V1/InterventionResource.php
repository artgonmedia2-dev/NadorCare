<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Intervention;
use App\Models\InterventionReport;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\DB;

/**
 * Intervention et son compte rendu. Contient des données de santé : l'appelant vérifie
 * le droit d'accès et journalise la lecture.
 *
 * @mixin Intervention
 */
class InterventionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $reports = $this->reports;
        $original = $reports->firstWhere('version', 1);
        // Version qui fait foi : le dernier avenant, sinon l'original.
        $current = $reports->last();

        return [
            'id' => $this->id,
            'booking_id' => $this->booking_id,
            /** `in_progress` tant que le compte rendu n'est pas validé, puis `validated`. */
            'status' => $this->status,
            'arrived_at' => $this->arrived_at?->toIso8601String(),
            'ended_at' => $this->ended_at?->toIso8601String(),
            'report' => $current ? [
                'version' => $current->version,
                /** Constantes relevées : `systolic`, `diastolic`, `pulse`, `temperature`, `glucose`, `spo2`. */
                'vitals' => $current->vitals ?? (object) [],
                'observations' => $current->observations,
                'signed_by_name' => $current->signed_by_name,
                'is_signed' => $current->signature_file_id !== null,
                'photos_count' => $original ? $original->photos()->count() : 0,
                'validated_at' => $current->validated_at?->toIso8601String(),
                /** Motif de la correction, si cette version est un avenant. */
                'amendment_reason' => $current->amendment_reason,
            ] : null,
            /** @var list<array{act_id: string|null, label: string, quantity: int}> */
            'acts' => DB::table('intervention_acts')->where('intervention_id', $this->id)->orderBy('id')
                ->get(['act_id', 'label', 'quantity'])
                ->map(fn ($act) => ['act_id' => $act->act_id, 'label' => $act->label, 'quantity' => (int) $act->quantity])->all(),
            /** @var list<array{consumable_id: string|null, label: string, quantity: float}> */
            'consumables' => DB::table('intervention_consumables')->where('intervention_id', $this->id)->orderBy('id')
                ->get(['consumable_id', 'label', 'quantity'])
                ->map(fn ($item) => ['consumable_id' => $item->consumable_id, 'label' => $item->label, 'quantity' => (float) $item->quantity])->all(),
            /** Historique des versions : l'original puis les avenants. */
            'versions' => $reports->filter(fn (InterventionReport $report) => $report->isValidated())
                ->map(fn (InterventionReport $report) => [
                    'version' => $report->version,
                    'validated_at' => $report->validated_at?->toIso8601String(),
                    'amendment_reason' => $report->amendment_reason,
                ])->values()->all(),
        ];
    }
}
