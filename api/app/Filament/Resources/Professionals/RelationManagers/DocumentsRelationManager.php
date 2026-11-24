<?php

namespace App\Filament\Resources\Professionals\RelationManagers;

use App\Actions\Professionals\ManageProfessionalFile;
use App\Actions\Professionals\ManageTeam;
use App\Actions\Professionals\ReviewProfessional;
use App\Filament\Resources\AgencyInsurances\AgencyInsuranceResource;
use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Models\Professional;
use App\Models\ProfessionalDocument;
use App\Services\Files\EncryptedFileStore;
use Filament\Actions\Action;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Justificatifs d'un professionnel : dépôt par l'agence, consultation du fichier, approbation, refus.
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
            ->headerActions([
                // L'agence dépose un justificatif à la place du soignant. Le fichier n'est pas rangé
                // par Filament : il est chiffré par l'action métier.
                Action::make('deposit')
                    ->label(__('admin.professionals.deposit_document'))
                    ->icon(Heroicon::OutlinedArrowUpTray)
                    ->visible(fn () => ProfessionalResource::mayManage())
                    ->schema(fn () => [
                        Select::make('type')
                            ->label(__('admin.professionals.document'))
                            ->options(fn () => collect(app(ManageProfessionalFile::class)->acceptedTypes($this->professional()))
                                ->mapWithKeys(fn (string $type) => [$type => self::typeLabel($type)])
                                ->all())
                            ->required(),
                        FileUpload::make('file')
                            ->label(__('admin.professionals.document_file'))
                            ->acceptedFileTypes(['application/pdf', 'image/jpeg', 'image/png'])
                            ->maxSize(10240)
                            ->storeFiles(false)
                            ->required(),
                        DatePicker::make('expires_at')
                            ->label(__('admin.professionals.expires_at'))
                            ->helperText(__('admin.professionals.expires_at_help'))
                            ->after('today'),
                    ])
                    ->action(function (array $data): void {
                        $upload = AgencyInsuranceResource::uploaded($data['file'] ?? null);

                        if ($upload === null) {
                            return;
                        }

                        ProfessionalResource::run(
                            fn () => app(ManageTeam::class)->depositDocument(
                                $this->professional(),
                                auth()->user(),
                                $data['type'],
                                $upload['contents'],
                                $upload['mime'],
                                $data['expires_at'] ?? null,
                            ),
                            __('admin.professionals.document_deposited'),
                        );
                    }),
            ])
            ->recordActions([
                Action::make('download')
                    ->label(__('admin.professionals.open_document'))
                    ->icon(Heroicon::OutlinedArrowDownTray)
                    ->visible(fn () => ProfessionalResource::mayVerify() || ProfessionalResource::mayManage())
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
     * La fiche du soignant, relue en base : son état décide de ce qui peut être déposé.
     */
    private function professional(): Professional
    {
        return Professional::query()->with('category')->findOrFail($this->getOwnerRecord()->getKey());
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
