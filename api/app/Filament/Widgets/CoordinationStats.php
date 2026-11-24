<?php

namespace App\Filament\Widgets;

use App\Enums\BookingStatus;
use App\Enums\Permission;
use App\Filament\Resources\Bookings\BookingResource;
use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Models\Booking;
use App\Models\ProfessionalDocument;
use Carbon\CarbonImmutable;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

/**
 * Chiffres du jour de la coordination : ce qui attend une décision passe en premier.
 */
class CoordinationStats extends StatsOverviewWidget
{
    /** Chargé avec la page : un tableau de bord qui clignote à l'ouverture se lit mal. */
    protected static bool $isLazy = false;

    protected int|string|array $columnSpan = 'full';

    protected ?string $pollingInterval = '30s';

    public static function canView(): bool
    {
        return auth()->user()?->can(Permission::BookingsView->value) ?? false;
    }

    protected function getColumns(): int
    {
        return 4;
    }

    /**
     * @return list<Stat>
     */
    protected function getStats(): array
    {
        $timezone = (string) config('nadorcare.timezone');
        $today = CarbonImmutable::now($timezone)->startOfDay();

        $pending = Booking::query()->where('status', BookingStatus::Pending)->count();
        $toReassign = Booking::query()->needsReassignment()->count();

        $todayCounts = Booking::query()
            ->where('scheduled_at', '>=', $today->utc())
            ->where('scheduled_at', '<', $today->addDay()->utc())
            ->whereIn('status', [...BookingStatus::activeMission(), BookingStatus::Completed])
            ->groupBy('status')
            ->selectRaw('status, COUNT(*) AS total')
            ->toBase()->pluck('total', 'status');
        $done = (int) ($todayCounts[BookingStatus::Completed->value] ?? 0);
        $onTheWay = (int) ($todayCounts[BookingStatus::EnRoute->value] ?? 0) + (int) ($todayCounts[BookingStatus::InProgress->value] ?? 0);
        $upcoming = (int) ($todayCounts[BookingStatus::Assigned->value] ?? 0);

        $toRenew = ProfessionalDocument::query();
        ProfessionalDocument::constrainToNeedsRenewal($toRenew, ProfessionalResource::EXPIRY_ALERT_DAYS);

        $bookings = BookingResource::getUrl('index');

        $stats = [
            Stat::make(__('admin.dashboard.stats.pending'), (string) $pending)
                ->description(__('admin.dashboard.stats.pending_help'))
                ->url($bookings),
            Stat::make(__('admin.dashboard.stats.reassign'), (string) $toReassign)
                ->description(__('admin.dashboard.stats.reassign_help'))
                ->extraAttributes($toReassign > 0 ? ['class' => 'nc-stat-alert'] : [])
                ->url($bookings),
            Stat::make(__('admin.dashboard.stats.today'), (string) ($done + $onTheWay + $upcoming))
                ->description(__('admin.dashboard.stats.today_help', ['done' => $done, 'moving' => $onTheWay, 'upcoming' => $upcoming])),
        ];

        if (auth()->user()?->can(Permission::ProfessionalsView->value)) {
            $stats[] = Stat::make(__('admin.dashboard.stats.documents'), (string) $toRenew->count())
                ->description(__('admin.dashboard.stats.documents_help', ['days' => ProfessionalResource::EXPIRY_ALERT_DAYS]))
                ->url(ProfessionalResource::getUrl('index'));
        }

        return $stats;
    }
}
