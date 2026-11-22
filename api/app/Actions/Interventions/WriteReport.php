<?php

namespace App\Actions\Interventions;

use App\Actions\Bookings\TransitionBooking;
use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\File;
use App\Models\Intervention;
use App\Models\InterventionReport;
use App\Models\User;
use App\Services\Files\EncryptedFileStore;
use App\Services\Health\AccessLogger;
use Illuminate\Support\Facades\DB;

/**
 * Compte rendu d'intervention (cahier des charges §5) : constantes, observations, actes,
 * consommables, photos, signature du patient. Une fois validé il n'est plus modifiable ;
 * toute correction crée un avenant tracé.
 */
class WriteReport
{
    public function __construct(
        private readonly EncryptedFileStore $files,
        private readonly AccessLogger $logger,
        private readonly TransitionBooking $transition,
    ) {}

    /**
     * Enregistre le brouillon. Les listes d'actes et de consommables remplacent les précédentes.
     *
     * @param  array{vitals?: array<string, mixed>|null, observations?: string|null, acts?: list<array{act_id?: string|null, label: string, quantity?: int}>, consumables?: list<array{consumable_id?: string|null, label: string, quantity?: float|int}>, client_created_at?: string|null}  $data
     */
    public function saveDraft(Intervention $intervention, User $actor, array $data): InterventionReport
    {
        $report = $this->draftOf($intervention);

        return DB::transaction(function () use ($intervention, $report, $actor, $data) {
            $changes = [];
            foreach (['vitals', 'observations', 'client_created_at'] as $field) {
                if (array_key_exists($field, $data)) {
                    $changes[$field] = $data[$field];
                }
            }
            if (isset($changes['vitals'])) {
                // Seules les constantes renseignées sont gardées.
                $changes['vitals'] = array_filter($changes['vitals'], fn ($value) => $value !== null && $value !== '') ?: null;
            }
            $report->update($changes);

            if (array_key_exists('acts', $data)) {
                DB::table('intervention_acts')->where('intervention_id', $intervention->getKey())->delete();
                foreach ($data['acts'] as $act) {
                    DB::table('intervention_acts')->insert([
                        'id' => (string) str()->ulid(),
                        'intervention_id' => $intervention->getKey(),
                        'act_id' => $act['act_id'] ?? null,
                        'label' => $act['label'],
                        'quantity' => $act['quantity'] ?? 1,
                    ]);
                }
            }

            if (array_key_exists('consumables', $data)) {
                DB::table('intervention_consumables')->where('intervention_id', $intervention->getKey())->delete();
                foreach ($data['consumables'] as $consumable) {
                    DB::table('intervention_consumables')->insert([
                        'id' => (string) str()->ulid(),
                        'intervention_id' => $intervention->getKey(),
                        'consumable_id' => $consumable['consumable_id'] ?? null,
                        'label' => $consumable['label'],
                        'quantity' => $consumable['quantity'] ?? 1,
                    ]);
                }
            }

            $this->log(AccessAction::Update, $report, $intervention, $actor);

            return $report;
        });
    }

    /**
     * Ajoute une photo au compte rendu, chiffrée avant stockage.
     */
    public function addPhoto(Intervention $intervention, User $actor, string $contents, string $mime): File
    {
        $report = $this->draftOf($intervention);

        if ($report->photos()->count() >= (int) config('nadorcare.limits.report_photos')) {
            throw new ApiException('report_photo_limit_reached');
        }

        $file = $this->files->store($contents, 'report_photo', $mime, $report, $actor);
        $this->log(AccessAction::Create, $file, $intervention, $actor);

        return $file;
    }

    /**
     * Enregistre la signature tracée à l'écran et le nom de la personne qui signe
     * (le patient, ou un proche présent s'il ne peut pas signer).
     */
    public function sign(Intervention $intervention, User $actor, string $pngContents, string $signedByName): InterventionReport
    {
        $report = $this->draftOf($intervention);

        return DB::transaction(function () use ($intervention, $report, $actor, $pngContents, $signedByName) {
            $previous = $report->signature_file_id ? File::query()->find($report->signature_file_id) : null;

            $file = $this->files->store($pngContents, 'signature', 'image/png', $report, $actor);
            $report->update(['signature_file_id' => $file->getKey(), 'signed_by_name' => $signedByName, 'signed_at' => now()]);

            if ($previous) {
                $this->files->delete($previous);
            }

            $this->log(AccessAction::Update, $report, $intervention, $actor);

            return $report;
        });
    }

