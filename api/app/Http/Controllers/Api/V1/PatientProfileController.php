<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Health\ReadPatientRecord;
use App\Actions\Patients\DeletePatientProfile;
use App\Actions\Patients\SavePatientProfile;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\PatientProfileRequest;
use App\Http\Resources\Api\V1\PatientProfileResource;
use App\Models\PatientProfile;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

#[Group('Profils de patients', weight: 3)]
class PatientProfileController extends Controller
{
    /**
     * Mes profils de patients
     *
     * Un compte gère plusieurs profils : soi-même, un parent, un enfant. Les notes de soin
     * ne figurent pas dans la liste.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        return PatientProfileResource::collection(
            $request->user()->patientProfiles()->orderBy('created_at')->get()
        );
    }

    /**
     * Ajouter un profil
     */
    public function store(PatientProfileRequest $request, SavePatientProfile $save): JsonResponse
    {
        $profile = $save->create($request->user(), $request->validated());

        return (new PatientProfileResource($profile))->withCareNotes()->response()->setStatusCode(201);
    }

    /**
     * Détail d'un profil
     *
     * Renvoie aussi les notes de soin. Cette lecture est inscrite au journal des accès.
     */
    public function show(Request $request, string $patientProfile, ReadPatientRecord $read): PatientProfileResource
    {
        $profile = $read->handle($request->user(), $this->find($request, $patientProfile));

        return (new PatientProfileResource($profile))->withCareNotes();
    }

    /**
     * Modifier un profil
     */
    public function update(PatientProfileRequest $request, string $patientProfile, SavePatientProfile $save): PatientProfileResource
    {
        $profile = $save->update($request->user(), $this->find($request, $patientProfile), $request->validated());

        return (new PatientProfileResource($profile))->withCareNotes();
    }

    /**
     * Retirer un profil
     *
     * Refusé (`profile_in_use`) tant qu'un soin est prévu ou en cours pour ce patient.
     */
    public function destroy(Request $request, string $patientProfile, DeletePatientProfile $delete): Response
    {
        $delete->handle($this->find($request, $patientProfile));

        return response()->noContent();
    }

    /**
     * Le profil est cherché parmi ceux du compte : celui d'un autre compte est « introuvable »,
     * ce qui ne révèle pas son existence.
     */
    private function find(Request $request, string $id): PatientProfile
    {
        return $request->user()->patientProfiles()->findOrFail($id);
    }
}
