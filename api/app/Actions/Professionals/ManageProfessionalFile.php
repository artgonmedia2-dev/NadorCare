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
    /**
     * Justificatifs qu'un soignant peut déposer sans qu'ils soient exigés. L'assurance
     * responsabilité civile personnelle est facultative depuis le modèle « agence » (règle
     * n° 8 du 2026-11-23), en attendant l'avis du juriste : c'est l'agence qui est assurée.
     */
    public const OPTIONAL_TYPES = [ProfessionalDocument::TYPE_RC_INSURANCE];

    /** Statuts dans lesquels le professionnel peut encore modifier son dossier. */
    private const EDITABLE = [VerificationStatus::Draft, VerificationStatus::Rejected];

    public function __construct(private readonly EncryptedFileStore $files) {}

    /**
     * Crée le dossier, ou le met à jour tant qu'il n'est pas soumis.
     *
     * N'est plus exposé par l'API depuis le modèle « agence » : la fiche d'un soignant se crée
     * et se modifie au back-office, par `ManageTeam`.
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
    public function uploadDocument(Professional $professional, string $type, string $contents, string $mime, ?string $expiresAt, ?User $uploader = null): ProfessionalDocument
    {
        // Par défaut le soignant lui-même ; sinon la personne de l'agence qui dépose pour lui.
        $uploader ??= $professional->user;

        if ($professional->verification_status === VerificationStatus::Suspended) {
            throw new ApiException('professional_file_locked', 409);
        }

        if (! in_array($type, $this->acceptedTypes($professional), true)) {
            throw new ApiException('document_type_not_expected');
        }

        // L'assurance est suivie par sa date d'expiration (cahier des charges §3).
        if ($type === ProfessionalDocument::TYPE_RC_INSURANCE && $expiresAt === null) {
            throw new ApiException('document_expiry_required');
        }

        return DB::transaction(function () use ($professional, $type, $contents, $mime, $expiresAt, $uploader) {
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

            $file = $this->files->store($contents, 'professional_document', $mime, $professional, $uploader);

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
     * Justificatifs facultatifs que le dossier peut recevoir en plus de ceux exigés.
     *
     * @return list<string>
     */
    public function optionalTypes(Professional $professional): array
    {
        return array_values(array_diff(self::OPTIONAL_TYPES, $this->requiredTypes($professional)));
    }

    /**
     * Tout ce qui peut être déposé dans le dossier : exigé ou facultatif.
     *
     * @return list<string>
     */
    public function acceptedTypes(Professional $professional): array
    {
        return [...$this->requiredTypes($professional), ...$this->optionalTypes($professional)];
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
