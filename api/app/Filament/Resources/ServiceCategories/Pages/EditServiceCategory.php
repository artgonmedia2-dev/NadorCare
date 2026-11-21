<?php

namespace App\Filament\Resources\ServiceCategories\Pages;

use App\Filament\Resources\ServiceCategories\ServiceCategoryResource;
use Filament\Resources\Pages\EditRecord;

/**
 * Pas d'action de suppression : une catégorie se masque (« Visible par le public »).
 */
class EditServiceCategory extends EditRecord
{
    protected static string $resource = ServiceCategoryResource::class;
}
