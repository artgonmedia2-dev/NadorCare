<?php

namespace App\Http\Controllers\Api\V1\Pro;

use App\Actions\Professionals\ManageProfessionalFile;
use App\Actions\Professionals\UpdateProfessionalSchedule;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ProfessionalFileResource;
use App\Models\Professional;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

#[Group('Professionnel — dossier', weight: 19)]
class ProfileController extends Controller
{
    private const DOCUMENT_TYPES = ['identity', 'diploma', 'practice_authorization', 'order_registration', 'rc_insurance'];

    /**
     * Mon dossier professionnel
     *
     * Répond `professional_profile_required` tant que le dossier n'a pas été créé.
     */
    public function show(Request $request): ProfessionalFileResource
    {
        return new ProfessionalFileResource($this->professional($request));
    }

    /**
     * Créer ou modifier mon dossier
     *
     * Possible tant que le dossier n'est pas soumis, ou après un refus.
     */
    public function save(Request $request, ManageProfessionalFile $file): JsonResponse
    {
        $input = $request->validate([
            // Profession, parmi celles de `GET /catalogue/professional-categories`.
            'professional_category_id' => ['required', 'string'],
            // Numéro d'autorisation d'exercice.
            'license_number' => ['sometimes', 'nullable', 'string', 'max:60'],
            // Numéro d'inscription à l'Ordre, pour les professions qui en ont un.
            'order_number' => ['sometimes', 'nullable', 'string', 'max:60'],
        ]);

        $professional = $file->save($request->user(), $input)->load('category');

        // Création ou modification : la réponse est la même (200), comme pour tout PUT.
        return (new ProfessionalFileResource($professional))->response()->setStatusCode(200);
    }

    /**
     * Déposer un justificatif
     *
     * Photo ou PDF, chiffré avant stockage. La date d'expiration est obligatoire pour
     * l'assurance responsabilité civile.
     */
    public function uploadDocument(Request $request, ManageProfessionalFile $file): JsonResponse
    {
        $input = $request->validate([
            // `identity`, `diploma`, `practice_authorization`, `order_registration` ou `rc_insurance`.
            'type' => ['required', Rule::in(self::DOCUMENT_TYPES)],
            // Image JPEG ou PNG, ou PDF. 10 Mo au plus.
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:10240'],
            // Date de fin de validité, `AAAA-MM-JJ`.
            'expires_at' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'after:today'],
        ]);

        $professional = $this->professional($request);
        $upload = $request->file('file');

        $file->uploadDocument(
            $professional,
            $input['type'],
            (string) $upload->get(),
            (string) $upload->getMimeType(),
            $input['expires_at'] ?? null,
        );

        return (new ProfessionalFileResource($professional->refresh()))->response()->setStatusCode(201);
    }

    /**
     * Soumettre mon dossier à la vérification
     *
     * Répond `documents_missing` avec la liste des justificatifs qui manquent.
     */
    public function submit(Request $request, ManageProfessionalFile $file): ProfessionalFileResource
    {
        return new ProfessionalFileResource($file->submit($this->professional($request)));
    }

    /**
     * Choisir mes zones
     *
     * Remplace la liste des zones couvertes, parmi celles de `GET /catalogue/zones`.
     */
    public function zones(Request $request, UpdateProfessionalSchedule $schedule): ProfessionalFileResource
    {
        $input = $request->validate([
            'zone_ids' => ['present', 'array', 'max:50'],
            'zone_ids.*' => ['string', 'distinct'],
        ]);

        $professional = $this->professional($request);
        $schedule->setZones($professional, array_values($input['zone_ids']));

        return new ProfessionalFileResource($professional);
    }

    /**
     * Définir mon agenda hebdomadaire
     *
     * Remplace toutes les plages. Heures de Nador ; `weekday` : 0 = dimanche … 6 = samedi.
     */
    public function availabilities(Request $request, UpdateProfessionalSchedule $schedule): ProfessionalFileResource
    {
        $input = $request->validate([
            'availabilities' => ['present', 'array', 'max:42'],
            'availabilities.*.weekday' => ['required', 'integer', 'between:0,6'],
            'availabilities.*.start_time' => ['required', 'date_format:H:i'],
            'availabilities.*.end_time' => ['required', 'date_format:H:i'],
        ]);

        $professional = $this->professional($request);
        $schedule->setAvailabilities($professional, array_values($input['availabilities']));

        return new ProfessionalFileResource($professional);
    }

    /**
     * Me mettre en ligne ou hors ligne
     *
     * Réservé aux professionnels vérifiés.
     */
    public function online(Request $request, UpdateProfessionalSchedule $schedule): ProfessionalFileResource
    {
        $input = $request->validate(['is_online' => ['required', 'boolean']]);

        return new ProfessionalFileResource($schedule->setOnline($this->professional($request), (bool) $input['is_online']));
    }

    private function professional(Request $request): Professional
    {
        // Relu en base à chaque requête : l'état du dossier change par le back-office.
        $professional = $request->user()->professional()->with('category')->first();

        if (! $professional) {
            throw new ApiException('professional_profile_required', 403);
        }

        return $professional;
    }
}
