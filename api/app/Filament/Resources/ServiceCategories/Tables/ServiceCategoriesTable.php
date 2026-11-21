<?php

namespace App\Filament\Resources\ServiceCategories\Tables;

use App\Models\ServiceCategory;
use App\Support\Translated;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ServiceCategoriesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('sort')
            ->columns([
                TextColumn::make('name')
                    ->label(__('admin.common.name_in', ['language' => __('admin.languages.'.app()->getLocale())]))
                    ->state(fn (ServiceCategory $record) => Translated::pick($record->name)),
                TextColumn::make('slug')
                    ->label(__('admin.common.slug'))
                    ->searchable(),
                TextColumn::make('services_count')
                    ->label(__('admin.service_categories.services_count'))
                    ->counts('services'),
                TextColumn::make('sort')
                    ->label(__('admin.common.sort'))
                    ->sortable(),
                IconColumn::make('is_active')
                    ->label(__('admin.common.active'))
                    ->boolean(),
            ])
            // Pas de suppression en masse : une catégorie porte des services et des réservations.
            ->recordActions([
                EditAction::make(),
            ]);
    }
}
