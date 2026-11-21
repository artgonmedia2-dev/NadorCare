<?php

namespace Database\Seeders;

use App\Enums\Permission;
use App\Enums\Role;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission as PermissionModel;
use Spatie\Permission\Models\Role as RoleModel;
use Spatie\Permission\PermissionRegistrar;

/**
 * Les six rôles du cahier des charges (§2) et la matrice des permissions du back-office.
 * Rejouable sans risque : crée ce qui manque et réaligne les permissions de chaque rôle.
 */
class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        foreach (Permission::values() as $permission) {
            PermissionModel::findOrCreate($permission, 'web');
        }

        foreach (self::matrix() as $role => $permissions) {
            RoleModel::findOrCreate($role, 'web')->syncPermissions(
                array_map(fn (Permission $permission) => $permission->value, $permissions)
            );
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }

    /**
     * @return array<string, list<Permission>>
     */
    public static function matrix(): array
    {
        $coordination = [
            Permission::BookingsView,
            Permission::BookingsConfirm,
            Permission::BookingsAssign,
            Permission::BookingsCancel,
            Permission::BookingsCreateForPatient,
            Permission::DisputesManage,
            Permission::PatientsView,
            Permission::HealthDataView,
            Permission::ComplaintsManage,
            Permission::ProfessionalsView,
            Permission::StatsView,
        ];

        return [
            // Patients, proches et professionnels n'ont aucune permission de back-office :
            // leurs droits viennent des policies (propriété du compte, mission en cours).
            Role::Patient->value => [],
            Role::Proche->value => [],
            Role::Professionnel->value => [],

            Role::Coordinateur->value => $coordination,

            Role::Administrateur->value => [
                ...$coordination,
                Permission::ProfessionalsVerify,
                Permission::CatalogueManage,
                Permission::ZonesManage,
                Permission::ContentManage,
                Permission::FinancesView,
                Permission::UsersManage,
                Permission::RolesManage,
                Permission::AuditView,
            ],

            // Le comptable ne voit aucune donnée de santé.
            Role::Comptable->value => [
                Permission::FinancesView,
                Permission::PayoutsManage,
                Permission::StatsView,
            ],
        ];
    }
}
