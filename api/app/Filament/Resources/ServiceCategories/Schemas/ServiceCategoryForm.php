<?php

namespace App\Filament\Resources\ServiceCategories\Schemas;

use App\Filament\Support\TranslatableFields;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ServiceCategoryForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Section::make(__('admin.common.translations'))
                ->schema(TranslatableFields::inputs('name')),

            Section::make(__('admin.common.settings'))
                ->schema([
                    TextInput::make('slug')
                        ->label(__('admin.common.slug'))
                        ->helperText(__('admin.common.slug_help'))
                        ->required()
                        ->maxLength(120)
                        ->regex('/^[a-z0-9]+(?:-[a-z0-9]+)*$/')
                        ->unique(ignoreRecord: true),
                    TextInput::make('icon')
                        ->label(__('admin.service_categories.icon'))
                        ->maxLength(60),
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
