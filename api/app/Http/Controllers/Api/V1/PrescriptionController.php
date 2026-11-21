<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AccessAction;
use App\Http\Controllers\Controller;
use App\Services\Files\EncryptedFileStore;
use App\Services\Health\AccessLogger;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

#[Group('Réservations', weight: 6)]
class PrescriptionController extends Controller
{
    /**
     * Déposer une ordonnance
     *
     * Photo ou PDF de l'ordonnance, à envoyer avant de réserver un soin qui l'exige.
     * Le fichier est chiffré avant d'être stocké. L'identifiant renvoyé se passe ensuite
     * dans `prescription_file_id`.
     */
    public function store(Request $request, EncryptedFileStore $files, AccessLogger $logger): JsonResponse
    {
        $request->validate([
            // Image JPEG ou PNG, ou PDF. 10 Mo au plus.
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:10240'],
        ]);

        $upload = $request->file('file');
        $user = $request->user();

        $file = $files->store(
            contents: (string) $upload->get(),
            category: 'prescription',
            mime: (string) $upload->getMimeType(),
            owner: $user,
            uploader: $user,
        );

        $logger->record(AccessAction::Create, $file, actor: $user);

        return response()->json([
            'data' => [
                'id' => $file->id,
                'mime' => $file->mime,
                'size' => $file->size,
            ],
        ], 201);
    }
}
