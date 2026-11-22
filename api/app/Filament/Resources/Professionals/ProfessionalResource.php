<?php

namespace App\Filament\Resources\Professionals;

use App\Actions\Professionals\ReviewProfessional;
use App\Enums\Permission;
use App\Enums\VerificationStatus;
use App\Exceptions\ApiException;
use App\Filament\Resources\Professionals\Pages\ListProfessionals;
use App\Filament\Resources\Professionals\Pages\ViewProfessional;
use App\Filament\Resources\Professionals\RelationManagers\DocumentsRelationManager;
use App\Models\Professional;
use App\Models\ProfessionalDocument;
use App\Support\Translated;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * Dossiers des professionnels (cahier des charges §6) : vérification des justificatifs,
 * validation, suspension, alertes d'expiration.
 *
 * La coordination consulte ; seul l'administrateur vérifie et suspend.
 */
class ProfessionalResource extends Resource
{
    protected static ?string $model = Professional::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedIdentification;

    protected static ?int $navigationSort = 1;

    /** Nombre de jours avant l'expiration de l'assurance à partir duquel le dossier est signalé. */
    public const EXPIRY_ALERT_DAYS = 30;

    public static function canAccess(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsView->value) ?? false;
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit(Model $record): bool
    {
        return false;
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function mayVerify(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsVerify->value) ?? false;
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
     * Date de fin de validité de l'assurance approuvée, ou `null` s'il n'y en a pas.
     */
    public static function insuranceExpiry(Professional $professional): ?string
    {
        return $professional->documents
            ->where('type', ProfessionalDocument::TYPE_RC_INSURANCE)
            ->where('status', ProfessionalDocument::STATUS_APPROVED)
            ->sortByDesc('expires_at')
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
                TextColumn::make('insurance')
                    ->label(__('admin.professionals.insurance_until'))
                    ->state(fn (Professional $record) => self::insuranceExpiry($record))
                    ->placeholder('—'),
            ])
            ->filters([
                SelectFilter::make('verification_status')
                    ->label(__('admin.professionals.status'))
                    ->options(self::statusOptions()),
                // Alerte d'expiration : assurance approuvée qui arrive à échéance.
                Filter::make('insurance_expiring')
                    ->label(__('admin.professionals.insurance_expiring', ['days' => self::EXPIRY_ALERT_DAYS]))
                    ->query(fn (Builder $query) => $query->whereHas('documents', fn (Builder $document) => $document
                        ->where('type', ProfessionalDocument::TYPE_RC_INSURANCE)
                        ->where('status', ProfessionalDocument::STATUS_APPROVED)
                        ->whereDate('expires_at', '<=', today()->addDays(self::EXPIRY_ALERT_DAYS)))),
            ])
            ->recordActions([
                ViewAction::make(),
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
            'view' => ViewProfessional::route('/{record}'),
        ];
    }
}
