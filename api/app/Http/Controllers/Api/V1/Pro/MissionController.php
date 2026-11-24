<?php

namespace App\Http\Controllers\Api\V1\Pro;

use App\Actions\Assignment\RespondToAssignment;
use App\Actions\Health\ReadPatientRecord;
use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Enums\DeclineReason;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\MissionResource;
use App\Models\Booking;
use App\Models\Professional;
use App\Services\Health\AccessLogger;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/**
 * Points d'accès de l'application professionnel.
 */
#[Group('Professionnel — missions', weight: 20)]
class MissionController extends Controller
{
    private const RELATIONS = ['service:id,name,duration_minutes,delivery_mode', 'patientProfile'];

    /**
     * Mes missions
     *
     * Missions affectées, en route ou en cours. Sans donnée de santé. Une mission affectée
     * attend la confirmation du soignant tant que `needs_confirmation` est vrai.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        return MissionResource::collection(
            Booking::query()
                ->with(self::RELATIONS)
                ->where('professional_id', $this->professional($request)->id)
                ->whereIn('status', BookingStatus::activeMission())
                ->orderBy('scheduled_at')
                ->get()
        );
    }

    /**
     * Détail d'une mission
     *
     * Ajoute les informations utiles au soin et la note du patient. Accessible uniquement
     * pendant la mission ; chaque lecture est inscrite au journal des accès.
     */
    public function show(Request $request, string $mission, ReadPatientRecord $read, AccessLogger $logger): MissionResource
    {
        $booking = $this->findMission($request, $mission);

        // Vérifie le cloisonnement par mission et journalise la lecture du dossier.
        $read->handle($request->user(), $booking->patientProfile, $booking);
        $logger->record(AccessAction::View, $booking, $booking->patient_profile_id, $booking->id, $request->user());

        return (new MissionResource($booking))->detailed();
    }

    /**
     * Confirmer la prise en charge d'une mission
     *
     * À faire avant l'heure `confirm_by` : passé ce délai, la coordination est alertée.
     */
    public function confirm(Request $request, string $mission, RespondToAssignment $respond): MissionResource
    {
        $booking = $respond->confirm($this->findMission($request, $mission), $request->user());

        return new MissionResource($booking->load(self::RELATIONS));
    }

    /**
     * Signaler mon indisponibilité pour une mission
     *
     * Possible tant que le soignant n'est pas parti. La réservation retourne à la
     * coordination, qui affecte un autre soignant.
     */
    public function decline(Request $request, string $mission, RespondToAssignment $respond): MissionResource
    {
        $input = $request->validate([
            // `busy` (déjà en intervention), `sick`, `personal` ou `other`.
            'reason' => ['required', Rule::enum(DeclineReason::class)],
            // Précision libre ; obligatoire avec `other`.
            'note' => ['sometimes', 'nullable', 'string', 'max:500'],
        ]);

        $released = $respond->decline(
            $this->findMission($request, $mission),
            $request->user(),
            DeclineReason::from($input['reason']),
            $input['note'] ?? null,
        );

        return new MissionResource($released->load(self::RELATIONS));
    }

    private function professional(Request $request): Professional
    {
        $professional = $request->user()->professional()->first();

        if (! $professional) {
            throw new ApiException('professional_profile_required', 403);
        }

        return $professional;
    }

    /**
     * Une mission d'un autre professionnel, ou terminée, est « introuvable ».
     */
    private function findMission(Request $request, string $id): Booking
    {
        return Booking::query()
            ->with(self::RELATIONS)
            ->where('professional_id', $this->professional($request)->id)
            ->whereIn('status', BookingStatus::activeMission())
            ->findOrFail($id);
    }
}
