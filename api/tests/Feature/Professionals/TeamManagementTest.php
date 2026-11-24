<?php

namespace Tests\Feature\Professionals;

use App\Actions\Professionals\ManageTeam;
use App\Enums\Role;
use App\Enums\VerificationStatus;
use App\Exceptions\ApiException;
use App\Filament\Resources\Professionals\Pages\CreateProfessional;
use App\Filament\Resources\Professionals\Pages\EditProfessional;
use App\Filament\Resources\Professionals\Pages\ViewProfessional;
use App\Models\AuditLog;
use App\Models\Professional;
use App\Models\ProfessionalCategory;
use App\Models\User;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Laravel\Sanctum\Sanctum;
use Livewire\Livewire;
use Tests\TestCase;

/**
 * Modèle « agence » (décision du 2026-11-23) : c'est l'agence qui crée, tient à jour et invite
 * les soignants de son équipe, depuis le back-office.
 */
class TeamManagementTest extends TestCase
{
    private const PHONE = '+212661234567';

    private ProfessionalCategory $nurses;

    protected function setUp(): void
    {
        parent::setUp();
        $this->nurses = ProfessionalCategory::factory()->create([
            'code' => 'nurse',
            'name' => ['fr' => 'Infirmier', 'ar' => 'ممرض', 'en' => 'Nurse'],
        ]);
    }

