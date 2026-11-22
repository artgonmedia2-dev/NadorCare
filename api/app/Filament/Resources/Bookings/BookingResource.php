<?php

namespace App\Filament\Resources\Bookings;

use App\Actions\Assignment\AssignProfessional;
use App\Actions\Assignment\OfferMission;
use App\Actions\Assignment\UnassignProfessional;
use App\Actions\Bookings\CancelBooking;
use App\Actions\Bookings\TransitionBooking;
use App\Enums\BookingStatus;
use App\Enums\Permission;
use App\Exceptions\ApiException;
use App\Filament\Resources\Bookings\Pages\ListBookings;
use App\Models\Booking;
use App\Models\Professional;
use App\Services\Assignment\ProfessionalMatcher;
use App\Support\Translated;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * File des demandes de soin. Le coordinateur confirme une demande en attente ou l'annule ;
 * l'affectation d'un professionnel viendra avec la tâche 6.2.
 *
 * La liste ne montre aucune donnée de santé (ni note du patient, ni ordonnance).
 * Les changements de statut passent par les mêmes actions que l'API.
 */
class BookingResource extends Resource
{
    protected static ?string $model = Booking::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedInboxArrowDown;

    protected static ?int $navigationSort = 0;

    public static function canAccess(): bool
    {
        return auth()->user()?->can(Permission::BookingsView->value) ?? false;
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function getModelLabel(): string
    {
        return __('admin.bookings.label');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.bookings.plural');
    }

    /**
     * Nombre de demandes à valider, affiché dans le menu.
     */
    public static function getNavigationBadge(): ?string
    {
        $pending = Booking::query()->where('status', BookingStatus::Pending)->count();

        return $pending > 0 ? (string) $pending : null;
    }

    /**
     * @return array<string, string>
     */
    public static function statusOptions(): array
    {
        $options = [];
        foreach (BookingStatus::cases() as $status) {
            $options[$status->value] = __('admin.bookings.statuses.'.$status->value);
        }

        return $options;
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with(['service:id,name', 'patientProfile:id,first_name,last_name', 'user:id,phone', 'professional.user:id,name']))
            ->defaultSort('scheduled_at')
            ->columns([
                TextColumn::make('reference')
                    ->label(__('admin.bookings.reference'))
                    ->searchable(),
                TextColumn::make('status')
                    ->label(__('admin.bookings.status'))
                    ->badge()
                    ->state(fn (Booking $record) => self::statusOptions()[$record->status->value])
                    ->color(fn (Booking $record) => match ($record->status) {
                        BookingStatus::Pending => 'warning',
                        BookingStatus::Cancelled, BookingStatus::Disputed => 'danger',
                        BookingStatus::Completed => 'gray',
                        default => 'success',
                    }),
                TextColumn::make('scheduled_at')
                    ->label(__('admin.bookings.scheduled_at'))
                    ->dateTime('d/m/Y H:i', (string) config('nadorcare.timezone'))
                    ->sortable(),
                TextColumn::make('service')
                    ->label(__('admin.bookings.service'))
                    ->state(fn (Booking $record) => Translated::pick($record->service->name)),
                TextColumn::make('patient')
                    ->label(__('admin.bookings.patient'))
                    ->state(fn (Booking $record) => trim($record->patientProfile->first_name.' '.$record->patientProfile->last_name)),
                TextColumn::make('professional.user.name')
                    ->label(__('admin.bookings.professional'))
                    ->placeholder('—'),
                TextColumn::make('user.phone')
                    ->label(__('admin.bookings.phone')),
                TextColumn::make('address')
                    ->label(__('admin.bookings.address'))
                    ->state(fn (Booking $record) => $record->address_snapshot['line'] ?? null)
                    ->wrap(),
                TextColumn::make('total_price')
                    ->label(__('admin.bookings.price'))
                    ->state(fn (Booking $record) => number_format($record->total_price / 100, 2, ',', ' ')),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label(__('admin.bookings.status'))
                    ->options(self::statusOptions())
                    ->default(BookingStatus::Pending->value),
            ])
            ->recordActions([
                Action::make('confirm')
                    ->label(__('admin.bookings.confirm'))
                    ->icon(Heroicon::OutlinedCheck)
                    ->color('success')
                    ->requiresConfirmation()
                    ->visible(fn (Booking $record) => $record->status === BookingStatus::Pending
                        && (auth()->user()?->can(Permission::BookingsConfirm->value) ?? false))
                    ->action(fn (Booking $record) => self::run(
                        fn () => app(TransitionBooking::class)->handle($record, BookingStatus::Confirmed, auth()->user()),
                        __('admin.bookings.confirmed'),
                    )),
                // Affectation directe : la coordination désigne le soignant sans attendre sa réponse.
                Action::make('assign')
                    ->label(__('admin.bookings.assign'))
                    ->icon(Heroicon::OutlinedUserPlus)
                    ->color('primary')
                    ->schema(fn (Booking $record) => [self::candidateSelect($record)])
                    ->visible(fn (Booking $record) => $record->status === BookingStatus::Confirmed && self::mayAssign())
                    ->action(fn (Booking $record, array $data) => self::run(
                        fn () => app(AssignProfessional::class)->handle($record, Professional::query()->findOrFail($data['professional_id']), auth()->user()),
                        __('admin.bookings.assigned'),
                    )),
                // Proposition : le soignant a un délai pour accepter ou refuser dans son application.
                Action::make('offer')
                    ->label(__('admin.bookings.offer'))
                    ->icon(Heroicon::OutlinedPaperAirplane)
                    ->color('gray')
                    ->schema(fn (Booking $record) => [self::candidateSelect($record)])
                    ->visible(fn (Booking $record) => $record->status === BookingStatus::Confirmed && self::mayAssign())
                    ->action(fn (Booking $record, array $data) => self::run(
                        fn () => app(OfferMission::class)->handle($record, Professional::query()->findOrFail($data['professional_id']), auth()->user()),
                        __('admin.bookings.offered'),
                    )),
                Action::make('unassign')
                    ->label(__('admin.bookings.unassign'))
                    ->icon(Heroicon::OutlinedArrowUturnLeft)
                    ->color('warning')
                    ->schema([
                        Textarea::make('reason')
                            ->label(__('admin.bookings.unassign_reason'))
                            ->required()
                            ->maxLength(500),
                    ])
                    ->visible(fn (Booking $record) => in_array($record->status, [BookingStatus::Assigned, BookingStatus::EnRoute], true) && self::mayAssign())
                    ->action(fn (Booking $record, array $data) => self::run(
                        fn () => app(UnassignProfessional::class)->handle($record, auth()->user(), $data['reason']),
                        __('admin.bookings.unassigned'),
                    )),
                Action::make('cancel')
                    ->label(__('admin.bookings.cancel'))
                    ->icon(Heroicon::OutlinedXMark)
                    ->color('danger')
                    ->schema([
                        Textarea::make('reason')
                            ->label(__('admin.bookings.cancel_reason'))
                            ->required()
                            ->maxLength(500),
                    ])
                    ->visible(fn (Booking $record) => $record->status->canTransitionTo(BookingStatus::Cancelled)
                        && (auth()->user()?->can(Permission::BookingsCancel->value) ?? false))
                    ->action(fn (Booking $record, array $data) => self::run(
                        fn () => app(CancelBooking::class)->handle($record, auth()->user(), $data['reason']),
                        __('admin.bookings.cancelled'),
                    )),
            ]);
    }

