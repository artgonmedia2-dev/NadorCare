<?php

namespace App\Filament\Pages;

use App\Filament\Resources\Bookings\BookingResource;
use App\Filament\Widgets\CoordinationStats;
use App\Filament\Widgets\DocumentsToRenew;
use App\Filament\Widgets\FinanceStats;
use App\Filament\Widgets\RequestsToHandle;
use App\Filament\Widgets\TodayMissions;
use App\Filament\Widgets\Watchlist;
use Carbon\CarbonImmutable;
use Filament\Actions\Action;
use Filament\Pages\Dashboard as BaseDashboard;
use Filament\Support\Icons\Heroicon;

/**
 * Tableau de bord de la coordination (refonte du 2026-11-24) : ce qui attend une décision
 * d'abord (chiffres, demandes à traiter), puis la journée et ce qu'il faut surveiller.
 */
class Dashboard extends BaseDashboard
{
    public function getTitle(): string
    {
        $name = trim((string) auth()->user()?->name);
        $first = $name === '' ? null : explode(' ', $name)[0];

        return $first === null ? __('admin.dashboard.hello_anonymous') : __('admin.dashboard.hello', ['name' => $first]);
    }

    public static function getNavigationLabel(): string
    {
        return __('admin.dashboard.nav');
    }

    public function getSubheading(): ?string
    {
        $now = CarbonImmutable::now((string) config('nadorcare.timezone'))->locale(app()->getLocale());

        return ucfirst($now->isoFormat('dddd D MMMM')).' · '.$now->format('H:i');
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('planning')
                ->label(__('admin.planning.nav'))
                ->icon(Heroicon::OutlinedCalendarDays)
                ->color('gray')
                ->url(fn () => TeamPlanning::getUrl())
                ->visible(fn () => TeamPlanning::canAccess()),
            Action::make('requests')
                ->label(__('admin.dashboard.all_requests'))
                ->icon(Heroicon::OutlinedInboxArrowDown)
                ->url(fn () => BookingResource::getUrl('index'))
                ->visible(fn () => BookingResource::canAccess()),
        ];
    }

    public function getWidgets(): array
    {
        return [
            CoordinationStats::class,
            FinanceStats::class,
            RequestsToHandle::class,
            TodayMissions::class,
            Watchlist::class,
            DocumentsToRenew::class,
        ];
    }

    public function getColumns(): int|array
    {
        return ['md' => 2];
    }
}
