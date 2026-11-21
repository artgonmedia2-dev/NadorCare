<?php

namespace App\Filament\Resources\Services\Tables;

use App\Models\Service;
use App\Support\Translated;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ServicesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with('category'))
            ->defaultSort('sort')
            ->columns([
                TextColumn::make('name')
                    ->label(__('admin.common.name_in', ['language' => __('admin.languages.'.app()->getLocale())]))
                    ->state(fn (Service $record) => Translated::pick($record->name)),
                TextColumn::make('category')
                    ->label(__('admin.services.category'))
                    ->state(fn (Service $record) => Translated::pick($record->category->name)),
                TextColumn::make('duration_minutes')
                    ->label(__('admin.services.duration'))
                    ->sortable(),
                TextColumn::make('base_price')
                    ->label(__('admin.services.price'))
                    ->state(fn (Service $record) => number_format($record->base_price / 100, 2, ',', ' '))
                    ->sortable(),
                IconColumn::make('requires_prescription')
                    ->label(__('admin.services.requires_prescription'))
                    ->boolean(),
                IconColumn::make('is_active')
                    ->label(__('admin.common.active'))
                    ->boolean(),
            ])
            // Un service ne se supprime pas : on le masque, car des réservations y sont rattachées.
            ->recordActions([
                EditAction::make(),
            ]);
    }
}
