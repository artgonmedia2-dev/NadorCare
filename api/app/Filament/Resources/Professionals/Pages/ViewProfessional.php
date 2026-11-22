<?php

namespace App\Filament\Resources\Professionals\Pages;

use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Models\Professional;
use App\Support\Translated;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Pages\ViewRecord;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

/**
 * Fiche d'un professionnel : identité, profession, état du dossier, puis ses justificatifs.
 */
class ViewProfessional extends ViewRecord
{
    protected static string $resource = ProfessionalResource::class;

    protected function getHeaderActions(): array
    {
        return ProfessionalResource::fileActions();
    }

    public function infolist(Schema $schema): Schema
    {
        return $schema->components([
            Section::make(__('admin.professionals.label'))
                ->columns(2)
                ->schema([
                    TextEntry::make('user.name')
                        ->label(__('admin.professionals.name'))
                        ->placeholder('—'),
                    TextEntry::make('user.phone')
                        ->label(__('admin.professionals.phone')),
                    TextEntry::make('category')
                        ->label(__('admin.professionals.category'))
                        ->state(fn (Professional $record) => Translated::pick($record->category->name)),
                    TextEntry::make('verification_status')
                        ->label(__('admin.professionals.status'))
                        ->badge()
                        ->state(fn (Professional $record) => ProfessionalResource::statusOptions()[$record->verification_status->value])
                        ->color(fn (Professional $record) => ProfessionalResource::statusColor($record->verification_status)),
                    TextEntry::make('license_number')
                        ->label(__('admin.professionals.license_number'))
                        ->placeholder('—'),
                    TextEntry::make('order_number')
                        ->label(__('admin.professionals.order_number'))
                        ->placeholder('—'),
                    TextEntry::make('suspension_reason')
                        ->label(__('admin.professionals.reason'))
                        ->placeholder('—')
                        ->columnSpanFull(),
                ]),
        ]);
    }
}
