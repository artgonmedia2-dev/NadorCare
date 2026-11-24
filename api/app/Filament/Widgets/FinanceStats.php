<?php

namespace App\Filament\Widgets;

use App\Enums\Permission;
use App\Filament\Resources\CaregiverAccounts\CaregiverAccountResource;
use App\Services\Finance\CaregiverLedger;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

/**
 * Tableau de bord du comptable : ce que les soignants doivent encore remettre, et les
 * rémunérations du mois qui restent à saisir. Aucune donnée de patient.
 */
class FinanceStats extends StatsOverviewWidget
{
    /** Chargé avec la page : un tableau de bord qui clignote à l'ouverture se lit mal. */
    protected static bool $isLazy = false;

    protected int|string|array $columnSpan = 'full';

    public static function canView(): bool
    {
        $user = auth()->user();

        // La coordination a son propre tableau : celui-ci est pour qui tient les comptes.
        return $user !== null
            && $user->can(Permission::FinancesView->value)
            && ! $user->can(Permission::BookingsView->value);
    }

    protected function getColumns(): int
    {
        return 3;
    }

    /**
     * @return list<Stat>
     */
    protected function getStats(): array
    {
        $ledger = app(CaregiverLedger::class);
        $period = CaregiverLedger::currentPeriod();
        $summaries = $ledger->summaries($period);

        $toHandOver = array_sum(array_map(fn (array $row) => max(0, $row['balance']), $summaries));
        $holders = count(array_filter($summaries, fn (array $row) => $row['balance'] > 0));
        $missing = count(array_filter($summaries, fn (array $row) => $row['missions'] > 0 && $row['remuneration'] === null));
        $missions = array_sum(array_column($summaries, 'missions'));
        $url = CaregiverAccountResource::getUrl('index');

        return [
            Stat::make(__('admin.dashboard.finance.to_hand_over'), CaregiverAccountResource::money($toHandOver).' DH')
                ->description(trans_choice('admin.dashboard.finance.holders', $holders, ['count' => $holders]))
                ->url($url),
            Stat::make(__('admin.dashboard.finance.missions'), (string) $missions)
                ->description(__('admin.dashboard.finance.missions_help'))
                ->url($url),
            Stat::make(__('admin.dashboard.finance.remunerations'), (string) $missing)
                ->description(__('admin.dashboard.finance.remunerations_help'))
                ->extraAttributes($missing > 0 ? ['class' => 'nc-stat-alert'] : [])
                ->url($url),
        ];
    }
}
