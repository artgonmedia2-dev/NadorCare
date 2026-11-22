<?php

namespace App\Http\Controllers\Api\V1\Pro;

use App\Actions\Assignment\RespondToOffer;
use App\Actions\Assignment\UnassignProfessional;
use App\Actions\Health\ReadPatientRecord;
use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\MissionOfferResource;
use App\Http\Resources\Api\V1\MissionResource;
use App\Models\Booking;
use App\Models\BookingOffer;
use App\Models\Professional;
use App\Services\Health\AccessLogger;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Points d'accès de l'application professionnel.
 */
#[Group('Professionnel — missions', weight: 20)]
class MissionController extends Controller
{
    private const RELATIONS = ['service:id,name,duration_minutes', 'patientProfile'];

    /**
     * Propositions de mission en attente
     *
     * Avant d'accepter, le professionnel ne voit que le soin, le créneau, la zone et la distance.
     */
    public function offers(Request $request): AnonymousResourceCollection
    {
        return MissionOfferResource::collection(
            BookingOffer::query()
                ->with('booking.service:id,name,duration_minutes')
                ->where('professional_id', $this->professional($request)->id)
                ->where('status', BookingOffer::STATUS_PENDING)
                ->where(fn ($query) => $query->whereNull('expires_at')->orWhere('expires_at', '>', now()))
                ->orderBy('expires_at')
                ->get()
        );
    }

    /**
     * Accepter une proposition
     *
     * La réservation est alors affectée au professionnel, qui accède au détail de la mission.
     * Répond `offer_unavailable` si le délai est dépassé ou si la proposition a été retirée.
     */
    public function accept(Request $request, string $offer, RespondToOffer $respond): MissionResource
    {
        $booking = $respond->accept($this->findOffer($request, $offer), $request->user());

        return new MissionResource($booking->load(self::RELATIONS));
    }

    /**
     * Refuser une proposition
     */
    public function decline(Request $request, string $offer, RespondToOffer $respond): MissionOfferResource
    {
        $input = $request->validate(['reason' => ['sometimes', 'nullable', 'string', 'max:500']]);

        $declined = $respond->decline($this->findOffer($request, $offer), $input['reason'] ?? null);

        return new MissionOfferResource($declined->load('booking.service:id,name,duration_minutes'));
    }

    /**
     * Mes missions
     *
     * Missions affectées, en route ou en cours. Sans donnée de santé.
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
     * Se désister d'une mission
     *
     * Possible tant que le professionnel n'est pas parti. La réservation retourne à la
     * coordination, qui cherche un autre soignant.
     */
    public function withdraw(Request $request, string $mission, UnassignProfessional $unassign): MissionResource
    {
        $input = $request->validate(['reason' => ['required', 'string', 'min:3', 'max:500']]);

        $booking = $this->findMission($request, $mission);
        $released = $unassign->handle($booking, $request->user(), $input['reason']);

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

    private function findOffer(Request $request, string $id): BookingOffer
    {
        return BookingOffer::query()
            ->where('professional_id', $this->professional($request)->id)
            ->findOrFail($id);
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
