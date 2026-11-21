<?php

namespace App\Filament\Resources\Services\Pages;

use App\Filament\Resources\Services\ServiceResource;
use Filament\Resources\Pages\EditRecord;

/**
 * Pas d'action de suppression : un service retiré du catalogue est simplement masqué
 * (« Visible par le public »), ses réservations passées restent lisibles.
 */
class EditService extends EditRecord
{
    protected static string $resource = ServiceResource::class;
}