    private static function mayAssign(): bool
    {
        return auth()->user()?->can(Permission::BookingsAssign->value) ?? false;
    }

    /**
     * Liste des professionnels qui peuvent prendre la réservation, les mieux placés d'abord
     * (zone couverte, disponibilité, distance, note). Seuls les éligibles y figurent.
     */
    private static function candidateSelect(Booking $booking): Select
    {
        $options = [];

        foreach (app(ProfessionalMatcher::class)->candidatesFor($booking) as $candidate) {
            $details = array_filter([
                $candidate->distanceMeters === null ? null : number_format($candidate->distanceMeters / 1000, 1, ',', ' ').' km',
                $candidate->coversZone ? __('admin.bookings.candidate.covers_zone') : __('admin.bookings.candidate.outside_zone'),
                $candidate->available ? __('admin.bookings.candidate.available') : __('admin.bookings.candidate.unavailable'),
                $candidate->rating === null ? null : number_format($candidate->rating, 1, ',', ' ').' / 5',
            ]);

            $options[$candidate->professional->id] = ($candidate->professional->user->name ?? $candidate->professional->user->phone)
                .' — '.implode(' · ', $details);
        }

        return Select::make('professional_id')
            ->label(__('admin.bookings.professional'))
            ->helperText($options === [] ? __('admin.bookings.candidate.none') : __('admin.bookings.candidate.help'))
            ->options($options)
            ->required();
    }

    /**
     * Exécute un changement de statut et affiche le résultat, y compris un refus métier.
     */
    private static function run(callable $change, string $successMessage): void
    {
        try {
            $change();
            Notification::make()->title($successMessage)->success()->send();
        } catch (ApiException $exception) {
            Notification::make()->title(__('api.errors.'.$exception->errorCode))->danger()->send();
        }
    }

    public static function getPages(): array
    {
        return [
            'index' => ListBookings::route('/'),
        ];
    }
}
