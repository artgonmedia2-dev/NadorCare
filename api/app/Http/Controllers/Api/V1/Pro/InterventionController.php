<?php

namespace App\Http\Controllers\Api\V1\Pro;

use App\Actions\Interventions\RunIntervention;
use App\Actions\Interventions\WriteReport;
use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\InterventionResource;
use App\Http\Resources\Api\V1\MissionResource;
use App\Models\Booking;
use App\Models\Intervention;
use App\Models\InterventionReport;
use App\Models\Professional;
use App\Services\Health\AccessLogger;
use App\Support\Translated;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

#[Group('Professionnel — intervention', weight: 21)]
class InterventionController extends Controller
{
    private const RELATIONS = ['service:id,name,duration_minutes', 'patientProfile'];

    /**
     * Partir vers le domicile
     *
     * La réservation passe « en route ». Le patient est prévenu et peut suivre l'arrivée.
     */
    public function depart(Request $request, string $mission, RunIntervention $run): MissionResource
    {
        $booking = $run->depart($this->findMission($request, $mission), $request->user());

        return new MissionResource($booking->load(self::RELATIONS));
    }

    /**
     * Envoyer ma position
     *
     * À appeler régulièrement pendant le trajet. Refusé (`location_not_expected`) en dehors :
     * la position n'est suivie que lorsque le professionnel est en route.
     */
    public function location(Request $request, string $mission, RunIntervention $run): JsonResponse
    {
        $input = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            // Précision annoncée par le téléphone, en mètres.
            'accuracy' => ['sometimes', 'nullable', 'integer', 'between:0,5000'],
        ]);

        $eta = $run->recordLocation(
            $this->findMission($request, $mission),
            (float) $input['latitude'],
            (float) $input['longitude'],
            isset($input['accuracy']) ? (int) $input['accuracy'] : null,
        );

        return response()->json(['data' => [
            /** Durée estimée du trajet restant, en secondes. */
            'eta_seconds' => $eta,
        ]]);
    }

    /**
     * Pointer mon arrivée
     *
     * La réservation passe « en cours » et le compte rendu s'ouvre en brouillon.
     */
    public function arrive(Request $request, string $mission, RunIntervention $run): JsonResponse
    {
        $input = $request->validate([
            'latitude' => ['sometimes', 'nullable', 'required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'required_with:latitude', 'numeric', 'between:-180,180'],
        ]);

        $intervention = $run->arrive(
            $this->findMission($request, $mission),
            $request->user(),
            isset($input['latitude']) ? (float) $input['latitude'] : null,
            isset($input['longitude']) ? (float) $input['longitude'] : null,
        );

        return (new InterventionResource($intervention->load('reports')))->response()->setStatusCode(201);
    }

    /**
     * Actes et consommables proposés
     *
     * Listes dans lesquelles choisir pour remplir le compte rendu d'une mission. Un acte ou un
     * consommable absent de la liste peut être saisi librement.
     */
    public function reference(Request $request, string $mission): JsonResponse
    {
        $booking = $this->findMission($request, $mission);

        $acts = DB::table('acts')
            ->join('service_act', 'service_act.act_id', '=', 'acts.id')
            ->where('service_act.service_id', $booking->service_id)
            ->where('acts.is_active', true)
            ->orderBy('acts.id')
            ->get(['acts.id', 'acts.name']);

        $consumables = DB::table('consumables')->where('is_active', true)->orderBy('id')->get(['id', 'name', 'unit']);

        return response()->json(['data' => [
            /** @var list<array{id: string, name: string|null}> */
            'acts' => $acts->map(fn ($act) => ['id' => $act->id, 'name' => Translated::pick(json_decode($act->name, true))])->all(),
            /** @var list<array{id: string, name: string|null, unit: string|null}> */
            'consumables' => $consumables->map(fn ($item) => [
                'id' => $item->id,
                'name' => Translated::pick(json_decode($item->name, true)),
                'unit' => $item->unit,
            ])->all(),
        ]]);
    }

    /**
     * Lire le compte rendu en cours
     */
    public function show(Request $request, string $mission, AccessLogger $logger): InterventionResource
    {
        $intervention = $this->findIntervention($request, $mission);
        $this->logRead($logger, $intervention, $request);

        return new InterventionResource($intervention);
    }

    /**
     * Enregistrer le compte rendu
     *
     * Brouillon, enregistrable autant de fois que nécessaire. Les listes d'actes et de
     * consommables remplacent les précédentes.
     */
    public function saveReport(Request $request, string $mission, WriteReport $write): InterventionResource
    {
        $rules = [
            'vitals' => ['sometimes', 'nullable', 'array'],
            'observations' => ['sometimes', 'nullable', 'string', 'max:5000'],
            'acts' => ['sometimes', 'array', 'max:50'],
            'acts.*.act_id' => ['sometimes', 'nullable', 'string', 'exists:acts,id'],
            'acts.*.label' => ['required', 'string', 'max:200'],
            'acts.*.quantity' => ['sometimes', 'integer', 'between:1,100'],
            'consumables' => ['sometimes', 'array', 'max:50'],
            'consumables.*.consumable_id' => ['sometimes', 'nullable', 'string', 'exists:consumables,id'],
            'consumables.*.label' => ['required', 'string', 'max:200'],
            'consumables.*.quantity' => ['sometimes', 'numeric', 'between:0.01,1000'],
            // Heure de saisie sur le téléphone, utile quand le compte rendu a été rédigé hors ligne.
            'client_created_at' => ['sometimes', 'nullable', 'date'],
        ];

        // Chaque constante a ses bornes plausibles : une faute de frappe est refusée.
        foreach (InterventionReport::VITALS as $name => [$min, $max]) {
            $rules["vitals.$name"] = ['sometimes', 'nullable', 'numeric', "between:$min,$max"];
        }

        $input = $request->validate($rules);
        if (isset($input['vitals'])) {
            $input['vitals'] = array_intersect_key($input['vitals'], InterventionReport::VITALS);
        }

        $intervention = $this->findIntervention($request, $mission);
        $write->saveDraft($intervention, $request->user(), $input);

        return new InterventionResource($intervention->load('reports'));
    }

    /**
     * Ajouter une photo au compte rendu
     */
    public function addPhoto(Request $request, string $mission, WriteReport $write): JsonResponse
    {
        $request->validate(['file' => ['required', 'file', 'mimes:jpg,jpeg,png', 'max:10240']]);

        $upload = $request->file('file');
        $intervention = $this->findIntervention($request, $mission);
        $write->addPhoto($intervention, $request->user(), (string) $upload->get(), (string) $upload->getMimeType());

        return (new InterventionResource($intervention->load('reports')))->response()->setStatusCode(201);
    }

    /**
     * Enregistrer la signature
     *
     * Signature tracée à l'écran (image PNG) et nom de la personne qui signe : le patient,
     * ou un proche présent s'il ne peut pas signer.
     */
    public function sign(Request $request, string $mission, WriteReport $write): InterventionResource
    {
        $input = $request->validate([
            'file' => ['required', 'file', 'mimes:png', 'max:2048'],
            'signed_by_name' => ['required', 'string', 'min:2', 'max:120'],
        ]);

        $intervention = $this->findIntervention($request, $mission);
        $write->sign($intervention, $request->user(), (string) $request->file('file')->get(), $input['signed_by_name']);

        return new InterventionResource($intervention->load('reports'));
    }

    /**
     * Terminer l'intervention
     *
     * Pointe la fin, valide le compte rendu (il n'est plus modifiable) et termine la
     * réservation. Exige des observations et la signature.
     */
    public function complete(Request $request, string $mission, WriteReport $write): InterventionResource
    {
        $input = $request->validate([
            // Les espèces ont été remises au professionnel.
            'cash_collected' => ['required', 'boolean'],
            'latitude' => ['sometimes', 'nullable', 'required_with:longitude', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'required_with:latitude', 'numeric', 'between:-180,180'],
        ]);

        $intervention = $this->findIntervention($request, $mission);
        $write->complete(
            $intervention,
            $request->user(),
            (bool) $input['cash_collected'],
            isset($input['latitude']) ? (float) $input['latitude'] : null,
            isset($input['longitude']) ? (float) $input['longitude'] : null,
        );

        return new InterventionResource($intervention->refresh()->load('reports'));
    }

    /**
     * Corriger un compte rendu validé (avenant)
     *
     * L'original reste intact : la correction devient une nouvelle version, avec son motif.
     */
    public function amend(Request $request, string $intervention, WriteReport $write, AccessLogger $logger): JsonResponse
    {
        $rules = [
            'reason' => ['required', 'string', 'min:5', 'max:500'],
            'observations' => ['required', 'string', 'max:5000'],
            'vitals' => ['sometimes', 'nullable', 'array'],
        ];
        foreach (InterventionReport::VITALS as $name => [$min, $max]) {
            $rules["vitals.$name"] = ['sometimes', 'nullable', 'numeric', "between:$min,$max"];
        }
        $input = $request->validate($rules);

        // Le professionnel corrige ses propres comptes rendus, y compris après la fin de la mission.
        $found = Intervention::query()
            ->where('professional_id', $this->professional($request)->id)
            ->findOrFail($intervention);

        $write->amend(
            $found,
            $request->user(),
            $input['reason'],
            $input['observations'],
            isset($input['vitals']) ? array_intersect_key($input['vitals'], InterventionReport::VITALS) : null,
        );

        return (new InterventionResource($found->load('reports')))->response()->setStatusCode(201);
    }

    private function logRead(AccessLogger $logger, Intervention $intervention, Request $request): void
    {
        $booking = $intervention->booking;
        $logger->record(AccessAction::View, $intervention, $booking->patient_profile_id, $booking->id, $request->user());
    }

    private function professional(Request $request): Professional
    {
        $professional = $request->user()->professional()->first();

        if (! $professional) {
            throw new ApiException('professional_profile_required', 403);
        }

        return $professional;
    }

    private function findMission(Request $request, string $id): Booking
    {
        return Booking::query()
            ->with(self::RELATIONS)
            ->where('professional_id', $this->professional($request)->id)
            ->whereIn('status', BookingStatus::activeMission())
            ->findOrFail($id);
    }

    /**
     * Intervention en cours d'une mission : elle existe à partir du pointage d'arrivée.
     */
    private function findIntervention(Request $request, string $missionId): Intervention
    {
        $booking = $this->findMission($request, $missionId);

        $intervention = Intervention::query()->with(['reports', 'booking'])->where('booking_id', $booking->id)->first();

        if (! $intervention) {
            throw new ApiException('intervention_not_started', 409);
        }

        return $intervention;
    }
}
