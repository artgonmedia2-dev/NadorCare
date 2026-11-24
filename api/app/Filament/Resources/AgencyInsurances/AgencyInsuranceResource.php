<?php

namespace App\Filament\Resources\AgencyInsurances;

use App\Actions\Agency\ManageAgencyInsurance;
use App\Enums\Permission;
use App\Filament\Resources\AgencyInsurances\Pages\ListAgencyInsurances;
use App\Models\AgencyInsurance;
use App\Services\Files\EncryptedFileStore;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;
use Livewire\Features\SupportFileUploads\TemporaryUploadedFile;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Assurance de l'agence : contrat, échéance, attestation. La coordination la consulte,
 * l'administrateur la tient à jour ; le menu alerte quand l'échéance approche.
 */
class AgencyInsuranceResource extends Resource
{
    protected static ?string $model = AgencyInsurance::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedShieldCheck;

    protected static ?int $navigationSort = 4;

    protected static ?string $slug = 'agency-insurance';

    public static function canAccess(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsView->value) ?? false;
    }

    public static function mayManage(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsVerify->value) ?? false;
    }

    public static function canCreate(): bool
    {
        return self::mayManage();
    }

    public static function canEdit(Model $record): bool
    {
        return self::mayManage();
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function getNavigationLabel(): string
    {
        return __('admin.agency_insurance.plural');
    }

    public static function getModelLabel(): string
    {
        return __('admin.agency_insurance.label');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.agency_insurance.plural');
    }

    /**
     * Alerte dans le menu : aucun contrat valable au-delà du délai d'alerte.
     */
    public static function getNavigationBadge(): ?string
    {
        return AgencyInsurance::needsAttention() ? '!' : null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'danger';
    }

    public static function getNavigationBadgeTooltip(): ?string
    {
        return __('admin.agency_insurance.alert', ['days' => AgencyInsurance::ALERT_DAYS]);
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('insurer')
                ->label(__('admin.agency_insurance.insurer'))
                ->required()
                ->maxLength(120),
            TextInput::make('policy_number')
                ->label(__('admin.agency_insurance.policy_number'))
                ->required()
                ->maxLength(80),
            DatePicker::make('expires_on')
                ->label(__('admin.agency_insurance.expires_on'))
                ->required(),
            // Le fichier n'est pas rangé par Filament : il est chiffré par `ManageAgencyInsurance`.
            FileUpload::make('attestation')
                ->label(__('admin.agency_insurance.attestation'))
                ->helperText(__('admin.agency_insurance.attestation_help'))
                ->acceptedFileTypes(['application/pdf', 'image/jpeg', 'image/png'])
                ->maxSize(10240)
                ->storeFiles(false),
        ]);
    }

    /**
     * Enregistre le formulaire par l'action métier.
     *
     * @param  array<string, mixed>  $data
     */
    public static function save(?AgencyInsurance $insurance, array $data): AgencyInsurance
    {
        return app(ManageAgencyInsurance::class)->save(
            $insurance,
            auth()->user(),
            ['insurer' => $data['insurer'], 'policy_number' => $data['policy_number'], 'expires_on' => $data['expires_on']],
            self::uploaded($data['attestation'] ?? null),
        );
    }

    /**
     * Contenu et type du fichier reçu du formulaire, ou `null` s'il n'y en a pas.
     *
     * @return array{contents: string, mime: string}|null
     */
    public static function uploaded(mixed $upload): ?array
    {
        $upload = is_array($upload) ? reset($upload) : $upload;

        if (! $upload instanceof TemporaryUploadedFile) {
            return null;
        }

        return ['contents' => (string) $upload->get(), 'mime' => (string) $upload->getMimeType()];
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('expires_on', 'desc')
            ->columns([
                TextColumn::make('insurer')
                    ->label(__('admin.agency_insurance.insurer')),
                TextColumn::make('policy_number')
                    ->label(__('admin.agency_insurance.policy_number')),
                TextColumn::make('expires_on')
                    ->label(__('admin.agency_insurance.expires_on'))
                    ->date('d/m/Y')
                    ->badge()
                    ->color(fn (AgencyInsurance $record) => match (true) {
                        $record->expires_on->isBefore(today()) => 'danger',
                        $record->expires_on->isBefore(today()->addDays(AgencyInsurance::ALERT_DAYS + 1)) => 'warning',
                        default => 'success',
                    }),
                TextColumn::make('state')
                    ->label(__('admin.agency_insurance.state'))
                    ->state(fn (AgencyInsurance $record) => match (true) {
                        $record->expires_on->isBefore(today()) => __('admin.agency_insurance.expired'),
                        $record->expires_on->isBefore(today()->addDays(AgencyInsurance::ALERT_DAYS + 1)) => __('admin.agency_insurance.expiring'),
                        default => __('admin.agency_insurance.valid'),
                    }),
            ])
            ->recordActions([
                Action::make('download')
                    ->label(__('admin.agency_insurance.open'))
                    ->icon(Heroicon::OutlinedArrowDownTray)
                    ->visible(fn (AgencyInsurance $record) => $record->file_id !== null)
                    ->action(fn (AgencyInsurance $record) => self::download($record)),
                EditAction::make()
                    ->using(fn (AgencyInsurance $record, array $data) => self::save($record, $data)),
            ]);
    }

    /**
     * Déchiffre l'attestation et l'envoie au navigateur. La lecture est inscrite au journal des accès.
     */
    private static function download(AgencyInsurance $insurance): StreamedResponse
    {
        $file = $insurance->file()->firstOrFail();
        $contents = app(EncryptedFileStore::class)->read($file, auth()->user());

        $extension = match ($file->mime) {
            'application/pdf' => 'pdf',
            'image/png' => 'png',
            default => 'jpg',
        };

        return response()->streamDownload(
            fn () => print ($contents),
            'assurance-agence-'.$insurance->id.'.'.$extension,
            ['Content-Type' => $file->mime],
        );
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAgencyInsurances::route('/'),
        ];
    }
}