    /**
     * Clôture : pointe la fin, valide le compte rendu (il devient immuable), enregistre
     * l'encaissement en espèces et termine la réservation.
     */
    public function complete(Intervention $intervention, User $actor, bool $cashCollected, ?float $latitude = null, ?float $longitude = null): Booking
    {
        $report = $this->draftOf($intervention);

        if (trim((string) $report->observations) === '') {
            throw new ApiException('report_observations_required');
        }

        if ($report->signature_file_id === null) {
            throw new ApiException('report_signature_required');
        }

        return DB::transaction(function () use ($intervention, $report, $actor, $cashCollected, $latitude, $longitude) {
            $booking = $this->transition->handle($intervention->booking, BookingStatus::Completed, $actor);

            $intervention->update(['ended_at' => now(), 'status' => Intervention::STATUS_VALIDATED]);
            if ($latitude !== null && $longitude !== null) {
                DB::update(
                    'UPDATE interventions SET end_location = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography WHERE id = ?',
                    [$longitude, $latitude, $intervention->getKey()],
                );
            }

            // Dernière écriture permise : après elle, la base refuse toute modification.
            $report->forceFill(['content_hash' => $this->hash($report), 'validated_at' => now()])->save();

            if ($booking->payment_method === 'cash') {
                DB::table('payments')->insert([
                    'id' => (string) str()->ulid(),
                    'booking_id' => $booking->getKey(),
                    'method' => 'cash',
                    'provider' => 'cash',
                    'status' => $cashCollected ? 'paid' : 'pending',
                    'amount' => $booking->total_price,
                    'currency' => 'MAD',
                    'collected_by' => $cashCollected ? $booking->professional_id : null,
                    'paid_at' => $cashCollected ? now() : null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            $this->log(AccessAction::Update, $report, $intervention, $actor);

            return $booking;
        });
    }

    /**
     * Avenant : correction d'un compte rendu validé. L'original reste intact ; l'avenant est
     * une nouvelle version, validée dès sa création, avec le motif de la correction.
     *
     * @param  array<string, mixed>|null  $vitals
     */
    public function amend(Intervention $intervention, User $actor, string $reason, string $observations, ?array $vitals = null): InterventionReport
    {
        $latest = $intervention->reports()->whereNotNull('validated_at')->orderByDesc('version')->first();

        if (! $latest) {
            throw new ApiException('report_not_validated', 409);
        }

        return DB::transaction(function () use ($intervention, $latest, $actor, $reason, $observations, $vitals) {
            $amendment = new InterventionReport([
                'intervention_id' => $intervention->getKey(),
                'version' => $latest->version + 1,
                'parent_report_id' => $latest->getKey(),
                'vitals' => $vitals === null ? $latest->vitals : (array_filter($vitals, fn ($value) => $value !== null && $value !== '') ?: null),
                'observations' => $observations,
                'signature_file_id' => $latest->signature_file_id,
                'signed_by_name' => $latest->signed_by_name,
                'signed_at' => $latest->signed_at,
                'author_id' => $actor->getKey(),
                'amendment_reason' => $reason,
            ]);
            $amendment->content_hash = $this->hash($amendment);
            $amendment->validated_at = now();
            $amendment->save();

            $this->log(AccessAction::Create, $amendment, $intervention, $actor);

            return $amendment;
        });
    }

    /**
     * Brouillon en cours. Refuse si le compte rendu est déjà validé.
     */
    private function draftOf(Intervention $intervention): InterventionReport
    {
        $report = $intervention->reports()->where('version', 1)->first();

        if (! $report || $report->isValidated()) {
            throw new ApiException('report_locked', 409);
        }

        return $report;
    }

    /**
     * Empreinte du contenu, pour prouver plus tard qu'il n'a pas changé.
     */
    private function hash(InterventionReport $report): string
    {
        return hash('sha256', json_encode([
            'intervention_id' => $report->intervention_id,
            'version' => $report->version,
            'vitals' => $report->vitals,
            'observations' => $report->observations,
            'signature_file_id' => $report->signature_file_id,
            'signed_by_name' => $report->signed_by_name,
        ], JSON_THROW_ON_ERROR));
    }

    private function log(AccessAction $action, InterventionReport|File $subject, Intervention $intervention, User $actor): void
    {
        $booking = $intervention->booking;
        $this->logger->record($action, $subject, $booking->patient_profile_id, $booking->getKey(), $actor);
    }
}
