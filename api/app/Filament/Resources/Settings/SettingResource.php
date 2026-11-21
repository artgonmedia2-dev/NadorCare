<?php

namespace App\Filament\Resources\Settings;

use App\Enums\Permission;
use App\Filament\Resources\Settings\Pages\EditSetting;
use App\Filament\Resources\Settings\Pages\ListSettings;
use App\Models\Setting;
use App\Services\Settings\Settings;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;

/**
 * Paramètres de gestion (horaires de service, délais, frais d'annulation).
 * La liste est fixe : on modifie une valeur, on n'en crée ni n'en supprime.
 */
class SettingResource extends Resource
{
    protected static ?string $model = Setting::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCog6Tooth;

    protected static ?int $navigationSort = 5;

    /** Paramètres dont la valeur est une heure (HH:MM) ; les autres sont des nombres entiers. */
    private const TIME_KEYS = [Settings::DAY_START, Settings::DAY_END];

    public static function canAccess(): bool
    {
        return auth()->user()?->can(Permission::CatalogueManage->value) ?? false;
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function getNavigationGroup(): string
    {
        return __('admin.nav.catalogue');
    }

    public static function getModelLabel(): string
    {
        return __('admin.settings.label');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.settings.plural');
    }

    public static function labelFor(string $key): string
    {
        $translationKey = 'admin.settings.keys.'.str_replace('.', '_', $key);
        $label = __($translationKey);

        return $label === $translationKey ? $key : $label;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('value')
                ->label(fn (?Setting $record) => $record ? self::labelFor($record->key) : __('admin.settings.value'))
                ->required()
                ->rules(fn (?Setting $record) => in_array($record?->key, self::TIME_KEYS, true)
                    ? ['regex:/^([01]\d|2[0-3]):[0-5]\d$/']
                    : ['integer', 'min:0', 'max:100000'])
                ->dehydrateStateUsing(fn ($state, ?Setting $record) => in_array($record?->key, self::TIME_KEYS, true)
                    ? (string) $state
                    : (int) $state),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->paginated(false)
            ->columns([
                TextColumn::make('key')
                    ->label(__('admin.settings.label'))
                    ->state(fn (Setting $record) => self::labelFor($record->key)),
                TextColumn::make('value')
                    ->label(__('admin.settings.value')),
            ])
            ->recordActions([EditAction::make()]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListSettings::route('/'),
            'edit' => EditSetting::route('/{record}/edit'),
        ];
    }
}
