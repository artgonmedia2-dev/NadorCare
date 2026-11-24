<?php

namespace App\Actions\Professionals;

use App\Contracts\SmsGateway;
use App\Enums\Permission;
use App\Enums\Role;
use App\Enums\UserStatus;
use App\Enums\VerificationStatus;
use App\Exceptions\ApiException;
use App\Models\Professional;
use App\Models\ProfessionalCategory;
use App\Models\ProfessionalDocument;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Support\PhoneNumber;
use Illuminate\Support\Facades\DB;

/**
 * Équipe de l'agence (décision du 2026-11-23) : Nador Care soigne avec ses propres soignants.
 * C'est l'agence, depuis le back-office, qui fait entrer quelqu'un dans l'équipe, tient sa
 * fiche et l'invite à ouvrir l'application. Un soignant ne s'inscrit plus lui-même.
 */
class ManageTeam
{
    public function __construct(
        private readonly SmsGateway $sms,
        private readonly AuditLogger $audit,
        private readonly ManageProfessionalFile $file,
        private readonly ReviewProfessional $review,
    ) {}

    /**
     * Fait entrer un soignant dans l'équipe. Sa fiche naît en brouillon : il ne reçoit aucune
     * mission tant que son dossier n'est pas validé.
     *
     * Si le numéro appartient déjà à un compte (un patient, par exemple), ce compte est rattaché
     * à l'équipe : une même personne peut être patient et soignant.
     *
     * @param  array{name: string, phone: string, professional_category_id: string, license_number?: string|null, order_number?: string|null}  $data
     */
    public function create(User $actor, array $data): Professional
    {
        $phone = PhoneNumber::normalize($data['phone']);

        if ($phone === null) {
            throw new ApiException('phone_invalid');
        }

        $category = $this->category($data['professional_category_id']);

        return DB::transaction(function () use ($actor, $data, $phone, $category) {
            $user = User::query()->where('phone', $phone)->lockForUpdate()->first();

            if ($user && $user->professional()->exists()) {
                throw new ApiException('team_member_exists', 409);
            }

            if (! $user) {
                $user = new User(['phone' => $phone, 'locale' => 'fr', 'status' => UserStatus::Active]);
            }
            $user->name = trim($data['name']);
            $user->save();

            if (! $user->hasRole(Role::Professionnel->value)) {
                $user->assignRole(Role::Professionnel->value);
            }

            $professional = new Professional([
                'user_id' => $user->getKey(),
                'professional_category_id' => $category->id,
                'license_number' => $data['license_number'] ?? null,
                'order_number' => $data['order_number'] ?? null,
                'verification_status' => VerificationStatus::Draft,
            ]);
            $professional->created_by = $actor->getKey();
            $professional->save();

            $this->audit->record('team.member_created', $professional, $actor, null, [
                'professional_category_id' => $category->id,
            ]);

            return $professional->refresh();
        });
    }

    /**
     * Met à jour la fiche d'un soignant. Le numéro de téléphone est son identifiant de
     * connexion : il ne peut pas être celui d'un autre compte.
     *
     * @param  array{name: string, phone: string, professional_category_id: string, license_number?: string|null, order_number?: string|null}  $data
     */
    public function update(Professional $professional, User $actor, array $data): Professional
    {
        $phone = PhoneNumber::normalize($data['phone']);

        if ($phone === null) {
            throw new ApiException('phone_invalid');
        }

        $category = $this->category($data['professional_category_id']);

        return DB::transaction(function () use ($professional, $actor, $data, $phone, $category) {
            $user = User::query()->lockForUpdate()->findOrFail($professional->user_id);

            if (User::query()->where('phone', $phone)->whereKeyNot($user->getKey())->exists()) {
                throw new ApiException('phone_already_used', 409);
            }

            $before = [
                'professional_category_id' => $professional->professional_category_id,
                'phone_changed' => false,
            ];

            $phoneChanged = $user->phone !== $phone;
            $user->forceFill(['name' => trim($data['name']), 'phone' => $phone])->save();

            // Un nouveau numéro n'a pas encore reçu d'invitation, et les sessions ouvertes avec
            // l'ancien ne doivent plus donner accès aux missions.
            if ($phoneChanged) {
                $user->tokens()->delete();
                $professional->invited_at = null;
            }

            $professional->fill([
                'professional_category_id' => $category->id,
                'license_number' => $data['license_number'] ?? null,
                'order_number' => $data['order_number'] ?? null,
            ])->save();

            $this->audit->record('team.member_updated', $professional, $actor, $before, [
                'professional_category_id' => $category->id,
                'phone_changed' => $phoneChanged,
            ]);

            return $professional->refresh();
        });
    }

    /**
     * Invite le soignant à ouvrir l'application : un SMS avec le lien de téléchargement.
     * Il se connecte ensuite avec ce même numéro et un code reçu par SMS, sans mot de passe.
     */
    public function invite(Professional $professional, User $actor): Professional
    {
        $user = User::query()->findOrFail($professional->user_id);

        if (! $user->isActive()) {
            throw new ApiException('account_suspended', 409);
        }

        // Le message part dans la langue du soignant et ne contient aucune donnée de patient.
        $this->sms->send($user->phone, __('api.team.invitation_sms', [
            'url' => (string) config('nadorcare.apps.pro_url'),
        ], $user->locale ?: 'fr'));

        $professional->invited_at = now();
        $professional->save();

        $this->audit->record('team.member_invited', $professional, $actor);

        return $professional;
    }

    /**
     * L'agence dépose un justificatif à la place du soignant. Déposé par un administrateur, il
     * est approuvé d'emblée : c'est lui qui contrôle les justificatifs. Déposé par un
     * coordinateur, il attend le contrôle de l'administrateur.
     */
    public function depositDocument(Professional $professional, User $actor, string $type, string $contents, string $mime, ?string $expiresAt): ProfessionalDocument
    {
        return DB::transaction(function () use ($professional, $actor, $type, $contents, $mime, $expiresAt) {
            $document = $this->file->uploadDocument($professional, $type, $contents, $mime, $expiresAt, $actor);

            $this->audit->record('team.document_deposited', $document, $actor, null, ['type' => $type]);

            if ($actor->can(Permission::ProfessionalsVerify->value)) {
                $document = $this->review->approveDocument($document, $actor);
            }

            return $document;
        });
    }

    /**
     * L'agence envoie le dossier à la vérification, quand elle a réuni tous les justificatifs.
     */
    public function submitFile(Professional $professional, User $actor): Professional
    {
        $submitted = $this->file->submit($professional);

        $this->audit->record('team.file_submitted', $submitted, $actor);

        return $submitted;
    }

    private function category(string $id): ProfessionalCategory
    {
        $category = ProfessionalCategory::query()->where('is_active', true)->find($id);

        if (! $category) {
            throw new ApiException('professional_category_unavailable');
        }

        return $category;
    }
}
