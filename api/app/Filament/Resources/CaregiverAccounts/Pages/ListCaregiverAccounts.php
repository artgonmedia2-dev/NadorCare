<?php

namespace App\Filament\Resources\CaregiverAccounts\Pages;

use App\Filament\Resources\CaregiverAccounts\CaregiverAccountResource;
use App\Services\Finance\CaregiverLedger;
use Filament\Resources\Pages\ListRecords;

class ListCaregiverAccounts extends ListRecords
{
    protected static string $resource = CaregiverAccountResource::class;

    /**
     * À chaque requête de l'écran, les chiffres sont recalculés : rien ne survit d'un affichage au suivant.
     */
    public function boot(): void
    {
        app(CaregiverLedger::class)->forget();
    }

    public function getSubheading(): ?string
    {
        return __('admin.finance.help');
    }
}
