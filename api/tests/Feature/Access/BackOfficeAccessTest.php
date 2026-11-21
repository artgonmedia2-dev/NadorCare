<?php

namespace Tests\Feature\Access;

use App\Enums\Role;
use App\Models\User;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Filament\Facades\Filament;
use Tests\TestCase;

class BackOfficeAccessTest extends TestCase
{
    public function test_two_factor_authentication_is_mandatory_in_the_back_office(): void
    {
        $panel = Filament::getPanel('admin');

        $this->assertTrue($panel->isMultiFactorAuthenticationRequired());
        $this->assertInstanceOf(AppAuthentication::class, array_values($panel->getMultiFactorAuthenticationProviders())[0]);
    }

    public function test_staff_without_two_factor_are_sent_to_its_setup_before_anything_else(): void
    {
        $admin = User::factory()->staff(Role::Administrateur)->create();

        $response = $this->actingAs($admin)->get('/admin');

        $response->assertRedirect();
        $this->assertStringContainsString('multi-factor-authentication', $response->headers->get('Location'));
    }

    public function test_staff_with_two_factor_reach_the_dashboard(): void
    {
        $admin = User::factory()->staff(Role::Administrateur)->create();
        $admin->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());

        $this->actingAs($admin)->get('/admin')->assertOk();
    }

    public function test_the_two_factor_secret_is_encrypted_at_rest(): void
    {
        $admin = User::factory()->staff(Role::Administrateur)->create();
        $secret = AppAuthentication::make()->generateSecret();
        $admin->saveAppAuthenticationSecret($secret);

        $this->assertNotSame($secret, $admin->fresh()->getRawOriginal('app_authentication_secret'));
        $this->assertSame($secret, $admin->fresh()->getAppAuthenticationSecret());
    }

    public function test_patients_and_professionals_are_refused(): void
    {
        foreach ([Role::Patient, Role::Professionnel] as $role) {
            $this->actingAs($this->userWithRole($role))->get('/admin')->assertForbidden();
        }
    }

    public function test_the_queue_dashboard_is_reserved_to_administrators(): void
    {
        $this->get('/horizon')->assertForbidden();
        $this->actingAs($this->userWithRole(Role::Coordinateur))->get('/horizon')->assertForbidden();
        $this->actingAs($this->userWithRole(Role::Administrateur))->get('/horizon')->assertOk();
    }
}
