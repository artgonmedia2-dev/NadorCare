<?php

namespace Tests\Feature\Professionals;

use App\Actions\Professionals\ReviewProfessional;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Enums\VerificationStatus;
use App\Exceptions\ApiException;
use App\Filament\Resources\Professionals\Pages\ListProfessionals;
use App\Filament\Resources\Professionals\Pages\ViewProfessional;
use App\Filament\Resources\Professionals\RelationManagers\DocumentsRelationManager;
use App\Models\AccessLog;
use App\Models\AuditLog;
use App\Models\Professional;
use App\Models\ProfessionalCategory;
use App\Models\ProfessionalDocument;
use App\Models\User;
use App\Services\Assignment\ProfessionalMatcher;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Livewire\Livewire;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

class ProfessionalFileTest extends TestCase
{
    use CreatesAssignmentData;

    private const NURSE_DOCUMENTS = ['identity', 'diploma', 'practice_authorization', 'rc_insurance'];

    private User $nurse;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        $this->setUpAssignmentData();
        $this->nurses->update(['code' => 'nurse', 'required_document_types' => self::NURSE_DOCUMENTS]);

        $this->nurse = $this->userWithRole(Role::Professionnel, ['name' => 'Samira El Idrissi']);
        $this->admin = $this->userWithRole(Role::Administrateur);
        Sanctum::actingAs($this->nurse, ['app:pro']);
    }

    private function upload(string $type, array $extra = [], string $content = '%PDF-1.4 justificatif')
    {
        return $this->post('/api/v1/pro/profile/documents', [
            'type' => $type,
            'file' => UploadedFile::fake()->createWithContent("$type.pdf", $content),
            ...$extra,
        ], ['Accept' => 'application/json']);
    }

    /**
     * Dossier complet : profession choisie et tous les justificatifs déposés.
     */
    private function completeFile(): Professional
    {
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id, 'license_number' => 'AE-2020-114'])->assertOk();
        foreach (['identity', 'diploma', 'practice_authorization'] as $type) {
            $this->upload($type)->assertCreated();
        }
        $this->upload('rc_insurance', ['expires_at' => '2027-06-30'])->assertCreated();

        return $this->nurse->professional()->firstOrFail();
    }

    private function approveAll(Professional $professional): void
    {
        foreach ($professional->documents()->where('status', 'pending')->get() as $document) {
            app(ReviewProfessional::class)->approveDocument($document, $this->admin);
        }
    }

    private function actingAsStaff(Role $role): User
    {
        $this->flushSession();
        $staff = User::factory()->staff($role)->create();
        $staff->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($staff, 'web');

        return $staff;
    }

    // --- Inscription ---

    public function test_professions_and_their_required_documents_are_public(): void
    {
        ProfessionalCategory::factory()->create(['is_active' => false]);

        $this->getJson('/api/v1/catalogue/professional-categories')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Infirmier')
            ->assertJsonPath('data.0.required_documents', self::NURSE_DOCUMENTS);

        $this->getJson('/api/v1/catalogue/zones')->assertOk()->assertJsonPath('data.0.name', 'Nador centre');
    }

    public function test_a_professional_starts_with_no_file_then_creates_a_draft(): void
    {
        $this->getJson('/api/v1/pro/profile')->assertForbidden()->assertJsonPath('code', 'professional_profile_required');

        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id, 'license_number' => 'AE-2020-114'])
            ->assertOk()
            ->assertJsonPath('data.verification_status', 'draft')
            ->assertJsonPath('data.category.name', 'Infirmier')
            ->assertJsonPath('data.license_number', 'AE-2020-114')
            ->assertJsonPath('data.required_documents', self::NURSE_DOCUMENTS)
            ->assertJsonPath('data.missing_documents', self::NURSE_DOCUMENTS)
            ->assertJsonPath('data.can_submit', false)
            ->assertJsonPath('data.is_online', false);

        // Un brouillon ne reçoit aucune mission.
        $this->assertCount(0, app(ProfessionalMatcher::class)->candidatesFor($this->createBooking()));
    }

    public function test_an_unknown_or_closed_profession_is_refused(): void
    {
        $closed = ProfessionalCategory::factory()->create(['is_active' => false]);

        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $closed->id])
            ->assertStatus(422)->assertJsonPath('code', 'professional_category_unavailable');
        $this->assertSame(0, Professional::query()->count());
    }

    // --- Justificatifs ---

    public function test_documents_are_stored_encrypted_and_tracked_one_by_one(): void
    {
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id]);

        $this->upload('diploma', content: '%PDF-1.4 Diplôme d\'État d\'infirmier')
            ->assertCreated()
            ->assertJsonPath('data.documents.0.type', 'diploma')
            ->assertJsonPath('data.documents.0.status', 'pending')
            ->assertJsonPath('data.missing_documents', ['identity', 'practice_authorization', 'rc_insurance']);

        $path = DB::table('files')->where('category', 'professional_document')->value('path');
        $this->assertStringNotContainsString('Diplôme', Storage::disk('local')->get($path));
    }

    public function test_the_insurance_requires_a_future_expiry_date(): void
    {
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id]);

        $this->upload('rc_insurance')->assertStatus(422)->assertJsonPath('code', 'document_expiry_required');
        $this->upload('rc_insurance', ['expires_at' => '2026-12-01'])->assertStatus(422)->assertJsonValidationErrors('expires_at');
        $this->upload('rc_insurance', ['expires_at' => '2027-06-30'])
            ->assertCreated()
            ->assertJsonPath('data.documents.0.expires_at', '2027-06-30');
    }

    public function test_only_documents_required_for_the_profession_are_accepted(): void
    {
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id]);

        // Les infirmiers n'ont pas d'Ordre.
        $this->upload('order_registration')->assertStatus(422)->assertJsonPath('code', 'document_type_not_expected');
        $this->upload('selfie')->assertStatus(422)->assertJsonValidationErrors('type');
        $this->post('/api/v1/pro/profile/documents', ['type' => 'diploma', 'file' => UploadedFile::fake()->create('virus.exe', 5)], ['Accept' => 'application/json'])
            ->assertStatus(422)->assertJsonValidationErrors('file');
    }

    public function test_a_new_upload_replaces_the_one_not_yet_checked(): void
    {
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id]);
        $this->upload('diploma', content: 'première version');
        $this->upload('diploma', content: 'version lisible')->assertCreated()->assertJsonCount(1, 'data.documents');

        $this->assertSame(1, ProfessionalDocument::query()->count());
        $this->assertSame(1, DB::table('files')->count());
    }

    // --- Soumission ---

    public function test_an_incomplete_file_cannot_be_submitted(): void
    {
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id]);
        $this->upload('identity');

        $this->postJson('/api/v1/pro/profile/submit')
            ->assertStatus(422)
            ->assertJsonPath('code', 'documents_missing')
            ->assertJsonPath('missing_documents', ['diploma', 'practice_authorization', 'rc_insurance']);
    }

    public function test_a_complete_file_is_submitted_and_then_locked(): void
    {
        $this->completeFile();

        $this->getJson('/api/v1/pro/profile')->assertJsonPath('data.can_submit', true)->assertJsonPath('data.missing_documents', []);
        $this->postJson('/api/v1/pro/profile/submit')->assertOk()->assertJsonPath('data.verification_status', 'submitted');

        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id])
            ->assertStatus(409)->assertJsonPath('code', 'professional_file_locked');
        $this->postJson('/api/v1/pro/profile/submit')->assertStatus(409);

        // Soumis, mais pas vérifié : toujours aucune mission.
        $this->assertCount(0, app(ProfessionalMatcher::class)->candidatesFor($this->createBooking()));
    }

    // --- Vérification ---

    public function test_the_file_is_validated_only_once_every_required_document_is_approved(): void
    {
        $professional = $this->completeFile();
        $this->postJson('/api/v1/pro/profile/submit');
        $review = app(ReviewProfessional::class);

        try {
            $review->verify($professional->fresh(), $this->admin);
            $this->fail('Le dossier a été validé avec des justificatifs non approuvés.');
        } catch (ApiException $e) {
            $this->assertSame('documents_not_approved', $e->errorCode);
            $this->assertEqualsCanonicalizing(self::NURSE_DOCUMENTS, $e->data['missing_documents']);
        }

        $this->approveAll($professional);
        $review->verify($professional->fresh(), $this->admin);

        $professional->refresh();
        $this->assertSame(VerificationStatus::Verified, $professional->verification_status);
        $this->assertSame($this->admin->id, $professional->getAttribute('verified_by'));

        // Historique des contrôles et journal des actions sensibles.
        $this->assertSame(4, DB::table('document_reviews')->where('reviewer_id', $this->admin->id)->where('decision', 'approved')->count());
        $this->assertSame(4, AuditLog::query()->where('event', 'professional_document.approved')->count());
        $verified = AuditLog::query()->where('event', 'professional.verified')->sole();
        $this->assertSame($this->admin->id, $verified->actor_id);
        $this->assertEquals(['status' => 'verified', 'reason' => null], $verified->new_values);

        $this->getJson('/api/v1/pro/profile')->assertJsonPath('data.verification_status', 'verified');
    }

    public function test_a_verified_professional_with_zones_and_schedule_becomes_a_candidate(): void
    {
        $professional = $this->completeFile();
        $this->postJson('/api/v1/pro/profile/submit');
        $this->approveAll($professional);
        app(ReviewProfessional::class)->verify($professional->fresh(), $this->admin);

        $this->putJson('/api/v1/pro/profile/zones', ['zone_ids' => [$this->zoneId]])
            ->assertOk()->assertJsonPath('data.zones.0.name', 'Nador centre');
        $this->putJson('/api/v1/pro/profile/availabilities', ['availabilities' => [
            ['weekday' => 2, 'start_time' => '08:00', 'end_time' => '12:00'],
            ['weekday' => 2, 'start_time' => '14:00', 'end_time' => '18:00'],
        ]])->assertOk()->assertJsonCount(2, 'data.availabilities')->assertJsonPath('data.availabilities.0.start_time', '08:00');
        $this->putJson('/api/v1/pro/profile/online', ['is_online' => true])->assertOk()->assertJsonPath('data.is_online', true);

        // Mardi 8 décembre à 10 h : dans la plage du matin.
        $candidate = app(ProfessionalMatcher::class)->candidatesFor($this->createBooking())->sole();
        $this->assertSame('Samira El Idrissi', $candidate->professional->user->name);
        $this->assertTrue($candidate->coversZone);
        $this->assertTrue($candidate->available);

        // À 13 h, entre ses deux plages : candidate, mais signalée hors agenda.
        $lunch = app(ProfessionalMatcher::class)->candidatesFor($this->createBooking(BookingStatus::Confirmed, '2026-12-08 13:00'))->sole();
        $this->assertFalse($lunch->available);
    }

    public function test_a_rejected_document_is_explained_and_kept_in_the_history(): void
    {
        $professional = $this->completeFile();
        $this->postJson('/api/v1/pro/profile/submit');
        $diploma = $professional->documents()->where('type', 'diploma')->sole();

        app(ReviewProfessional::class)->rejectDocument($diploma, $this->admin, 'Photo illisible');
        app(ReviewProfessional::class)->reject($professional->fresh(), $this->admin, 'Diplôme à renvoyer');

        $this->getJson('/api/v1/pro/profile')
            ->assertJsonPath('data.verification_status', 'rejected')
            ->assertJsonPath('data.status_reason', 'Diplôme à renvoyer')
            ->assertJsonPath('data.missing_documents', ['diploma'])
            ->assertJsonPath('data.can_submit', false);

        // Le professionnel corrige et soumet de nouveau.
        $this->upload('diploma', content: 'version lisible')->assertCreated();
        $this->postJson('/api/v1/pro/profile/submit')->assertOk()->assertJsonPath('data.verification_status', 'submitted')->assertJsonPath('data.status_reason', null);

        // Le justificatif refusé reste dans le dossier, avec son contrôle.
        $this->assertSame(['rejected', 'pending'], $professional->documents()->where('type', 'diploma')->orderBy('id')->pluck('status')->all());
        $this->assertSame('Photo illisible', DB::table('document_reviews')->where('professional_document_id', $diploma->id)->value('comment'));
    }

    public function test_an_expired_document_cannot_be_approved(): void
    {
        $professional = $this->completeFile();
        $insurance = $professional->documents()->where('type', 'rc_insurance')->sole();
        $this->travelTo('2027-07-01 10:00');

        $this->expectException(ApiException::class);
        $this->expectExceptionMessage('document_expired');
        app(ReviewProfessional::class)->approveDocument($insurance, $this->admin);
    }

    public function test_a_renewed_insurance_replaces_the_previous_one_once_approved(): void
    {
        $professional = $this->completeFile();
        $this->postJson('/api/v1/pro/profile/submit');
        $this->approveAll($professional);
        app(ReviewProfessional::class)->verify($professional->fresh(), $this->admin);

        // Renouvellement : l'ancienne assurance reste valable tant que la nouvelle n'est pas contrôlée.
        $this->upload('rc_insurance', ['expires_at' => '2028-06-30'])->assertCreated();
        $this->assertSame(['approved', 'pending'], $professional->documents()->where('type', 'rc_insurance')->orderBy('id')->pluck('status')->all());

        $renewal = $professional->documents()->where('type', 'rc_insurance')->where('status', 'pending')->sole();
        app(ReviewProfessional::class)->approveDocument($renewal, $this->admin);

        $this->assertSame(['expired', 'approved'], $professional->documents()->where('type', 'rc_insurance')->orderBy('id')->pluck('status')->all());
    }

    public function test_expired_insurance_is_flagged_every_night(): void
    {
        $professional = $this->completeFile();
        $this->approveAll($professional);

        $this->travelTo('2027-06-30 03:00');
        $this->artisan('nadorcare:expire-documents')->assertSuccessful();
        $this->assertSame('approved', $professional->documents()->where('type', 'rc_insurance')->value('status'));

        $this->travelTo('2027-07-01 03:00');
        $this->artisan('nadorcare:expire-documents')->assertSuccessful();
        $this->assertSame('expired', $professional->documents()->where('type', 'rc_insurance')->value('status'));
        // Les justificatifs sans date de validité ne sont pas touchés.
        $this->assertSame('approved', $professional->documents()->where('type', 'diploma')->value('status'));
    }

    public function test_a_suspended_professional_goes_offline_and_receives_no_mission(): void
    {
        $professional = $this->createProfessional(['name' => 'Karima']);
        DB::table('professionals')->where('id', $professional->id)->update(['is_online' => true]);
        $review = app(ReviewProfessional::class);

        $review->suspend($professional->fresh(), $this->admin, 'Plainte en cours d\'examen');

        $professional->refresh();
        $this->assertSame(VerificationStatus::Suspended, $professional->verification_status);
        $this->assertFalse($professional->is_online);
        $this->assertCount(0, app(ProfessionalMatcher::class)->candidatesFor($this->createBooking()));

        Sanctum::actingAs($professional->user, ['app:pro']);
        $this->putJson('/api/v1/pro/profile/online', ['is_online' => true])->assertStatus(409)->assertJsonPath('code', 'professional_not_verified');
        $this->getJson('/api/v1/pro/profile')->assertJsonPath('data.status_reason', 'Plainte en cours d\'examen');

        $review->reinstate($professional->fresh(), $this->admin);
        $this->assertCount(1, app(ProfessionalMatcher::class)->candidatesFor($this->createBooking()));
        $this->assertSame(['professional.suspended', 'professional.reinstated'], AuditLog::query()->orderBy('id')->pluck('event')->all());
    }

    // --- Zones et agenda ---

    public function test_zones_and_schedule_are_validated(): void
    {
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id]);
        $closedZone = $this->createZone();
        DB::table('zones')->where('id', $closedZone)->update(['is_active' => false]);

        $this->putJson('/api/v1/pro/profile/zones', ['zone_ids' => [$this->zoneId, $closedZone]])
            ->assertStatus(422)->assertJsonPath('code', 'zone_unavailable');

        $overlap = [['weekday' => 1, 'start_time' => '08:00', 'end_time' => '12:00'], ['weekday' => 1, 'start_time' => '11:00', 'end_time' => '15:00']];
        $this->putJson('/api/v1/pro/profile/availabilities', ['availabilities' => $overlap])
            ->assertStatus(422)->assertJsonPath('code', 'availability_invalid');
        $this->putJson('/api/v1/pro/profile/availabilities', ['availabilities' => [['weekday' => 1, 'start_time' => '18:00', 'end_time' => '09:00']]])
            ->assertStatus(422)->assertJsonPath('code', 'availability_invalid');
        $this->putJson('/api/v1/pro/profile/availabilities', ['availabilities' => [['weekday' => 9, 'start_time' => '8h', 'end_time' => '12:00']]])
            ->assertStatus(422)->assertJsonValidationErrors(['availabilities.0.weekday', 'availabilities.0.start_time']);

        // Un dossier non vérifié ne peut pas se mettre en ligne.
        $this->putJson('/api/v1/pro/profile/online', ['is_online' => true])->assertStatus(409);

        // Vider l'agenda est permis.
        $this->putJson('/api/v1/pro/profile/availabilities', ['availabilities' => []])->assertOk()->assertJsonCount(0, 'data.availabilities');
    }

    public function test_the_patient_app_has_no_access_to_the_professional_file(): void
    {
        Sanctum::actingAs($this->nurse, ['app:patient']);

        $this->getJson('/api/v1/pro/profile')->assertForbidden();
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id])->assertForbidden();
    }

    // --- Back-office ---

    public function test_the_administrator_checks_documents_and_validates_the_file_in_the_back_office(): void
    {
        $professional = $this->completeFile();
        $this->postJson('/api/v1/pro/profile/submit');
        $staff = $this->actingAsStaff(Role::Administrateur);

        $this->get('/admin/professionals')->assertOk();
        $this->get("/admin/professionals/{$professional->id}")->assertOk()->assertSee('Samira El Idrissi')->assertSee('AE-2020-114');

        Livewire::test(ListProfessionals::class)
            ->assertCanSeeTableRecords([$professional])
            ->filterTable('verification_status', 'verified')
            ->assertCanNotSeeTableRecords([$professional]);

        $documents = Livewire::test(DocumentsRelationManager::class, ['ownerRecord' => $professional, 'pageClass' => ViewProfessional::class]);
        $diploma = $professional->documents()->where('type', 'diploma')->sole();

        // Ouvrir un justificatif le déchiffre, et la lecture est journalisée.
        $documents->callTableAction('download', $diploma)->assertFileDownloaded("diploma-{$diploma->id}.pdf");
        $log = AccessLog::query()->where('subject_id', $diploma->file_id)->sole();
        $this->assertSame($staff->id, $log->actor_id);

        // Valider trop tôt est refusé, avec l'explication.
        Livewire::test(ViewProfessional::class, ['record' => $professional->id])
            ->callAction('verify')
            ->assertNotified(__('api.errors.documents_not_approved'));

        foreach ($professional->documents as $document) {
            $documents->callTableAction('approve', $document)->assertNotified(__('admin.professionals.document_approved'));
        }

        Livewire::test(ViewProfessional::class, ['record' => $professional->id])
            ->callAction('verify')
            ->assertNotified(__('admin.professionals.verified'));

        $this->assertSame(VerificationStatus::Verified, $professional->fresh()->verification_status);

        Livewire::test(ViewProfessional::class, ['record' => $professional->id])
            ->assertActionHidden('verify')
            ->callAction('suspend', data: ['reason' => 'Assurance contestée'])
            ->assertNotified(__('admin.professionals.suspended'));
        $this->assertSame(VerificationStatus::Suspended, $professional->fresh()->verification_status);
    }

    public function test_a_document_is_rejected_with_a_reason_from_the_back_office(): void
    {
        $professional = $this->completeFile();
        $this->actingAsStaff(Role::Administrateur);
        $identity = $professional->documents()->where('type', 'identity')->sole();

        $documents = Livewire::test(DocumentsRelationManager::class, ['ownerRecord' => $professional, 'pageClass' => ViewProfessional::class]);
        $documents->callTableAction('reject', $identity, data: ['reason' => ''])->assertHasTableActionErrors(['reason' => 'required']);
        $documents->callTableAction('reject', $identity, data: ['reason' => 'Pièce expirée'])->assertNotified(__('admin.professionals.document_rejected'));

        $this->assertSame('rejected', $identity->fresh()->status);
        $this->assertSame('Pièce expirée', $identity->fresh()->rejection_reason);
        $documents->assertTableActionHidden('approve', $identity);
    }

    public function test_the_coordinator_consults_files_but_cannot_decide(): void
    {
        $professional = $this->completeFile();
        $this->postJson('/api/v1/pro/profile/submit');
        $this->actingAsStaff(Role::Coordinateur);

        $this->get('/admin/professionals')->assertOk();
        Livewire::test(ViewProfessional::class, ['record' => $professional->id])
            ->assertActionHidden('verify')
            ->assertActionHidden('reject');
        Livewire::test(DocumentsRelationManager::class, ['ownerRecord' => $professional, 'pageClass' => ViewProfessional::class])
            ->assertTableActionHidden('approve', $professional->documents()->first())
            ->assertTableActionHidden('download', $professional->documents()->first());

        $this->actingAsStaff(Role::Comptable);
        $this->get('/admin/professionals')->assertForbidden();
    }

    public function test_files_with_expiring_insurance_are_listed_as_alerts(): void
    {
        $soon = $this->createProfessional(['name' => 'Expire bientôt', 'insurance_expires' => '2026-12-20']);
        $later = $this->createProfessional(['name' => 'Expire plus tard', 'insurance_expires' => '2027-06-30']);
        $this->actingAsStaff(Role::Coordinateur);

        Livewire::test(ListProfessionals::class)
            ->filterTable('insurance_expiring')
            ->assertCanSeeTableRecords([$soon])
            ->assertCanNotSeeTableRecords([$later])
            ->assertSee('20/12/2026');
    }
}
