<?php

namespace App\Actions\Professionals;

use App\Enums\VerificationStatus;
use App\Exceptions\ApiException;
use App\Models\Professional;
use App\Models\ProfessionalCategory;
use App\Models\ProfessionalDocument;
use App\Models\User;
use App\Services\Files\EncryptedFileStore;
use Illuminate\Support\Facades\DB;

/**
 * Dossier d'inscription d'un professionnel (cahier des charges §5) : il choisit sa profession,
 * dépose ses justificatifs, puis soumet le dossier à la vérification.
 *
 * Tant que le dossier n'est pas vérifié par un administrateur, le compte ne reçoit aucune mission.
 */
class ManageProfessionalFile
{
    /** Statuts dans lesquels le professionnel peut encore modifier son dossier. */
    private const EDITABLE = [VerificationStatus::Draft, VerificationStatus::Rejected];

    public function __construct(private readonly EncryptedFileStore $files) {}

    /**
     * Crée le dossier, ou le met à jour tant qu'il n'est pas soumis.
     *
     * @param  array{professional_category_id: string, license_number?: string|null, order_number?: string|null}  $data
     */
    public function save(User $user, array $data): Professional
    {
        $category = ProfessionalCategory::query()->where('is_active', true)->find($data['professional_category_id']);

        if (! $category) {
            throw new ApiException('professional_category_unavailable');
        }

        // Relu en base : l'état du dossier décide si la modification est encore permise.
        $professional = $user->professional()->first() ?? new Professional(['user_id' => $user->getKey()]);

        if ($professional->exists && ! in_array($professional->verification_status, self::EDITABLE, true)) {
            throw new ApiException('professional_file_locked', 409);
        }

        $professional->fill([
            'professional_category_id' => $category->id,
            'license_number' => $data['license_number'] ?? null,
            'order_number' => $data['order_number'] ?? null,
        ]);
        $professional->verification_status ??= VerificationStatus::Draft;
        $professional->save();

        // Relit les valeurs posées par la base (hors ligne par défaut, compteurs).
        $professional->refresh();
        $user->setRelation('professional', $professional);

        return $professional;
    }

    /**
     * Dépose un justificatif. Il remplace le dépôt précédent du même type s'il n'a pas encore
     * été contrôlé ; un justificatif approuvé reste valable jusqu'à l'approbation de son
     * remplaçant (renouvellement de l'assurance, par exemple).
     */
    public function uploadDocument(Professional $professional, string $type, string $contents, string $mime, ?string $expiresAt): ProfessionalDocument
    {
        if ($professional->verification_status === VerificationStatus::Suspended) {
            throw new ApiException('professional_file_locked', 409);
        }

        if (! in_array($type, $this->requiredTypes($professional), true)) {
            throw new ApiException('document_type_not_expected');
        }

        // L'assurance est suivie par sa date d'expiration (cahier des charges §3).
        if ($type === ProfessionalDocument::TYPE_RC_INSURANCE && $expiresAt === null) {
            throw new ApiException('document_expiry_required');
        }

        return DB::transaction(function () use ($professional, $type, $contents, $mime, $expiresAt) {
            // Seul un dépôt pas encore contrôlé est effacé. Un justificatif refusé reste
            // dans le dossier : il fait partie de l'historique des contrôles.
            $replaced = $professional->documents()
                ->where('type', $type)
                ->where('status', ProfessionalDocument::STATUS_PENDING)
                ->get();

            foreach ($replaced as $old) {
                $file = $old->file;
                $old->delete();
                if ($file) {
                    $this->files->delete($file);
                }
            }

            $file = $this->files->store($contents, 'professional_document', $mime, $professional, $professional->user);

            return ProfessionalDocument::create([
                'professional_id' => $professional->id,
                'type' => $type,
                'file_id' => $file->id,
                'expires_at' => $expiresAt,
                'status' => ProfessionalDocument::STATUS_PENDING,
            ]);
        });
    }

    /**
     * Soumet le dossier : tous les justificatifs exigés pour la profession doivent être déposés.
     */
    public function submit(Professional $professional): Professional
    {
        if (! in_array($professional->verification_status, self::EDITABLE, true)) {
            throw new ApiException('professional_file_locked', 409);
        }

        $missing = $this->missingTypes($professional);

        if ($missing !== []) {
            throw new ApiException('documents_missing', 422, ['missing_documents' => $missing]);
        }

        $professional->forceFill(['verification_status' => VerificationStatus::Submitted, 'suspension_reason' => null])->save();

        return $professional;
    }

    /**
     * Justificatifs exigés pour la profession du dossier.
     *
     * @return list<string>
     */
    public function requiredTypes(Professional $professional): array
    {
        return array_values($professional->category->required_document_types ?? []);
    }

    /**
     * Justificatifs exigés qui n'ont aucun dépôt utilisable (en attente ou approuvé).
     *
     * @return list<string>
     */
    public function missingTypes(Professional $professional): array
    {
        $present = $professional->documents()
            ->whereIn('status', [ProfessionalDocument::STATUS_PENDING, ProfessionalDocument::STATUS_APPROVED])
            ->pluck('type')
            ->all();

        return array_values(array_diff($this->requiredTypes($professional), $present));
    }
}
