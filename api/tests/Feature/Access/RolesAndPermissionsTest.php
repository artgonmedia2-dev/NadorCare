<?php

namespace Tests\Feature\Access;

use App\Enums\Permission;
use App\Enums\Role;
use App\Models\User;
use Filament\Facades\Filament;
use Spatie\Permission\Models\Role as RoleModel;
use Tests\TestCase;

class RolesAndPermissionsTest extends TestCase
{
    public function test_the_six_roles_of_the_specification_exist(): void
    {
        $this->assertEqualsCanonicalizing(Role::values(), RoleModel::query()->pluck('name')->all());
    }

    public function test_only_the_coordination_confirms_and_assigns_bookings(): void
    {
        foreach ([Role::Coordinateur, Role::Administrateur] as $role) {
            $user = $this->userWithRole($role);
            $this->assertTrue($user->can(Permission::BookingsConfirm->value), $role->value);
            $this->assertTrue($user->can(Permission::BookingsAssign->value), $role->value);
        }

        foreach ([Role::Patient, Role::Proche, Role::Professionnel, Role::Comptable] as $role) {
            $user = $this->userWithRole($role);
            $this->assertFalse($user->can(Permission::BookingsConfirm->value), $role->value);
            $this->assertFalse($user->can(Permission::BookingsAssign->value), $role->value);
        }
    }

    public function test_the_accountant_sees_finances_but_no_health_data(): void
    {
        $accountant = $this->userWithRole(Role::Comptable);

        $this->assertTrue($accountant->can(Permission::FinancesView->value));
        $this->assertTrue($accountant->can(Permission::PayoutsManage->value));
        $this->assertFalse($accountant->can(Permission::HealthDataView->value));
        $this->assertFalse($accountant->can(Permission::PatientsView->value));
    }

    public function test_only_the_administrator_manages_users_roles_and_verification(): void
    {
        $admin = $this->userWithRole(Role::Administrateur);
        $coordinator = $this->userWithRole(Role::Coordinateur);

        foreach ([Permission::UsersManage, Permission::RolesManage, Permission::ProfessionalsVerify, Permission::AuditView] as $permission) {
            $this->assertTrue($admin->can($permission->value), $permission->value);
            $this->assertFalse($coordinator->can($permission->value), $permission->value);
        }
    }

    public function test_only_active_staff_can_open_the_back_office(): void
    {
        $panel = Filament::getPanel('admin');

        foreach (Role::staff() as $role) {
            $this->assertTrue($this->userWithRole($role)->canAccessPanel($panel), $role->value);
        }

        foreach ([Role::Patient, Role::Proche, Role::Professionnel] as $role) {
            $this->assertFalse($this->userWithRole($role)->canAccessPanel($panel), $role->value);
        }

        $suspended = User::factory()->suspended()->withRole(Role::Administrateur)->create();
        $this->assertFalse($suspended->canAccessPanel($panel));
    }

    public function test_the_back_office_redirects_guests_to_its_login_page(): void
    {
        $this->get('/admin')->assertRedirect('/admin/login');
        $this->get('/admin/login')->assertOk();
    }
}