    private function actingAsStaff(Role $role): User
    {
        $this->flushSession();
        $staff = User::factory()->staff($role)->create();
        $staff->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($staff, 'web');

        return $staff;
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function form(array $overrides = []): array
    {
        return [
            'name' => 'Samira El Idrissi',
            'phone' => '06 61 23 45 67',
            'professional_category_id' => $this->nurses->id,
            'license_number' => 'AE-2020-114',
            ...$overrides,
        ];
    }

    public function test_the_coordinator_adds_a_caregiver_to_the_team(): void
    {
        $coordinator = $this->actingAsStaff(Role::Coordinateur);

        Livewire::test(CreateProfessional::class)
            ->fillForm($this->form())
            ->call('create')
            ->assertHasNoFormErrors();

        $professional = Professional::query()->sole();
        $user = User::query()->findOrFail($professional->user_id);

        // Le numéro local est enregistré au format international : c'est l'identifiant de connexion.
        $this->assertSame(self::PHONE, $user->phone);
        $this->assertSame('Samira El Idrissi', $user->name);
        $this->assertTrue($user->hasRole(Role::Professionnel->value));
        $this->assertSame(VerificationStatus::Draft, $professional->verification_status);
        $this->assertSame('AE-2020-114', $professional->license_number);
        $this->assertSame($coordinator->id, $professional->created_by);
        $this->assertNull($professional->invited_at);
        $this->assertTrue(AuditLog::query()->where('event', 'team.member_created')->exists());
    }

    public function test_required_fields_and_the_phone_format_are_checked(): void
    {
        $this->actingAsStaff(Role::Coordinateur);

        Livewire::test(CreateProfessional::class)
            ->fillForm($this->form(['name' => '', 'professional_category_id' => null]))
            ->call('create')
            ->assertHasFormErrors(['name' => 'required', 'professional_category_id' => 'required']);

        Livewire::test(CreateProfessional::class)
            ->fillForm($this->form(['phone' => '12345']))
            ->call('create')
            ->assertNotified(__('api.errors.phone_invalid'));

        $this->assertSame(0, Professional::query()->count());
    }

    public function test_a_number_already_in_the_team_is_refused_but_a_patient_can_join_it(): void
    {
        $staff = $this->actingAsStaff(Role::Administrateur);
        $team = app(ManageTeam::class);

        // Un patient déjà connu rejoint l'équipe avec le même compte.
        $patient = User::factory()->withRole(Role::Patient)->create(['phone' => self::PHONE, 'name' => 'Samira']);
        $professional = $team->create($staff, $this->form());

        $this->assertSame($patient->id, $professional->user_id);
        $this->assertSame(1, User::query()->where('phone', self::PHONE)->count());
        $this->assertTrue($patient->fresh()->hasRole(Role::Patient->value));
        $this->assertTrue($patient->fresh()->hasRole(Role::Professionnel->value));

        // Le même numéro ne peut pas entrer deux fois dans l'équipe.
        try {
            $team->create($staff, $this->form(['name' => 'Autre']));
            $this->fail('Le doublon aurait dû être refusé.');
        } catch (ApiException $exception) {
            $this->assertSame('team_member_exists', $exception->errorCode);
        }
        $this->assertSame(1, Professional::query()->count());
    }

    public function test_a_closed_profession_is_refused(): void
    {
        $staff = $this->actingAsStaff(Role::Administrateur);
        $closed = ProfessionalCategory::factory()->create(['is_active' => false]);

        try {
            app(ManageTeam::class)->create($staff, $this->form(['professional_category_id' => $closed->id]));
            $this->fail('Une profession fermée aurait dû être refusée.');
        } catch (ApiException $exception) {
            $this->assertSame('professional_category_unavailable', $exception->errorCode);
        }
        $this->assertSame(0, Professional::query()->count());
    }

    public function test_the_caregiver_is_invited_by_sms_and_then_signs_in_with_that_number(): void
    {
        $staff = $this->actingAsStaff(Role::Coordinateur);
        config(['nadorcare.apps.pro_url' => 'https://exemple.test/app-soignants']);
        $professional = app(ManageTeam::class)->create($staff, $this->form());

        Livewire::test(ViewProfessional::class, ['record' => $professional->id])
            ->callAction('invite')
            ->assertNotified(__('admin.professionals.invited'));

        $message = (string) $this->sms()->lastMessageTo(self::PHONE);
        $this->assertStringContainsString('https://exemple.test/app-soignants', $message);
        $this->assertNotNull($professional->fresh()->invited_at);
        $this->assertTrue(AuditLog::query()->where('event', 'team.member_invited')->exists());

        // Le soignant se connecte avec ce numéro et un code, sans mot de passe ni consentement à cocher.
        $this->flushSession();
        $this->postJson('/api/v1/auth/otp/request', ['phone' => self::PHONE])->assertStatus(202);
        preg_match('/\d{6}/', (string) $this->sms()->lastMessageTo(self::PHONE), $code);

        $this->postJson('/api/v1/auth/otp/verify', [
            'phone' => self::PHONE, 'code' => $code[0], 'app' => 'pro', 'device_name' => 'Pixel 8',
        ])->assertOk()->assertJsonPath('user.name', 'Samira El Idrissi');
    }

    public function test_changing_the_phone_number_closes_the_open_sessions(): void
    {
        $staff = $this->actingAsStaff(Role::Coordinateur);
        $professional = app(ManageTeam::class)->create($staff, $this->form());
        $user = User::query()->findOrFail($professional->user_id);
        $user->createToken('Pixel 8', ['app:pro']);
        app(ManageTeam::class)->invite($professional, $staff);

        Livewire::test(EditProfessional::class, ['record' => $professional->id])
            ->assertFormSet(['name' => 'Samira El Idrissi', 'phone' => self::PHONE])
            ->fillForm(['name' => 'Samira Idrissi', 'phone' => '+212662000000', 'order_number' => 'ON-77'])
            ->call('save')
            ->assertHasNoFormErrors();

        $user->refresh();
        $this->assertSame('Samira Idrissi', $user->name);
        $this->assertSame('+212662000000', $user->phone);
        $this->assertSame('ON-77', $professional->fresh()->order_number);
        // L'ancien téléphone ne doit plus ouvrir l'application, et le nouveau n'a pas été invité.
        $this->assertSame(0, $user->tokens()->count());
        $this->assertNull($professional->fresh()->invited_at);
    }

    public function test_a_phone_number_used_by_another_account_cannot_be_taken(): void
    {
        $staff = $this->actingAsStaff(Role::Coordinateur);
        $professional = app(ManageTeam::class)->create($staff, $this->form());
        User::factory()->withRole(Role::Patient)->create(['phone' => '+212662000000']);

        Livewire::test(EditProfessional::class, ['record' => $professional->id])
            ->fillForm(['phone' => '+212662000000'])
            ->call('save')
            ->assertNotified(__('api.errors.phone_already_used'));

        $this->assertSame(self::PHONE, User::query()->findOrFail($professional->user_id)->phone);
    }

    public function test_only_the_coordination_manages_the_team(): void
    {
        $staff = $this->actingAsStaff(Role::Administrateur);
        $professional = app(ManageTeam::class)->create($staff, $this->form());

        // Le comptable n'a pas accès aux fiches des soignants.
        $this->actingAsStaff(Role::Comptable);
        $this->get('/admin/professionals/create')->assertForbidden();
        $this->get("/admin/professionals/{$professional->id}/edit")->assertForbidden();

        // Un soignant n'entre pas dans le back-office, et l'API n'offre aucun moyen de créer une fiche.
        $this->flushSession();
        Sanctum::actingAs(User::factory()->withRole(Role::Professionnel)->create(), ['app:pro']);
        $this->putJson('/api/v1/pro/profile', ['professional_category_id' => $this->nurses->id])->assertStatus(405);
    }
}
