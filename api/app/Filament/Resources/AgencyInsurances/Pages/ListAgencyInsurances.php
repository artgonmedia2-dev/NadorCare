<?php

namespace App\Filament\Resources\AgencyInsurances\Pages;

use App\Filament\Resources\AgencyInsurances\AgencyInsuranceResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

/**
 * Contrats d'assurance de l'agence. L'ajout et la modification se font dans une fenêtre,
 * et passent par `ManageAgencyInsurance`.
 */
class ListAgencyInsurances extends ListRecords
{
    protected static string $resource = AgencyInsuranceResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label(__('admin.agency_insurance.add'))
                ->using(fn (array $data) => AgencyInsuranceResource::save(null, $data)),
        ];
    }
}
