<?php

namespace App\Filament\Resources\Services\Schemas;

use App\Filament\Support\TranslatableFields;
use App\Models\ProfessionalCategory;
use App\Models\ServiceCategory;
use App\Support\Translated;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ServiceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Section::make(__('admin.common.translations'))
                ->schema([
                    ...TranslatableFields::inputs('name'),
                    ...TranslatableFields::textareas('description'),
                ]),

            Section::make(__('admin.common.settings'))
                ->schema([
                    Select::make('service_category_id')
                        ->label(__('admin.services.category'))
                        ->options(fn () => ServiceCategory::query()->orderBy('sort')->get()
                            ->mapWithKeys(fn (ServiceCategory $category) => [$category->id => Translated::pick($category->name)])->all())
                        ->required(),
                    Select::make('professional_category_id')
                        ->label(__('admin.services.professional_category'))
                        ->options(fn () => ProfessionalCategory::query()->where('is_active', true)->get()
                            ->mapWithKeys(fn (ProfessionalCategory $category) => [$category->id => Translated::pick($category->name)])->all())
                        ->required(),
                    TextInput::make('slug')
                        ->label(__('admin.common.slug'))
                        ->helperText(__('admin.common.slug_help'))
                        ->required()
                        ->maxLength(120)
                        ->regex('/^[a-z0-9]+(?:-[a-z0-9]+)*$/')
                        ->unique(ignoreRecord: true),
                    TextInput::make('duration_minutes')
                        ->label(__('admin.services.duration'))
                        ->required()
                        ->integer()
                        ->minValue(5)
                        ->maxValue(600),
                    // Saisi en dirhams, enregistré en centimes.
                    TextInput::make('base_price')
                        ->label(__('admin.services.price'))
                        ->helperText(__('admin.services.price_help'))
                        ->required()
                        ->numeric()
                        ->minValue(0)
                        ->maxValue(100000)
                        ->formatStateUsing(fn ($state) => $state === null ? null : $state / 100)
                        ->dehydrateStateUsing(fn ($state) => (int) round(((float) $state) * 100)),
                    Toggle::make('requires_prescription')
                        ->label(__('admin.services.requires_prescription'))
                        ->helperText(__('admin.services.requires_prescription_help')),
                    Toggle::make('allows_series')
                        ->label(__('admin.services.allows_series')),
                    Select::make('delivery_mode')
                        ->label(__('admin.services.delivery_mode'))
                        ->options([
                            'home' => __('admin.services.delivery_modes.home'),
                            'remote' => __('admin.services.delivery_modes.remote'),
                        ])
                        ->default('home')
                        ->selectablePlaceholder(false)
                        ->required(),
                    TextInput::make('sort')
                        ->label(__('admin.common.sort'))
                        ->required()
                        ->integer()
                        ->minValue(0)
                        ->default(0),
                    Toggle::make('is_active')
                        ->label(__('admin.common.active'))
                        ->default(true),
                ]),
        ]);
    }
}
