<?php

namespace Tests\Feature\Professionals;

use App\Actions\Professionals\ManageTeam;
use App\Enums\Role;
use App\Enums\VerificationStatus;
use App\Filament\Resources\AgencyInsurances\Pages\ListAgencyInsurances;
use App\Filament\Resources\Professionals\Pages\ListProfessionals;
use App\Filament\Resources\Professionals\Pages\ViewProfessional;
use App\Filament\Resources\Professionals\RelationManagers\DocumentsRelationManager;
use App\Filament\Widgets\DocumentsToRenew;
use App\Models\AgencyInsurance;
use App\Models\AuditLog;
use App\Models\File;
use App\Models\Professional;
use App\Models\ProfessionalDocument;
use App\Models\User;
use App\Services\Assignment\ProfessionalMatcher;
use App\Services\Files\EncryptedFileStore;
use Filament\Actions\CreateAction;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Livewire\Livewire;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

/**
 * Modèle « agence » (décision du 2026-11-23) : l'agence centralise le dossier de ses soignants,
 * dépose leurs justificatifs, suit leur validité, et enregistre sa propre assurance.
 */
class AgencyDocumentsTest extends TestCase
{
    use CreatesAssignmentData;

    private const NURSE_DOCUMENTS = ['identity', 'diploma', 'practice_authorization'];

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        // Lundi 7 décembre 2026, 10 h à Nador.
        $this->setUpAssignmentData();
        $this->nurses->update(['code' => 'nurse', 'required_document_types' => self::NURSE_DOCUMENTS]);
    }

    private function actingAsStaff(Role $role): User
    {
        $this->flushSession();
        $staff = User::factory()->staff($role)->create();
        $staff->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($staff, 'web');

        return $staff;
    }

    private function hire(User $staff): Professional
    {
        return app(ManageTeam::class)->create($staff, [
            'name' => 'Samira El Idrissi', 'phone' => '+212661234567', 'professional_category_id' => $this->nurses->id,
        ]);
    }

    private function pdf(string $name = 'justificatif.pdf'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, "%PDF-1.4\n1 0 obj\n<< >>\nendobj\n%%EOF\n");
    }

    /**
     * Les envois de fichier se testent à l'heure réelle : le nettoyage des envois temporaires
     * supprimerait sinon un fichier tout juste déposé, qu'il croirait vieux de deux semaines.
     */
    private function atRealTime(): void
    {
        $this->travelBack();
    }

    private function documents(Professional $professional)
    {
        return Livewire::test(DocumentsRelationManager::class, ['ownerRecord' => $professional, 'pageClass' => ViewProfessional::class]);
    }

    // --- Dépôt par l'agence ---

    public function test_the_coordinator_deposits_a_document_that_waits_for_the_administrator(): void
    {
        $this->atRealTime();
        $coordinator = $this->actingAsStaff(Role::Coordinateur);
        $professional = $this->hire($coordinator);

        $this->documents($professional)
            ->callTableAction('deposit', data: ['type' => 'diploma', 'file' => $this->pdf()])
            ->assertHasNoTableActionErrors()
            ->assertNotified(__('admin.professionals.document_deposited'));

        $document = $professional->documents()->sole();
        $this->assertSame('diploma', $document->type);
        $this->assertSame(ProfessionalDocument::STATUS_PENDING, $document->status);

        // Le fichier est chiffré, et on sait qui l'a déposé.
        $file = File::query()->findOrFail($document->file_id);
        $this->assertSame($coordinator->id, $file->uploaded_by);
        $this->assertSame('application/pdf', $file->mime);
        $stored = (string) Storage::disk('local')->get($file->path);
        $contents = app(EncryptedFileStore::class)->read($file, $coordinator);
        $this->assertStringStartsWith('%PDF-1.4', $contents);
        $this->assertStringNotContainsString('%PDF', $stored);
        $this->assertTrue(AuditLog::query()->where('event', 'team.document_deposited')->exists());
    }

    public function test_a_document_deposited_by_the_administrator_is_approved_at_once(): void
    {
        $this->atRealTime();
        $admin = $this->actingAsStaff(Role::Administrateur);
        $professional = $this->hire($admin);

        $this->documents($professional)
            ->callTableAction('deposit', data: ['type' => 'practice_authorization', 'file' => $this->pdf(), 'expires_at' => '2027-06-30'])
            ->assertHasNoTableActionErrors();

        $document = $professional->documents()->sole();
        $this->assertSame(ProfessionalDocument::STATUS_APPROVED, $document->status);
        $this->assertSame('2027-06-30', $document->expires_at?->format('Y-m-d'));
        $this->assertSame(1, DB::table('document_reviews')->where('reviewer_id', $admin->id)->where('decision', 'approved')->count());
    }

    public function test_a_deposit_is_checked_like_any_other(): void
    {
        $this->atRealTime();
        $admin = $this->actingAsStaff(Role::Administrateur);
        $professional = $this->hire($admin);

        $this->documents($professional)
            ->callTableAction('deposit', data: ['type' => null, 'file' => null])
            ->assertHasTableActionErrors(['type' => 'required', 'file' => 'required']);

        // L'inscription à l'Ordre n'est pas demandée à une infirmière : elle n'est pas proposée.
        $this->documents($professional)
            ->callTableAction('deposit', data: ['type' => 'order_registration', 'file' => $this->pdf()])
            ->assertHasTableActionErrors(['type']);

        // L'assurance, quand elle est déposée, exige sa date de fin de validité.
        $this->documents($professional)
            ->callTableAction('deposit', data: ['type' => 'rc_insurance', 'file' => $this->pdf()])
            ->assertNotified(__('api.errors.document_expiry_required'));

        $this->assertSame(0, $professional->documents()->count());
    }

    public function test_the_agency_builds_the_whole_file_and_the_caregiver_can_work_without_personal_insurance(): void
    {
        $admin = $this->actingAsStaff(Role::Administrateur);
        $professional = $this->hire($admin);
        $team = app(ManageTeam::class);

        foreach (self::NURSE_DOCUMENTS as $type) {
            $team->depositDocument($professional, $admin, $type, '%PDF-1.4', 'application/pdf', null);
        }

        // Le soignant voit son dossier complet : l'assurance personnelle est facultative.
        Sanctum::actingAs(User::query()->findOrFail($professional->user_id), ['app:pro']);
        $this->getJson('/api/v1/pro/profile')->assertOk()
            ->assertJsonPath('data.required_documents', self::NURSE_DOCUMENTS)
            ->assertJsonPath('data.optional_documents', ['rc_insurance'])
            ->assertJsonPath('data.missing_documents', [])
            ->assertJsonPath('data.can_submit', true);

        // L'agence envoie le dossier, l'administrateur le valide.
        $this->actingAs($admin, 'web');
        Livewire::test(ViewProfessional::class, ['record' => $professional->id])
            ->callAction('submit')
            ->assertNotified(__('admin.professionals.submitted'))
            ->callAction('verify')
            ->assertNotified(__('admin.professionals.verified'));

        $professional->refresh();
        $this->assertSame(VerificationStatus::Verified, $professional->verification_status);
        $this->assertTrue(AuditLog::query()->where('event', 'team.file_submitted')->exists());

        // Sans assurance personnelle, elle peut recevoir une mission.
        $this->assertSame(0, $professional->documents()->where('type', 'rc_insurance')->count());
        $this->assertTrue(app(ProfessionalMatcher::class)->isEligible($this->createBooking(), $professional));
    }

    public function test_a_caregiver_may_still_add_a_personal_insurance(): void
    {
        $admin = $this->actingAsStaff(Role::Administrateur);
        $professional = $this->hire($admin);
        Sanctum::actingAs(User::query()->findOrFail($professional->user_id), ['app:pro']);

        $this->post('/api/v1/pro/profile/documents', ['type' => 'rc_insurance', 'file' => $this->pdf()], ['Accept' => 'application/json'])
            ->assertStatus(422)->assertJsonPath('code', 'document_expiry_required');
        $this->post('/api/v1/pro/profile/documents', ['type' => 'rc_insurance', 'file' => $this->pdf(), 'expires_at' => '2027-06-30'], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonPath('data.documents.0.type', 'rc_insurance')
            // Facultative : elle ne compte pas parmi les justificatifs qui manquent.
            ->assertJsonPath('data.missing_documents', self::NURSE_DOCUMENTS);
    }

    public function test_only_the_coordination_deposits_documents(): void
    {
        $admin = $this->actingAsStaff(Role::Administrateur);
        $professional = $this->hire($admin);

        $this->actingAsStaff(Role::Comptable);
        $this->get("/admin/professionals/{$professional->id}")->assertForbidden();
    }

    // --- Suivi de la validité ---

    public function test_documents_to_renew_are_listed_on_the_dashboard_and_in_the_team_list(): void
    {
        $soon = $this->createProfessional(['name' => 'Expire bientôt', 'insurance_expires' => '2026-12-20']);
        $later = $this->createProfessional(['name' => 'Expire plus tard', 'insurance_expires' => '2027-06-30']);
        // Périmée, sans remplaçante : toujours à renouveler.
        $expired = $this->createProfessional(['name' => 'Déjà périmée', 'insurance' => ProfessionalDocument::STATUS_EXPIRED, 'insurance_expires' => '2026-11-01']);
        // Périmée, mais remplacée par une assurance approuvée : plus rien à faire.
        $renewed = $this->createProfessional(['name' => 'Renouvelée', 'insurance' => ProfessionalDocument::STATUS_EXPIRED, 'insurance_expires' => '2026-11-01']);
        $old = $renewed->documents()->sole();
        ProfessionalDocument::create([
            'professional_id' => $renewed->id, 'type' => 'rc_insurance', 'file_id' => $old->file_id,
            'expires_at' => '2027-11-01', 'status' => ProfessionalDocument::STATUS_APPROVED,
        ]);

        $this->actingAsStaff(Role::Coordinateur);

        Livewire::test(DocumentsToRenew::class)
            ->assertCanSeeTableRecords([$soon->documents()->sole(), $expired->documents()->sole()])
            ->assertCanNotSeeTableRecords([$later->documents()->sole(), $old])
            ->assertSee('Expire bientôt')
            ->assertSee('20/12/2026');

        Livewire::test(ListProfessionals::class)
            ->filterTable('documents_expiring')
            ->assertCanSeeTableRecords([$soon, $expired])
            ->assertCanNotSeeTableRecords([$later, $renewed])
            ->assertSee('20/12/2026');

        $this->get('/admin')->assertOk();
    }

    // --- Assurance de l'agence ---

    public function test_the_administrator_records_the_agency_insurance_with_its_certificate(): void
    {
        $this->atRealTime();
        $this->assertTrue(AgencyInsurance::needsAttention());
        $admin = $this->actingAsStaff(Role::Administrateur);

        Livewire::test(ListAgencyInsurances::class)
            ->callAction(CreateAction::class, data: [
                'insurer' => 'Assurances du Rif', 'policy_number' => 'RC-2026-0042',
                'expires_on' => '2027-12-31', 'attestation' => $this->pdf('attestation.pdf'),
            ])
            ->assertHasNoActionErrors();

        $insurance = AgencyInsurance::query()->sole();
        $this->assertSame('Assurances du Rif', $insurance->insurer);
        $this->assertSame($admin->id, $insurance->created_by);
        $this->assertStringStartsWith('%PDF-1.4', app(EncryptedFileStore::class)->read($insurance->file()->firstOrFail(), $admin));
        $this->assertTrue(AuditLog::query()->where('event', 'agency_insurance.created')->exists());
        $this->assertFalse(AgencyInsurance::needsAttention());

        // Modifier l'échéance garde l'attestation.
        Livewire::test(ListAgencyInsurances::class)
            ->callTableAction('edit', $insurance, data: ['expires_on' => '2028-12-31'])
            ->assertHasNoTableActionErrors();
        $insurance->refresh();
        $this->assertSame('2028-12-31', $insurance->expires_on->format('Y-m-d'));
        $this->assertNotNull($insurance->file_id);

        // À un mois de l'échéance, le menu alerte.
        $this->travelTo('2028-12-10 10:00');
        $this->assertTrue(AgencyInsurance::needsAttention());
    }

    public function test_the_coordinator_reads_the_agency_insurance_without_changing_it(): void
    {
        $insurance = AgencyInsurance::query()->create(['insurer' => 'Assurances du Rif', 'policy_number' => 'RC-1', 'expires_on' => '2027-12-31']);

        $this->actingAsStaff(Role::Coordinateur);
        $this->get('/admin/agency-insurance')->assertOk()->assertSee('Assurances du Rif');
        Livewire::test(ListAgencyInsurances::class)
            ->assertActionHidden(CreateAction::class)
            ->assertTableActionHidden('edit', $insurance);

        $this->actingAsStaff(Role::Comptable);
        $this->get('/admin/agency-insurance')->assertForbidden();
    }
}
