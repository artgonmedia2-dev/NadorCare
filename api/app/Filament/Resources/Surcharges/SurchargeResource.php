<?php

namespace App\Filament\Resources\Surcharges;

use App\Enums\Permission;
use App\Filament\Resources\Surcharges\Pages\CreateSurcharge;
use App\Filament\Resources\Surcharges\Pages\EditSurcharge;
use App\Filament\Resources\Surcharges\Pages\ListSurcharges;
use App\Filament\Support\TranslatableFields;
use App\Models\Surcharge;
use App\Support\Translated;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\TimePicker;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/**
 * Majorations du tarif (cahier des charges §6) : nuit et jour férié.
 * La majoration de distance n'est pas proposée tant que son mode de calcul n'est pas défini.
 */
class SurchargeResource extends Resource
{
    protected static ?string $model = Surcharge::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArrowTrendingUp;

    protected static ?int $navigationSort = 3;

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
        return __('admin.surcharges.label');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.surcharges.plural');
    }

    /**
     * @return array<string, string>
     */
    public static function typeOptions(): array
    {
        return [
            Surcharge::TYPE_NIGHT => __('admin.surcharges.types.night'),
            Surcharge::TYPE_HOLIDAY => __('admin.surcharges.types.holiday'),
        ];
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            Section::make(__('admin.common.translations'))
                ->schema(TranslatableFields::inputs('name')),

            Section::make(__('admin.common.settings'))
                ->schema([
                    Select::make('type')
                        ->label(__('admin.surcharges.type'))
                        ->options(self::typeOptions())
                        ->required()
                        ->live(),
                    Select::make('mode')
                        ->label(__('admin.surcharges.mode'))
                        ->options([
                            Surcharge::MODE_PERCENT => __('admin.surcharges.modes.percent'),
                            Surcharge::MODE_FIXED => __('admin.surcharges.modes.fixed'),
                        ])
                        ->required()
                        ->live(),
                    // Pourcentage, ou montant saisi en dirhams et enregistré en centimes.
                    TextInput::make('value')
                        ->label(__('admin.surcharges.value'))
                        ->helperText(__('admin.surcharges.value_help'))
                        ->required()
                        ->numeric()
                        ->minValue(0)
                        ->maxValue(100000)
                        ->dehydrateStateUsing(fn ($state, Get $get) => $get('mode') === Surcharge::MODE_FIXED
                            ? (int) round(((float) $state) * 100)
                            : (int) round((float) $state)),
                    TimePicker::make('config.start')
                        ->label(__('admin.surcharges.night_start'))
                        ->seconds(false)
                        ->format('H:i')
                        ->visible(fn (Get $get) => $get('type') === Surcharge::TYPE_NIGHT)
                        ->required(fn (Get $get) => $get('type') === Surcharge::TYPE_NIGHT),
                    TimePicker::make('config.end')
                        ->label(__('admin.surcharges.night_end'))
                        ->seconds(false)
                        ->format('H:i')
                        ->visible(fn (Get $get) => $get('type') === Surcharge::TYPE_NIGHT)
                        ->required(fn (Get $get) => $get('type') === Surcharge::TYPE_NIGHT),
                    Toggle::make('is_active')
                        ->label(__('admin.surcharges.active'))
                        ->default(true),
                ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label(__('admin.common.name_in', ['language' => __('admin.languages.'.app()->getLocale())]))
                    ->state(fn (Surcharge $record) => Translated::pick($record->name)),
                TextColumn::make('type')
                    ->label(__('admin.surcharges.type'))
                    ->state(fn (Surcharge $record) => self::typeOptions()[$record->type] ?? $record->type),
                TextColumn::make('value')
                    ->label(__('admin.surcharges.value'))
                    ->state(fn (Surcharge $record) => $record->mode === Surcharge::MODE_PERCENT
                        ? $record->value.' %'
                        : number_format($record->value / 100, 2, ',', ' ').' DH'),
                IconColumn::make('is_active')
                    ->label(__('admin.surcharges.active'))
                    ->boolean(),
            ])
            ->recordActions([EditAction::make()]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListSurcharges::route('/'),
            'create' => CreateSurcharge::route('/create'),
            'edit' => EditSurcharge::route('/{record}/edit'),
        ];
    }
}
