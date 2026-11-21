<?php

namespace App\Enums;

/**
 * Permissions du back-office. La répartition par rôle est dans RolesAndPermissionsSeeder.
 */
enum Permission: string
{
    case BookingsView = 'bookings.view';
    case BookingsConfirm = 'bookings.confirm';
    case BookingsAssign = 'bookings.assign';
    case BookingsCancel = 'bookings.cancel';
    case BookingsCreateForPatient = 'bookings.create-for-patient';
    case DisputesManage = 'disputes.manage';
    case PatientsView = 'patients.view';
    case HealthDataView = 'health-data.view';
    case ComplaintsManage = 'complaints.manage';
    case ProfessionalsView = 'professionals.view';
    case ProfessionalsVerify = 'professionals.verify';
    case CatalogueManage = 'catalogue.manage';
    case ZonesManage = 'zones.manage';
    case ContentManage = 'content.manage';
    case FinancesView = 'finances.view';
    case PayoutsManage = 'payouts.manage';
    case StatsView = 'stats.view';
    case UsersManage = 'users.manage';
    case RolesManage = 'roles.manage';
    case AuditView = 'audit.view';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $permission) => $permission->value, self::cases());
    }
}
