<?php

namespace App\Filament\Resources\Bookings;

use App\Actions\Bookings\CancelBooking;
use App\Actions\Bookings\TransitionBooking;
use App\Enums\BookingStatus;
use App\Enums\Permission;
use App\Exceptions\ApiException;
use App\Filament\Resources\Bookings\Pages\ListBookings;
use App\Models\Booking;
use App\Support\Translated;
use BackedEnum;
use Filament\Actions\Action;
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
            ->modifyQueryUsing(fn (Builder $query) => $query->with(['service:id,name', 'patientProfile:id,first_name,last_name', 'user:id,phone']))
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
