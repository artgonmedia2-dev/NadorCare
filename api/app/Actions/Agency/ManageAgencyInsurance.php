<?php

namespace App\Actions\Agency;

use App\Models\AgencyInsurance;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Services\Files\EncryptedFileStore;
use Illuminate\Support\Facades\DB;

/**
 * Assurance de l'agence (modèle « agence », règle n° 8 du 2026-11-23) : l'administrateur
 * enregistre le contrat de Nador Care, son échéance et son attestation.
 */
class ManageAgencyInsurance
{
    public function __construct(
        private readonly EncryptedFileStore $files,
        private readonly AuditLogger $audit,
    ) {}

    /**
     * Enregistre un contrat, ou met à jour celui qui est donné. L'attestation, si elle est
     * fournie, remplace la précédente.
     *
     * @param  array{insurer: string, policy_number: string, expires_on: string}  $data
     * @param  array{contents: string, mime: string}|null  $attestation
     */
    public function save(?AgencyInsurance $insurance, User $actor, array $data, ?array $attestation = null): AgencyInsurance
    {
        return DB::transaction(function () use ($insurance, $actor, $data, $attestation) {
            $created = $insurance === null;
            $insurance ??= new AgencyInsurance;

            $insurance->fill([
                'insurer' => trim($data['insurer']),
                'policy_number' => trim($data['policy_number']),
                'expires_on' => $data['expires_on'],
            ]);

            if ($created) {
                $insurance->created_by = $actor->getKey();
            }
            $insurance->save();

            if ($attestation !== null) {
                $previous = $insurance->file()->first();
                $file = $this->files->store($attestation['contents'], 'agency_insurance', $attestation['mime'], $insurance, $actor);
                $insurance->file_id = $file->id;
                $insurance->save();

                if ($previous) {
                    $this->files->delete($previous);
                }
            }

            $this->audit->record($created ? 'agency_insurance.created' : 'agency_insurance.updated', $insurance, $actor, null, [
                'expires_on' => $insurance->expires_on->format('Y-m-d'),
            ]);

            return $insurance;
        });
    }
}
