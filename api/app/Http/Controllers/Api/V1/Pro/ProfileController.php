<?php

namespace App\Http\Controllers\Api\V1\Pro;

use App\Actions\Professionals\ManageProfessionalFile;
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
     * Déposer un justificatif
     *
     * Photo ou PDF, chiffré avant stockage. L'assurance responsabilité civile est facultative ;
     * si elle est déposée, sa date d'expiration est obligatoire.
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
