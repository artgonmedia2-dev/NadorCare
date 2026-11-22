<?php

namespace App\Filament\Resources\Professionals\RelationManagers;

use App\Actions\Professionals\ReviewProfessional;
use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Models\ProfessionalDocument;
use App\Services\Files\EncryptedFileStore;
use Filament\Actions\Action;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Justificatifs d'un professionnel : consultation du fichier, approbation, refus.
 * Chaque ouverture de fichier est journalisée, chaque décision entre dans l'historique des contrôles.
 */
class DocumentsRelationManager extends RelationManager
{
    protected static string $relationship = 'documents';

    public static function getTitle(Model $ownerRecord, string $pageClass): string
    {
        return __('admin.professionals.documents');
    }

    public function isReadOnly(): bool
    {
        return false;
    }

    public static function typeLabel(string $type): string
    {
        return __('admin.professionals.document_types.'.$type);
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('type')
                    ->label(__('admin.professionals.document'))
                    ->state(fn (ProfessionalDocument $record) => self::typeLabel($record->type)),
                TextColumn::make('status')
                    ->label(__('admin.professionals.status'))
                    ->badge()
                    ->state(fn (ProfessionalDocument $record) => __('admin.professionals.document_statuses.'.$record->status))
                    ->color(fn (ProfessionalDocument $record) => match ($record->status) {
                        ProfessionalDocument::STATUS_APPROVED => 'success',
                        ProfessionalDocument::STATUS_PENDING => 'warning',
                        default => 'danger',
                    }),
                TextColumn::make('expires_at')
                    ->label(__('admin.professionals.expires_at'))
                    ->date('d/m/Y')
                    ->placeholder('—'),
                TextColumn::make('rejection_reason')
                    ->label(__('admin.professionals.reason'))
                    ->placeholder('—')
                    ->wrap(),
                TextColumn::make('created_at')
                    ->label(__('admin.professionals.uploaded_at'))
                    ->dateTime('d/m/Y H:i', (string) config('nadorcare.timezone')),
            ])
            ->recordActions([
                Action::make('download')
                    ->label(__('admin.professionals.open_document'))
                    ->icon(Heroicon::OutlinedArrowDownTray)
                    ->visible(fn () => ProfessionalResource::mayVerify())
                    ->action(fn (ProfessionalDocument $record) => self::download($record)),
                Action::make('approve')
                    ->label(__('admin.professionals.approve_document'))
                    ->icon(Heroicon::OutlinedCheck)
                    ->color('success')
                    ->requiresConfirmation()
                    ->visible(fn (ProfessionalDocument $record) => ProfessionalResource::mayVerify() && $record->status === ProfessionalDocument::STATUS_PENDING)
                    ->action(fn (ProfessionalDocument $record) => ProfessionalResource::run(
                        fn () => app(ReviewProfessional::class)->approveDocument($record, auth()->user()),
                        __('admin.professionals.document_approved'),
                    )),
                Action::make('reject')
                    ->label(__('admin.professionals.reject_document'))
                    ->icon(Heroicon::OutlinedXMark)
                    ->color('danger')
                    ->schema([ProfessionalResource::reasonField()])
                    ->visible(fn (ProfessionalDocument $record) => ProfessionalResource::mayVerify() && $record->status === ProfessionalDocument::STATUS_PENDING)
                    ->action(fn (ProfessionalDocument $record, array $data) => ProfessionalResource::run(
                        fn () => app(ReviewProfessional::class)->rejectDocument($record, auth()->user(), $data['reason']),
                        __('admin.professionals.document_rejected'),
                    )),
            ]);
    }

    /**
     * Déchiffre le fichier et l'envoie au navigateur. La lecture est inscrite au journal des accès.
     */
    private static function download(ProfessionalDocument $document): StreamedResponse
    {
        $file = $document->file()->firstOrFail();
        $contents = app(EncryptedFileStore::class)->read($file, auth()->user());

        $extension = match ($file->mime) {
            'application/pdf' => 'pdf',
            'image/png' => 'png',
            default => 'jpg',
        };

        return response()->streamDownload(
            fn () => print ($contents),
            $document->type.'-'.$document->id.'.'.$extension,
            ['Content-Type' => $file->mime],
        );
    }
}
