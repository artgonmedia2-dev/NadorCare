<?php

namespace Tests\Feature\Patients;

use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Models\AccessLog;
use App\Models\Booking;
use App\Models\PatientProfile;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PatientProfileApiTest extends TestCase
{
    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = $this->userWithRole(Role::Patient);
        Sanctum::actingAs($this->user, ['app:patient']);
    }

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'first_name' => 'Aïcha',
            'last_name' => 'Benali',
            'relationship' => 'parent',
            'birth_date' => '1948-03-12',
            'sex' => 'female',
            'care_notes' => 'Diabète de type 2, se déplace avec un déambulateur',
        ], $overrides);
    }

    public function test_an_account_holds_several_patient_profiles(): void
    {
        $this->postJson('/api/v1/patient-profiles', $this->payload(['relationship' => 'self', 'first_name' => 'Karim']))->assertCreated();
        $this->postJson('/api/v1/patient-profiles', $this->payload())->assertCreated();
        $this->postJson('/api/v1/patient-profiles', $this->payload(['relationship' => 'child', 'first_name' => 'Yanis', 'birth_date' => '2019-06-01']))->assertCreated();

        $this->getJson('/api/v1/patient-profiles')
            ->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.first_name', 'Karim')
            ->assertJsonPath('data.1.relationship', 'parent')
            ->assertJsonPath('data.2.birth_date', '2019-06-01');
    }

    public function test_care_notes_are_encrypted_and_absent_from_the_list(): void
    {
        $id = $this->postJson('/api/v1/patient-profiles', $this->payload())
            ->assertCreated()
            ->assertJsonPath('data.care_notes', 'Diabète de type 2, se déplace avec un déambulateur')
            ->json('data.id');

        $this->assertStringNotContainsString('Diabète', DB::table('patient_profiles')->where('id', $id)->value('care_notes'));

        $this->getJson('/api/v1/patient-profiles')
            ->assertOk()
            ->assertJsonPath('data.0.has_care_notes', true)
            ->assertJsonMissingPath('data.0.care_notes');
    }

    public function test_writing_and_reading_a_profile_is_logged(): void
    {
        $id = $this->postJson('/api/v1/patient-profiles', $this->payload())->json('data.id');
        $this->getJson("/api/v1/patient-profiles/$id")->assertOk()->assertJsonPath('data.care_notes', 'Diabète de type 2, se déplace avec un déambulateur');
        $this->patchJson("/api/v1/patient-profiles/$id", ['care_notes' => 'Allergie à l\'iode'])->assertOk();

        $logs = AccessLog::query()->where('patient_profile_id', $id)->orderBy('id')->get();

        $this->assertSame([AccessAction::Create, AccessAction::View, AccessAction::Update], $logs->pluck('action')->all());
        $this->assertTrue($logs->every(fn (AccessLog $log) => $log->actor_id === $this->user->id));

        // La liste, sans donnée de santé, n'écrit rien de plus.
        $this->getJson('/api/v1/patient-profiles')->assertOk();
        $this->assertSame(3, AccessLog::query()->count());
    }

    public function test_only_one_profile_can_be_the_account_holder(): void
    {
        $this->postJson('/api/v1/patient-profiles', $this->payload(['relationship' => 'self']))->assertCreated();

        $this->postJson('/api/v1/patient-profiles', $this->payload(['relationship' => 'self']))
            ->assertStatus(422)
            ->assertJsonPath('code', 'self_profile_exists');

        $parent = $this->postJson('/api/v1/patient-profiles', $this->payload())->json('data.id');
        $this->patchJson("/api/v1/patient-profiles/$parent", ['relationship' => 'self'])
            ->assertStatus(422)
            ->assertJsonPath('code', 'self_profile_exists');
    }

    public function test_invalid_data_is_rejected_field_by_field(): void
    {
        $this->postJson('/api/v1/patient-profiles', [
            'first_name' => '',
            'relationship' => 'cousin',
            'birth_date' => now()->addDay()->format('Y-m-d'),
            'sex' => 'x',
            'phone' => '123',
        ])
            ->assertStatus(422)
            ->assertJsonPath('code', 'validation_failed')
            ->assertJsonValidationErrors(['first_name', 'last_name', 'relationship', 'birth_date', 'sex', 'phone']);

        $this->assertSame(0, PatientProfile::query()->count());
    }

    public function test_a_profile_is_updated_partially(): void
    {
        $id = $this->postJson('/api/v1/patient-profiles', $this->payload())->json('data.id');

        $this->patchJson("/api/v1/patient-profiles/$id", ['phone' => '0661223344', 'care_notes' => null])
            ->assertOk()
            ->assertJsonPath('data.phone', '+212661223344')
            ->assertJsonPath('data.first_name', 'Aïcha')
            ->assertJsonPath('data.has_care_notes', false);
    }

    public function test_profiles_of_other_accounts_are_invisible(): void
    {
        $other = PatientProfile::factory()->create();

        $this->getJson('/api/v1/patient-profiles')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson("/api/v1/patient-profiles/{$other->id}")->assertNotFound()->assertJsonPath('code', 'not_found');
        $this->patchJson("/api/v1/patient-profiles/{$other->id}", ['first_name' => 'Pirate'])->assertNotFound();
        $this->deleteJson("/api/v1/patient-profiles/{$other->id}")->assertNotFound();

        $this->assertNotSame('Pirate', $other->fresh()->first_name);
        $this->assertSame(0, AccessLog::query()->count());
    }

    public function test_a_profile_is_removed_unless_care_is_planned_or_in_progress(): void
    {
        $profile = PatientProfile::factory()->create(['user_id' => $this->user->id]);
        $booking = Booking::factory()->inStatus(BookingStatus::Confirmed)->create([
            'user_id' => $this->user->id,
            'patient_profile_id' => $profile->id,
        ]);

        $this->deleteJson("/api/v1/patient-profiles/{$profile->id}")
            ->assertStatus(409)
            ->assertJsonPath('code', 'profile_in_use');

        DB::table('bookings')->where('id', $booking->id)->update(['status' => BookingStatus::Completed->value]);

        $this->deleteJson("/api/v1/patient-profiles/{$profile->id}")->assertNoContent();
        $this->getJson('/api/v1/patient-profiles')->assertJsonCount(0, 'data');

        // Le profil est masqué, pas effacé : l'historique des soins reste rattaché.
        $this->assertSoftDeleted('patient_profiles', ['id' => $profile->id]);
    }

    public function test_the_number_of_profiles_per_account_is_capped(): void
    {
        config(['nadorcare.limits.patient_profiles' => 2]);

        $this->postJson('/api/v1/patient-profiles', $this->payload())->assertCreated();
        $this->postJson('/api/v1/patient-profiles', $this->payload())->assertCreated();
        $this->postJson('/api/v1/patient-profiles', $this->payload())
            ->assertStatus(422)
            ->assertJsonPath('code', 'profile_limit_reached');
    }

    public function test_a_professional_app_token_cannot_manage_patient_profiles(): void
    {
        Sanctum::actingAs($this->user, ['app:pro']);

        $this->getJson('/api/v1/patient-profiles')->assertForbidden()->assertJsonPath('code', 'forbidden');
        $this->postJson('/api/v1/patient-profiles', $this->payload())->assertForbidden();
    }

    public function test_guests_are_refused(): void
    {
        $this->app['auth']->forgetGuards();

        $this->getJson('/api/v1/patient-profiles')->assertUnauthorized();
    }
}
