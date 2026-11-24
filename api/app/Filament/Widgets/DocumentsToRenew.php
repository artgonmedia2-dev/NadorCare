<?php

namespace App\Filament\Widgets;

use App\Enums\Permission;
use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Models\ProfessionalDocument;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

/**
 * Tableau de bord : justificatifs des soignants périmés ou qui arrivent à échéance. L'agence
 * suit la validité des documents de son équipe ; rien ne se bloque tout seul.
 */
class DocumentsToRenew extends TableWidget
{
    /** Chargé avec la page : un tableau de bord qui clignote à l'ouverture se lit mal. */
    protected static bool $isLazy = false;

    protected int|string|array $columnSpan = 'full';

    public static function canView(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsView->value) ?? false;
    }

    public function table(Table $table): Table
    {
        return $table
            ->heading(__('admin.professionals.to_renew.title', ['days' => ProfessionalResource::EXPIRY_ALERT_DAYS]))
            ->query(function (): Builder {
                $query = ProfessionalDocument::query()->with('professional.user:id,name');
                ProfessionalDocument::constrainToNeedsRenewal($query, ProfessionalResource::EXPIRY_ALERT_DAYS);

                return $query;
            })
            ->defaultSort('expires_at')
            ->paginated([10, 25])
            ->emptyStateHeading(__('admin.professionals.to_renew.none'))
            ->columns([
                TextColumn::make('professional.user.name')
                    ->label(__('admin.professionals.name'))
                    ->placeholder('—')
                    ->url(fn (ProfessionalDocument $record) => ProfessionalResource::getUrl('view', ['record' => $record->professional_id])),
                TextColumn::make('type')
                    ->label(__('admin.professionals.document'))
                    ->state(fn (ProfessionalDocument $record) => __('admin.professionals.document_types.'.$record->type)),
                TextColumn::make('expires_at')
                    ->label(__('admin.professionals.expires_at'))
                    ->date('d/m/Y')
                    ->badge()
                    ->color(fn (ProfessionalDocument $record) => $record->expires_at?->isBefore(today()) ? 'danger' : 'warning'),
            ]);
    }
}
