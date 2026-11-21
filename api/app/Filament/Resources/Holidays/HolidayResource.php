<?php

namespace App\Filament\Resources\Holidays;

use App\Enums\Permission;
use App\Filament\Resources\Holidays\Pages\CreateHoliday;
use App\Filament\Resources\Holidays\Pages\EditHoliday;
use App\Filament\Resources\Holidays\Pages\ListHolidays;
use App\Filament\Support\TranslatableFields;
use App\Models\Holiday;
use App\Support\Translated;
use BackedEnum;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DatePicker;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/**
 * Jours fériés : ils déclenchent la majoration « jour férié ». Les fêtes religieuses
 * changent de date chaque année, d'où une saisie manuelle.
 */
class HolidayResource extends Resource
{
    protected static ?string $model = Holiday::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCalendarDays;

    protected static ?int $navigationSort = 4;

    public static function canAccess(): bool
    {
        return auth()->user()?->can(Permission::CatalogueManage->value) ?? false;
    }

    public static function getNavigationGroup(): string
    {
        return __('admin.nav.catalogue');
    }

    public static function getModelLabel(): string
    {
        return __('admin.holidays.label');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.holidays.plural');
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            DatePicker::make('date')
                ->label(__('admin.holidays.date'))
                ->required()
                ->unique(ignoreRecord: true),
            ...TranslatableFields::inputs('name'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('date')
            ->columns([
                TextColumn::make('date')
                    ->label(__('admin.holidays.date'))
                    ->date('d/m/Y')
                    ->sortable(),
                TextColumn::make('name')
                    ->label(__('admin.common.name_in', ['language' => __('admin.languages.'.app()->getLocale())]))
                    ->state(fn (Holiday $record) => Translated::pick($record->name)),
            ])
            // Un jour férié se supprime sans risque : les prix déjà calculés sont figés dans les réservations.
            ->recordActions([EditAction::make(), DeleteAction::make()]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListHolidays::route('/'),
            'create' => CreateHoliday::route('/create'),
            'edit' => EditHoliday::route('/{record}/edit'),
        ];
    }
}
