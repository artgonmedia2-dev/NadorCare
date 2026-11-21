<?php

namespace App\Filament\Resources\Surcharges\Pages;

use App\Filament\Resources\Surcharges\SurchargeResource;
use App\Models\Surcharge;
use Filament\Resources\Pages\EditRecord;

class EditSurcharge extends EditRecord
{
    protected static string $resource = SurchargeResource::class;

    /**
     * Le montant fixe est enregistre en centimes et se saisit en dirhams.
     */
    protected function mutateFormDataBeforeFill(array $data): array
    {
        if (($data['mode'] ?? null) === Surcharge::MODE_FIXED && isset($data['value'])) {
            $data['value'] = $data['value'] / 100;
        }

        return $data;
    }
}
