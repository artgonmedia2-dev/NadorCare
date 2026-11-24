<?php

namespace App\Filament\Resources\Professionals;

use App\Actions\Professionals\ManagePlanning;
use App\Actions\Professionals\ManageTeam;
use App\Actions\Professionals\ReviewProfessional;
use App\Enums\Permission;
use App\Enums\VerificationStatus;
use App\Exceptions\ApiException;
use App\Filament\Resources\Professionals\Pages\CreateProfessional;
use App\Filament\Resources\Professionals\Pages\EditProfessional;
use App\Filament\Resources\Professionals\Pages\ListProfessionals;
use App\Filament\Resources\Professionals\Pages\ViewProfessional;
use App\Filament\Resources\Professionals\RelationManagers\DocumentsRelationManager;
use App\Models\Professional;
use App\Models\ProfessionalCategory;
use App\Models\ProfessionalDocument;
use App\Models\Zone;
use App\Services\Planning\TeamWeek;
use App\Support\Translated;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\CheckboxList;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\TimePicker;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

/**
 * Dossiers des professionnels (cahier des charges §6) : vérification des justificatifs,
 * validation, suspension, alertes d'expiration.
 *
 * Modèle « agence » : la coordination ajoute, modifie et invite les soignants de l'équipe ;
 * seul l'administrateur valide un dossier et suspend un compte.
 */
class ProfessionalResource extends Resource
{
    protected static ?string $model = Professional::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedIdentification;

    protected static ?int $navigationSort = 1;

    /** Nombre de jours avant l'expiration d'un justificatif à partir duquel le dossier est signalé. */
    public const EXPIRY_ALERT_DAYS = 30;

