<?php

namespace App\Actions\Professionals;

use App\Enums\VerificationStatus;
use App\Exceptions\ApiException;
use App\Models\Professional;
use App\Models\ProfessionalDocument;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use Illuminate\Support\Facades\DB;

/**
 * Vérification d'un professionnel par un administrateur (cahier des charges §3) : contrôle de
 * chaque justificatif, puis validation manuelle du dossier. Chaque décision est conservée dans
 * l'historique des contrôles et dans le journal des actions sensibles.
 */
class ReviewProfessional
{
    public function __construct(
        private readonly ManageProfessionalFile $file,
        private readonly AuditLogger $audit,
    ) {}

    public function approveDocument(ProfessionalDocument $document, User $reviewer): ProfessionalDocument
    {
        // Un justificatif déjà périmé ne peut pas être approuvé.
        if ($document->expires_at !== null && $document->expires_at->isBefore(today())) {
            throw new ApiException('document_expired');
        }

        return DB::transaction(function () use ($document, $reviewer) {
            // L'ancien justificatif approuvé du même type est remplacé par celui-ci.
            ProfessionalDocument::query()
                ->where('professional_id', $document->professional_id)
                ->where('type', $document->type)
                ->where('status', ProfessionalDocument::STATUS_APPROVED)
                ->whereKeyNot($document->getKey())
                ->update(['status' => ProfessionalDocument::STATUS_EXPIRED]);

            return $this->decide($document, $reviewer, ProfessionalDocument::STATUS_APPROVED, null);
        });
    }

    public function rejectDocument(ProfessionalDocument $document, User $reviewer, string $reason): ProfessionalDocument
    {
        return DB::transaction(fn () => $this->decide($document, $reviewer, ProfessionalDocument::STATUS_REJECTED, $reason));
    }

    /**
     * Valide le dossier : le compte peut alors recevoir des missions.
     * Tous les justificatifs exigés doivent être approuvés.
     */
    public function verify(Professional $professional, User $reviewer): Professional
    {
        if (! in_array($professional->verification_status, [VerificationStatus::Submitted, VerificationStatus::UnderReview], true)) {
            throw new ApiException('professional_file_not_submitted', 409);
        }

        $approved = $professional->documents()->where('status', ProfessionalDocument::STATUS_APPROVED)->pluck('type')->all();
        $notApproved = array_values(array_diff($this->file->requiredTypes($professional), $approved));

        if ($notApproved !== []) {
            throw new ApiException('documents_not_approved', 422, ['missing_documents' => $notApproved]);
        }

        return $this->changeStatus($professional, $reviewer, VerificationStatus::Verified, null, 'professional.verified', [
            'verified_at' => now(),
            'verified_by' => $reviewer->getKey(),
        ]);
    }

    /**
     * Refuse le dossier. Le professionnel peut le corriger puis le soumettre de nouveau.
     */
    public function reject(Professional $professional, User $reviewer, string $reason): Professional
    {
        if (! in_array($professional->verification_status, [VerificationStatus::Submitted, VerificationStatus::UnderReview], true)) {
            throw new ApiException('professional_file_not_submitted', 409);
        }

        return $this->changeStatus($professional, $reviewer, VerificationStatus::Rejected, $reason, 'professional.rejected');
    }

    /**
     * Suspend un professionnel vérifié : il ne reçoit plus aucune mission.
     */
    public function suspend(Professional $professional, User $reviewer, string $reason): Professional
    {
        if ($professional->verification_status !== VerificationStatus::Verified) {
            throw new ApiException('professional_not_verified', 409);
        }

        return $this->changeStatus($professional, $reviewer, VerificationStatus::Suspended, $reason, 'professional.suspended', ['is_online' => false]);
    }

    public function reinstate(Professional $professional, User $reviewer): Professional
    {
        if ($professional->verification_status !== VerificationStatus::Suspended) {
            throw new ApiException('professional_not_suspended', 409);
        }

        return $this->changeStatus($professional, $reviewer, VerificationStatus::Verified, null, 'professional.reinstated');
    }

    private function decide(ProfessionalDocument $document, User $reviewer, string $status, ?string $reason): ProfessionalDocument
    {
        $previous = $document->status;

        $document->update([
            'status' => $status,
            'reviewed_by' => $reviewer->getKey(),
            'reviewed_at' => now(),
            'rejection_reason' => $reason,
        ]);

        // Historique des contrôles (cahier des charges §3).
        DB::table('document_reviews')->insert([
            'id' => (string) str()->ulid(),
            'professional_document_id' => $document->getKey(),
            'reviewer_id' => $reviewer->getKey(),
            'decision' => $status,
            'comment' => $reason,
            'created_at' => now(),
        ]);

        $this->audit->record('professional_document.'.$status, $document, $reviewer, ['status' => $previous], ['status' => $status, 'type' => $document->type]);

        return $document;
    }

    /**
     * @param  array<string, mixed>  $extra
     */
    private function changeStatus(Professional $professional, User $reviewer, VerificationStatus $status, ?string $reason, string $event, array $extra = []): Professional
    {
        $previous = $professional->verification_status;

        $professional->forceFill(['verification_status' => $status, 'suspension_reason' => $reason, ...$extra])->save();

        $this->audit->record($event, $professional, $reviewer, ['status' => $previous->value], ['status' => $status->value, 'reason' => $reason]);

        return $professional;
    }
}
