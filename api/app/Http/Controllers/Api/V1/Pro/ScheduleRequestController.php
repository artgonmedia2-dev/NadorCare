<?php

namespace App\Http\Controllers\Api\V1\Pro;

use App\Actions\Professionals\ManagePlanning;
use App\Enums\ScheduleRequestKind;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ScheduleRequestResource;
use App\Models\Professional;
use App\Models\ScheduleRequest;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/**
 * Le planning est tenu par la coordination : le soignant ne le modifie pas, il fait une
 * demande que la coordination accepte ou refuse.
 */
#[Group('Professionnel — planning', weight: 20)]
class ScheduleRequestController extends Controller
{
    /**
     * Mes demandes de planning
     *
     * Les trente plus récentes, de la plus récente à la plus ancienne.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        return ScheduleRequestResource::collection(
            ScheduleRequest::query()
                ->where('professional_id', $this->professional($request)->id)
                ->orderByDesc('created_at')->orderByDesc('id')
                ->limit(30)
                ->get()
        );
    }

    /**
     * Proposer une semaine type ou signaler une indisponibilité
     *
     * Rien ne change dans le planning tant que la coordination n'a pas accepté.
     */
    public function store(Request $request, ManagePlanning $planning): JsonResponse
    {
        $input = $request->validate([
            // `weekly` ou `unavailability`.
            'kind' => ['required', Rule::enum(ScheduleRequestKind::class)],
            // Semaine proposée (pour `weekly`). Heures de Nador ; `weekday` : 0 = dimanche … 6 = samedi.
            'slots' => ['required_if:kind,weekly', 'array', 'max:42'],
            'slots.*.weekday' => ['required', 'integer', 'between:0,6'],
            'slots.*.start_time' => ['required', 'date_format:H:i'],
            'slots.*.end_time' => ['required', 'date_format:H:i'],
            // Premier et dernier jour d'indisponibilité (pour `unavailability`), `AAAA-MM-JJ`.
            'starts_on' => ['required_if:kind,unavailability', 'date_format:Y-m-d'],
            'ends_on' => ['required_if:kind,unavailability', 'date_format:Y-m-d'],
            'note' => ['sometimes', 'nullable', 'string', 'max:500'],
        ]);

        $professional = $this->professional($request);
        $note = $input['note'] ?? null;

        $created = $input['kind'] === ScheduleRequestKind::Weekly->value
            ? $planning->proposeWeek($professional, array_values($input['slots']), $note)
            : $planning->reportUnavailability($professional, $input['starts_on'], $input['ends_on'], $note);

        return (new ScheduleRequestResource($created->refresh()))->response()->setStatusCode(201);
    }

    /**
     * Retirer une demande en attente
     *
     * Répond `schedule_request_closed` si la coordination a déjà répondu.
     */
    public function destroy(Request $request, string $scheduleRequest, ManagePlanning $planning): ScheduleRequestResource
    {
        $professional = $this->professional($request);
        $found = ScheduleRequest::query()->where('professional_id', $professional->id)->find($scheduleRequest);

        if (! $found) {
            throw new ApiException('not_found', 404);
        }

        return new ScheduleRequestResource($planning->cancel($found, $professional));
    }

    private function professional(Request $request): Professional
    {
        // Relu en base à chaque requête : l'état du dossier change par le back-office.
        $professional = $request->user()->professional()->first();

        if (! $professional) {
            throw new ApiException('professional_profile_required', 403);
        }

        return $professional;
    }
}