    public static function canAccess(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsView->value) ?? false;
    }

    public static function canCreate(): bool
    {
        return self::mayManage();
    }

    public static function canEdit(Model $record): bool
    {
        return self::mayManage();
    }

    public static function mayManage(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsManage->value) ?? false;
    }

    /**
     * Fiche d'un soignant : ce que l'agence saisit pour le faire entrer dans l'équipe.
     */
    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            Section::make(__('admin.professionals.label'))
                ->columns(2)
                ->schema([
                    TextInput::make('name')
                        ->label(__('admin.professionals.name'))
                        ->required()
                        ->minLength(2)
                        ->maxLength(120),
                    TextInput::make('phone')
                        ->label(__('admin.professionals.phone'))
                        ->helperText(__('admin.professionals.phone_help'))
                        ->tel()
                        ->required()
                        ->maxLength(20),
                    Select::make('professional_category_id')
                        ->label(__('admin.professionals.category'))
                        ->options(fn () => ProfessionalCategory::query()->where('is_active', true)->orderBy('code')->get()
                            ->mapWithKeys(fn (ProfessionalCategory $category) => [$category->id => Translated::pick($category->name)])
                            ->all())
                        ->required(),
                    TextInput::make('license_number')
                        ->label(__('admin.professionals.license_number'))
                        ->maxLength(60),
                    TextInput::make('order_number')
                        ->label(__('admin.professionals.order_number'))
                        ->maxLength(60),
                ]),
        ]);
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function mayVerify(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsVerify->value) ?? false;
    }

    public static function getNavigationLabel(): string
    {
        return __('admin.professionals.plural');
    }

    public static function getModelLabel(): string
    {
        return __('admin.professionals.label');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.professionals.plural');
    }

    /**
     * Nombre de dossiers en attente de vérification, affiché dans le menu.
     */
    public static function getNavigationBadge(): ?string
    {
        $waiting = Professional::query()
            ->whereIn('verification_status', [VerificationStatus::Submitted, VerificationStatus::UnderReview])
            ->count();

        return $waiting > 0 ? (string) $waiting : null;
    }

    /**
     * @return array<string, string>
     */
    public static function statusOptions(): array
    {
        $options = [];
        foreach (VerificationStatus::cases() as $status) {
            $options[$status->value] = __('admin.professionals.statuses.'.$status->value);
        }

        return $options;
    }

    public static function statusColor(VerificationStatus $status): string
    {
        return match ($status) {
            VerificationStatus::Verified => 'success',
            VerificationStatus::Submitted, VerificationStatus::UnderReview => 'warning',
            VerificationStatus::Rejected, VerificationStatus::Suspended => 'danger',
            VerificationStatus::Draft => 'gray',
        };
    }

    /**
     * Prochaine échéance parmi les justificatifs approuvés du dossier, ou `null` si aucun n'a
     * de date de fin de validité.
     */
    public static function nextExpiry(Professional $professional): ?string
    {
        return $professional->documents
            ->where('status', ProfessionalDocument::STATUS_APPROVED)
            ->whereNotNull('expires_at')
            ->sortBy('expires_at')
            ->first()?->expires_at?->format('d/m/Y');
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with(['user:id,name,phone', 'category:id,name', 'documents']))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label(__('admin.professionals.name'))
                    ->placeholder('—')
                    ->searchable(),
                TextColumn::make('user.phone')
                    ->label(__('admin.professionals.phone'))
                    ->searchable(),
                TextColumn::make('category')
                    ->label(__('admin.professionals.category'))
                    ->state(fn (Professional $record) => Translated::pick($record->category->name)),
                TextColumn::make('verification_status')
                    ->label(__('admin.professionals.status'))
                    ->badge()
                    ->state(fn (Professional $record) => self::statusOptions()[$record->verification_status->value])
                    ->color(fn (Professional $record) => self::statusColor($record->verification_status)),
                TextColumn::make('next_expiry')
                    ->label(__('admin.professionals.next_expiry'))
                    ->state(fn (Professional $record) => self::nextExpiry($record))
                    ->placeholder('—'),
            ])
            ->filters([
                SelectFilter::make('verification_status')
                    ->label(__('admin.professionals.status'))
                    ->options(self::statusOptions()),
                // Alerte d'expiration : un justificatif périmé, ou qui arrive à échéance.
                Filter::make('documents_expiring')
                    ->label(__('admin.professionals.documents_expiring', ['days' => self::EXPIRY_ALERT_DAYS]))
                    ->query(function (Builder $query): void {
                        $toRenew = ProfessionalDocument::query()->select('professional_documents.professional_id');
                        ProfessionalDocument::constrainToNeedsRenewal($toRenew, self::EXPIRY_ALERT_DAYS);

                        $query->whereIn('professionals.id', $toRenew);
                    }),
            ])
            ->recordActions([
                ViewAction::make(),
                EditAction::make(),
            ]);
    }

    /**
     * Actions sur le dossier, partagées par la liste et la fiche.
     *
     * @return list<Action>
     */
    public static function fileActions(): array
    {
        $waiting = [VerificationStatus::Submitted, VerificationStatus::UnderReview];

        return [
            EditAction::make()
                ->label(__('admin.professionals.edit'))
                ->visible(fn () => self::mayManage()),
            // L'invitation part par SMS : le soignant se connecte ensuite avec ce numéro.
            Action::make('invite')
                ->label(fn (Professional $record) => $record->invited_at === null
                    ? __('admin.professionals.invite')
                    : __('admin.professionals.invite_again'))
                ->icon(Heroicon::OutlinedPaperAirplane)
                ->requiresConfirmation()
                ->modalDescription(__('admin.professionals.invite_confirm'))
                ->visible(fn () => self::mayManage())
                ->action(fn (Professional $record) => self::run(
                    fn () => app(ManageTeam::class)->invite($record, auth()->user()),
                    __('admin.professionals.invited'),
                )),
            // Le planning est tenu par la coordination : zones et semaine type du soignant.
            Action::make('planning')
                ->label(__('admin.planning.set'))
                ->icon(Heroicon::OutlinedCalendarDays)
                ->visible(fn () => self::mayManage())
                ->modalHeading(__('admin.planning.set'))
                ->modalDescription(__('admin.planning.set_help'))
                ->fillForm(fn (Professional $record) => [
                    'zone_ids' => DB::table('professional_zone')->where('professional_id', $record->id)->pluck('zone_id')->all(),
                    'slots' => TeamWeek::slotsOf($record->id),
                ])
                ->schema([
                    CheckboxList::make('zone_ids')
                        ->label(__('admin.planning.zones'))
                        ->options(fn () => Zone::query()->where('is_active', true)->orderBy('sort')->get(['id', 'name'])
                            ->mapWithKeys(fn (Zone $zone) => [$zone->id => Translated::pick($zone->name)])
                            ->all())
                        ->columns(2),
                    Repeater::make('slots')
                        ->label(__('admin.planning.week'))
                        ->addActionLabel(__('admin.planning.add_slot'))
                        ->columns(3)
                        ->defaultItems(0)
                        ->reorderable(false)
                        ->schema([
                            Select::make('weekday')
                                ->label(__('admin.planning.day'))
                                ->options(TeamWeek::weekdayNames())
                                ->required(),
                            TimePicker::make('start_time')
                                ->label(__('admin.planning.from'))
                                ->seconds(false)
                                ->required(),
                            TimePicker::make('end_time')
                                ->label(__('admin.planning.to'))
                                ->seconds(false)
                                ->required(),
                        ]),
                ])
                ->action(fn (Professional $record, array $data) => self::run(
                    fn () => app(ManagePlanning::class)->set(
                        $record,
                        auth()->user(),
                        array_values($data['zone_ids'] ?? []),
                        array_values($data['slots'] ?? []),
                    ),
                    __('admin.planning.saved'),
                )),
            // L'agence a réuni les justificatifs : elle envoie le dossier à la vérification.
            Action::make('submit')
                ->label(__('admin.professionals.submit'))
                ->icon(Heroicon::OutlinedInboxArrowDown)
                ->requiresConfirmation()
                ->visible(fn (Professional $record) => self::mayManage()
                    && in_array($record->verification_status, [VerificationStatus::Draft, VerificationStatus::Rejected], true))
                ->action(fn (Professional $record) => self::run(
                    fn () => app(ManageTeam::class)->submitFile($record, auth()->user()),
                    __('admin.professionals.submitted'),
                )),
            Action::make('verify')
                ->label(__('admin.professionals.verify'))
                ->icon(Heroicon::OutlinedCheckBadge)
                ->color('success')
                ->requiresConfirmation()
                ->visible(fn (Professional $record) => self::mayVerify() && in_array($record->verification_status, $waiting, true))
                ->action(fn (Professional $record) => self::run(
                    fn () => app(ReviewProfessional::class)->verify($record, auth()->user()),
                    __('admin.professionals.verified'),
                )),
            Action::make('reject')
                ->label(__('admin.professionals.reject'))
                ->icon(Heroicon::OutlinedXMark)
                ->color('danger')
                ->schema([self::reasonField()])
                ->visible(fn (Professional $record) => self::mayVerify() && in_array($record->verification_status, $waiting, true))
                ->action(fn (Professional $record, array $data) => self::run(
                    fn () => app(ReviewProfessional::class)->reject($record, auth()->user(), $data['reason']),
                    __('admin.professionals.rejected'),
                )),
            Action::make('suspend')
                ->label(__('admin.professionals.suspend'))
                ->icon(Heroicon::OutlinedNoSymbol)
                ->color('danger')
                ->schema([self::reasonField()])
                ->visible(fn (Professional $record) => self::mayVerify() && $record->verification_status === VerificationStatus::Verified)
                ->action(fn (Professional $record, array $data) => self::run(
                    fn () => app(ReviewProfessional::class)->suspend($record, auth()->user(), $data['reason']),
                    __('admin.professionals.suspended'),
                )),
            Action::make('reinstate')
                ->label(__('admin.professionals.reinstate'))
                ->icon(Heroicon::OutlinedArrowPath)
                ->color('success')
                ->requiresConfirmation()
                ->visible(fn (Professional $record) => self::mayVerify() && $record->verification_status === VerificationStatus::Suspended)
                ->action(fn (Professional $record) => self::run(
                    fn () => app(ReviewProfessional::class)->reinstate($record, auth()->user()),
                    __('admin.professionals.reinstated'),
                )),
        ];
    }

    public static function reasonField(): Textarea
    {
        return Textarea::make('reason')
            ->label(__('admin.professionals.reason'))
            ->required()
            ->maxLength(500);
    }

    /**
     * Exécute une décision et affiche le résultat, y compris un refus métier.
     */
    public static function run(callable $decision, string $successMessage): void
    {
        try {
            $decision();
            Notification::make()->title($successMessage)->success()->send();
        } catch (ApiException $exception) {
            Notification::make()->title(__('api.errors.'.$exception->errorCode))->danger()->send();
        }
    }

    public static function getRelations(): array
    {
        return [DocumentsRelationManager::class];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListProfessionals::route('/'),
            'create' => CreateProfessional::route('/create'),
            'view' => ViewProfessional::route('/{record}'),
            'edit' => EditProfessional::route('/{record}/edit'),
        ];
    }
}
