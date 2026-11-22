<?php

namespace Tests\Feature\Interventions;

use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Events\ProfessionalLocationUpdated;
use App\Models\AccessLog;
use App\Models\Booking;
use App\Models\Intervention;
use App\Models\InterventionReport;
use App\Models\Professional;
use Illuminate\Database\QueryException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

/**
 * Parcours critique « compte rendu » : départ, trajet, arrivée, rédaction, clôture, avenant.
 */
class InterventionFlowTest extends TestCase
{
    use CreatesAssignmentData;

    private Professional $samira;

    private Booking $mission;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        $this->setUpAssignmentData();

        $this->samira = $this->createProfessional(['name' => 'Samira']);
        $this->mission = $this->createBooking(BookingStatus::Assigned, '2026-12-08 10:00', $this->samira);
        Sanctum::actingAs($this->samira->user, ['app:pro']);
    }

    private function url(string $suffix = ''): string
    {
        return "/api/v1/pro/missions/{$this->mission->id}$suffix";
    }

    private function signature()
    {
        return $this->post($this->url('/report/signature'), [
            'file' => UploadedFile::fake()->image('signature.png', 400, 200),
            'signed_by_name' => 'Aïcha Benali',
        ], ['Accept' => 'application/json']);
    }

    /**
     * Amène la mission jusqu'à un compte rendu prêt à être validé.
     */
    private function reachReadyReport(): void
    {
        $this->postJson($this->url('/depart'))->assertOk();
        $this->postJson($this->url('/arrive'))->assertCreated();
        $this->putJson($this->url('/report'), [
            'vitals' => ['systolic' => 135, 'diastolic' => 85, 'pulse' => 72],
            'observations' => 'Pansement refait, plaie propre, pas de signe d\'infection.',
        ])->assertOk();
        $this->signature()->assertOk();
    }

    // --- Départ et trajet ---

    public function test_the_professional_departs_and_the_patient_sees_who_is_coming(): void
    {
        $this->postJson($this->url('/depart'))->assertOk()->assertJsonPath('data.status', 'en_route');

        $this->assertSame(BookingStatus::EnRoute, $this->mission->fresh()->status);

        Sanctum::actingAs($this->mission->user, ['app:patient']);
        $this->getJson("/api/v1/bookings/{$this->mission->id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'en_route')
            ->assertJsonPath('data.professional.name', 'Samira')
            ->assertJsonPath('data.professional.profession', 'Infirmier')
            // Pas encore de position envoyée.
            ->assertJsonPath('data.tracking', null);
    }

    public function test_the_position_is_shared_only_during_the_journey(): void
    {
        Event::fake([ProfessionalLocationUpdated::class]);
        $position = ['latitude' => 35.1760, 'longitude' => -2.9200, 'accuracy' => 12];

        // Avant le départ : refusé.
        $this->postJson($this->url('/location'), $position)->assertStatus(409)->assertJsonPath('code', 'location_not_expected');

        $this->postJson($this->url('/depart'));
        $eta = $this->postJson($this->url('/location'), $position)->assertOk()->json('data.eta_seconds');
        $this->assertGreaterThan(60, $eta);
        $this->assertLessThan(900, $eta);

        $this->assertSame(1, DB::table('location_pings')->where('booking_id', $this->mission->id)->count());
        Event::assertDispatched(ProfessionalLocationUpdated::class, fn (ProfessionalLocationUpdated $event) => $event->bookingId === $this->mission->id
            && $event->latitude === 35.1760 && $event->etaSeconds === $eta);

        // Le patient voit la position et l'heure d'arrivée estimée.
        Sanctum::actingAs($this->mission->user, ['app:patient']);
        $this->getJson("/api/v1/bookings/{$this->mission->id}")
            ->assertJsonPath('data.tracking.latitude', 35.176)
            ->assertJsonPath('data.tracking.eta_minutes', (int) ceil($eta / 60));

        // Une fois arrivé : plus de suivi, et l'envoi de position est de nouveau refusé.
        Sanctum::actingAs($this->samira->user, ['app:pro']);
        $this->postJson($this->url('/arrive'))->assertCreated();
        $this->postJson($this->url('/location'), $position)->assertStatus(409);

        Sanctum::actingAs($this->mission->user, ['app:patient']);
        $this->getJson("/api/v1/bookings/{$this->mission->id}")->assertJsonPath('data.tracking', null);
    }

    public function test_an_old_position_is_not_shown_to_the_patient(): void
    {
        $this->postJson($this->url('/depart'));
        $this->postJson($this->url('/location'), ['latitude' => 35.1760, 'longitude' => -2.9200])->assertOk();

        $this->travel(11)->minutes();

        Sanctum::actingAs($this->mission->user, ['app:patient']);
        $this->getJson("/api/v1/bookings/{$this->mission->id}")->assertJsonPath('data.tracking', null);
    }

    // --- Arrivée et compte rendu ---

    public function test_arrival_opens_the_intervention_with_a_draft_report(): void
    {
        // On n'arrive pas sans être parti.
        $this->postJson($this->url('/arrive'))->assertStatus(409)->assertJsonPath('code', 'transition_not_allowed');
        $this->putJson($this->url('/report'), ['observations' => 'trop tôt'])->assertStatus(409)->assertJsonPath('code', 'intervention_not_started');

        $this->postJson($this->url('/depart'));
        $this->postJson($this->url('/arrive'), ['latitude' => 35.1688, 'longitude' => -2.9335])
            ->assertCreated()
            ->assertJsonPath('data.status', 'in_progress')
            ->assertJsonPath('data.report.version', 1)
            ->assertJsonPath('data.report.validated_at', null)
            ->assertJsonPath('data.report.is_signed', false);

        $this->assertSame(BookingStatus::InProgress, $this->mission->fresh()->status);
        $intervention = Intervention::query()->sole();
        $this->assertNotNull($intervention->arrived_at);
        $this->assertNotNull(DB::table('interventions')->where('id', $intervention->id)->value('arrival_location'));
    }

    public function test_the_report_is_saved_as_a_draft_encrypted_and_logged(): void
    {
        $this->postJson($this->url('/depart'));
        $this->postJson($this->url('/arrive'));
        $actId = (string) Str::ulid();
        DB::table('acts')->insert(['id' => $actId, 'name' => json_encode(['fr' => 'Réfection de pansement']), 'created_at' => now(), 'updated_at' => now()]);

        $this->putJson($this->url('/report'), [
            'vitals' => ['systolic' => 135, 'diastolic' => 85, 'pulse' => 72, 'temperature' => 37.2, 'glucose' => 1.1, 'spo2' => 98],
            'observations' => 'Pansement refait, plaie propre.',
            'acts' => [['act_id' => $actId, 'label' => 'Réfection de pansement', 'quantity' => 1], ['label' => 'Prise de tension']],
            'consumables' => [['label' => 'Compresses stériles', 'quantity' => 4]],
        ])
            ->assertOk()
            ->assertJsonPath('data.report.vitals.systolic', 135)
            ->assertJsonPath('data.report.vitals.temperature', 37.2)
            ->assertJsonPath('data.report.observations', 'Pansement refait, plaie propre.')
            ->assertJsonPath('data.acts.0.label', 'Réfection de pansement')
            ->assertJsonPath('data.acts.1.act_id', null)
            ->assertJsonPath('data.consumables.0.quantity', 4);

        // Un nouvel enregistrement remplace les listes et garde ce qui n'est pas renvoyé.
        $this->putJson($this->url('/report'), ['acts' => [['label' => 'Injection']]])
            ->assertOk()
            ->assertJsonCount(1, 'data.acts')
            ->assertJsonPath('data.report.observations', 'Pansement refait, plaie propre.')
            ->assertJsonCount(1, 'data.consumables');

        $raw = DB::table('intervention_reports')->first();
        $this->assertStringNotContainsString('Pansement', $raw->observations);
        $this->assertStringNotContainsString('135', $raw->vitals);

        $this->assertSame(2, AccessLog::query()->where('action', AccessAction::Update->value)->where('booking_id', $this->mission->id)->count());
    }

    public function test_implausible_vitals_are_refused(): void
    {
        $this->postJson($this->url('/depart'));
        $this->postJson($this->url('/arrive'));

        $this->putJson($this->url('/report'), ['vitals' => ['systolic' => 1350, 'temperature' => 372, 'spo2' => 140, 'pulse' => 'vite']])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['vitals.systolic', 'vitals.temperature', 'vitals.spo2', 'vitals.pulse']);

        // Une constante inconnue est ignorée, pas enregistrée.
        $this->putJson($this->url('/report'), ['vitals' => ['pulse' => 70, 'poids' => 80]])
            ->assertOk()
            ->assertJsonPath('data.report.vitals', ['pulse' => 70]);
    }

    public function test_photos_and_signature_are_stored_encrypted(): void
    {
        $this->postJson($this->url('/depart'));
        $this->postJson($this->url('/arrive'));

        $this->post($this->url('/report/photos'), ['file' => UploadedFile::fake()->image('plaie.jpg')], ['Accept' => 'application/json'])
            ->assertCreated()->assertJsonPath('data.report.photos_count', 1);
        $this->post($this->url('/report/photos'), ['file' => UploadedFile::fake()->create('note.pdf', 10)], ['Accept' => 'application/json'])
            ->assertStatus(422)->assertJsonValidationErrors('file');

        $this->signature()->assertOk()->assertJsonPath('data.report.is_signed', true)->assertJsonPath('data.report.signed_by_name', 'Aïcha Benali');
        // Refaire signer remplace la signature précédente.
        $this->signature()->assertOk();

        $this->assertSame(1, DB::table('files')->where('category', 'signature')->count());
        $this->assertSame(1, DB::table('files')->where('category', 'report_photo')->count());
        foreach (DB::table('files')->pluck('path') as $path) {
            $this->assertStringNotContainsString('PNG', (string) Storage::disk('local')->get($path));
        }
    }

    public function test_the_number_of_photos_is_capped(): void
    {
        config(['nadorcare.limits.report_photos' => 1]);
        $this->postJson($this->url('/depart'));
        $this->postJson($this->url('/arrive'));

        $this->post($this->url('/report/photos'), ['file' => UploadedFile::fake()->image('a.jpg')], ['Accept' => 'application/json'])->assertCreated();
        $this->post($this->url('/report/photos'), ['file' => UploadedFile::fake()->image('b.jpg')], ['Accept' => 'application/json'])
            ->assertStatus(422)->assertJsonPath('code', 'report_photo_limit_reached');
    }

    // --- Clôture ---

    public function test_the_intervention_cannot_be_completed_without_observations_and_signature(): void
    {
        $this->postJson($this->url('/depart'));
        $this->postJson($this->url('/arrive'));

        $this->postJson($this->url('/complete'), ['cash_collected' => true])
            ->assertStatus(422)->assertJsonPath('code', 'report_observations_required');

        $this->putJson($this->url('/report'), ['observations' => 'Soin réalisé sans difficulté.']);
        $this->postJson($this->url('/complete'), ['cash_collected' => true])
            ->assertStatus(422)->assertJsonPath('code', 'report_signature_required');

        $this->postJson($this->url('/complete'), [])->assertStatus(422)->assertJsonValidationErrors('cash_collected');
        $this->assertSame(BookingStatus::InProgress, $this->mission->fresh()->status);
    }

    public function test_completing_validates_the_report_records_the_cash_and_closes_the_booking(): void
    {
        $this->reachReadyReport();

        $this->postJson($this->url('/complete'), ['cash_collected' => true, 'latitude' => 35.1688, 'longitude' => -2.9335])
            ->assertOk()
            ->assertJsonPath('data.status', 'validated')
            ->assertJsonPath('data.report.version', 1)
            ->assertJsonPath('data.versions.0.version', 1);

        $this->assertSame(BookingStatus::Completed, $this->mission->fresh()->status);

        $report = InterventionReport::query()->sole();
        $this->assertNotNull($report->validated_at);
        $this->assertSame(64, strlen((string) $report->content_hash));
        $this->assertNotNull(Intervention::query()->sole()->ended_at);

        $payment = DB::table('payments')->where('booking_id', $this->mission->id)->sole();
        $this->assertSame('cash', $payment->method);
        $this->assertSame('paid', $payment->status);
        $this->assertSame(10000, $payment->amount);
        $this->assertSame($this->samira->id, $payment->collected_by);

        $this->assertSame(
            ['en_route', 'in_progress', 'completed'],
            $this->mission->statusHistory()->get()->map(fn ($row) => $row->to_status->value)->all(),
        );
    }

    public function test_cash_not_collected_is_recorded_as_pending(): void
    {
        $this->reachReadyReport();

        $this->postJson($this->url('/complete'), ['cash_collected' => false])->assertOk();

        $payment = DB::table('payments')->where('booking_id', $this->mission->id)->sole();
        $this->assertSame('pending', $payment->status);
        $this->assertNull($payment->collected_by);
        $this->assertNull($payment->paid_at);
    }

    public function test_a_validated_report_can_no_longer_be_edited(): void
    {
        $this->reachReadyReport();
        $this->postJson($this->url('/complete'), ['cash_collected' => true])->assertOk();
        $report = InterventionReport::query()->sole();

        // Par l'API : la mission est terminée, elle n'est plus accessible.
        $this->putJson($this->url('/report'), ['observations' => 'Réécriture'])->assertNotFound();
        $this->getJson('/api/v1/pro/missions')->assertJsonCount(0, 'data');

        // Par la base elle-même : la modification est refusée.
        try {
            DB::transaction(fn () => DB::table('intervention_reports')->where('id', $report->id)->update(['observations' => encrypt('Falsifié')]));
            $this->fail('Un compte rendu validé a pu être modifié.');
        } catch (QueryException $e) {
            $this->assertStringContainsString('avenant', $e->getMessage());
        }

        $this->assertSame('Pansement refait, plaie propre, pas de signe d\'infection.', $report->fresh()->observations);
    }

    // --- Avenant ---

    public function test_a_correction_creates_a_traced_amendment_and_keeps_the_original(): void
    {
        $this->reachReadyReport();
        $this->postJson($this->url('/complete'), ['cash_collected' => true]);
        $intervention = Intervention::query()->sole();

        $this->postJson("/api/v1/pro/interventions/{$intervention->id}/amendments", ['observations' => 'Correction'])
            ->assertStatus(422)->assertJsonValidationErrors('reason');

        $this->postJson("/api/v1/pro/interventions/{$intervention->id}/amendments", [
            'reason' => 'Erreur de saisie sur la tension',
            'observations' => 'Pansement refait, plaie propre. Tension recontrôlée.',
            'vitals' => ['systolic' => 125, 'diastolic' => 80],
        ])
            ->assertCreated()
            ->assertJsonPath('data.report.version', 2)
            ->assertJsonPath('data.report.amendment_reason', 'Erreur de saisie sur la tension')
            ->assertJsonPath('data.report.vitals.systolic', 125)
            ->assertJsonCount(2, 'data.versions');

        $versions = InterventionReport::query()->orderBy('version')->get();
        $this->assertSame([1, 2], $versions->pluck('version')->all());
        $this->assertSame(135, $versions[0]->vitals['systolic'], 'l\'original n\'a pas changé');
        $this->assertSame($versions[0]->id, $versions[1]->parent_report_id);
        $this->assertSame($this->samira->user_id, $versions[1]->author_id);
        $this->assertNotNull($versions[1]->validated_at);
        $this->assertNotSame($versions[0]->content_hash, $versions[1]->content_hash);
    }

    public function test_only_the_author_amends_and_only_a_validated_report(): void
    {
        $this->postJson($this->url('/depart'));
        $this->postJson($this->url('/arrive'));
        $intervention = Intervention::query()->sole();
        $payload = ['reason' => 'Correction demandée', 'observations' => 'Texte corrigé'];

        // Pas encore validé : pas d'avenant.
        $this->postJson("/api/v1/pro/interventions/{$intervention->id}/amendments", $payload)
            ->assertStatus(409)->assertJsonPath('code', 'report_not_validated');

        // Un autre professionnel ne voit pas cette intervention.
        Sanctum::actingAs($this->createProfessional()->user, ['app:pro']);
        $this->postJson("/api/v1/pro/interventions/{$intervention->id}/amendments", $payload)->assertNotFound();
        $this->getJson($this->url('/intervention'))->assertNotFound();
    }

    // --- Côté patient ---

    public function test_the_patient_reads_the_report_once_the_care_is_done(): void
    {
        $this->reachReadyReport();

        Sanctum::actingAs($this->mission->user, ['app:patient']);
        $this->getJson("/api/v1/bookings/{$this->mission->id}/report")->assertNotFound()->assertJsonPath('code', 'report_not_available');
        $this->getJson("/api/v1/bookings/{$this->mission->id}")->assertJsonPath('data.has_report', false);

        Sanctum::actingAs($this->samira->user, ['app:pro']);
        $this->postJson($this->url('/complete'), ['cash_collected' => true]);
        $intervention = Intervention::query()->sole();
        $this->postJson("/api/v1/pro/interventions/{$intervention->id}/amendments", [
            'reason' => 'Précision ajoutée', 'observations' => 'Pansement refait. Prochain passage dans 48 h.',
        ])->assertCreated();

        Sanctum::actingAs($this->mission->user, ['app:patient']);
        $this->getJson("/api/v1/bookings/{$this->mission->id}")
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.has_report', true);

        // Le patient lit la version qui fait foi, et voit qu'elle a été corrigée.
        $this->getJson("/api/v1/bookings/{$this->mission->id}/report")
            ->assertOk()
            ->assertJsonPath('data.report.version', 2)
            ->assertJsonPath('data.report.observations', 'Pansement refait. Prochain passage dans 48 h.')
            ->assertJsonPath('data.report.vitals.systolic', 135)
            ->assertJsonPath('data.report.signed_by_name', 'Aïcha Benali')
            ->assertJsonCount(2, 'data.versions');

        $log = AccessLog::query()->where('actor_id', $this->mission->user_id)->where('subject_type', Intervention::class)->sole();
        $this->assertSame(AccessAction::View, $log->action);

        // Le compte rendu d'un autre compte reste invisible.
        Sanctum::actingAs($this->userWithRole(Role::Patient), ['app:patient']);
        $this->getJson("/api/v1/bookings/{$this->mission->id}/report")->assertNotFound();
    }

    public function test_actions_and_consumables_are_offered_for_the_service(): void
    {
        $actId = (string) Str::ulid();
        $otherAct = (string) Str::ulid();
        DB::table('acts')->insert([
            ['id' => $actId, 'name' => json_encode(['fr' => 'Réfection de pansement', 'ar' => 'تغيير الضمادة']), 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['id' => $otherAct, 'name' => json_encode(['fr' => 'Acte d\'un autre service']), 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ]);
        DB::table('service_act')->insert(['service_id' => $this->nursingService->id, 'act_id' => $actId]);
        DB::table('consumables')->insert(['id' => (string) Str::ulid(), 'name' => json_encode(['fr' => 'Compresses stériles']), 'unit' => 'pièce', 'is_active' => true, 'created_at' => now(), 'updated_at' => now()]);

        $this->getJson($this->url('/reference'))
            ->assertOk()
            ->assertJsonCount(1, 'data.acts')
            ->assertJsonPath('data.acts.0.name', 'Réfection de pansement')
            ->assertJsonPath('data.consumables.0.name', 'Compresses stériles')
            ->assertJsonPath('data.consumables.0.unit', 'pièce');

        $this->getJson($this->url('/reference'), ['Accept-Language' => 'ar'])->assertJsonPath('data.acts.0.name', 'تغيير الضمادة');
    }
}
