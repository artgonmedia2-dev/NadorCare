<?php

namespace App\Filament\Widgets;

use App\Enums\BookingStatus;
use App\Enums\Permission;
use App\Filament\Resources\Bookings\BookingResource;
use App\Models\Booking;
use App\Models\Zone;
use App\Support\Translated;
use Filament\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

/**
 * Demandes qui attendent la coordination : à valider, à affecter, en attente de la
 * confirmation du soignant, ou à réaffecter. Les boutons sont ceux de la liste des demandes.
 */
class RequestsToHandle extends TableWidget
{
    /** Chargé avec la page : un tableau de bord qui clignote à l'ouverture se lit mal. */
    protected static bool $isLazy = false;

    protected int|string|array $columnSpan = 'full';

    /** @var array<string, string|null> */
    private array $zoneNames = [];

    public static function canView(): bool
    {
        return auth()->user()?->can(Permission::BookingsView->value) ?? false;
    }

    public function table(Table $table): Table
    {
        return $table
            ->heading(__('admin.dashboard.requests.title'))
            ->description(__('admin.dashboard.requests.help'))
            ->query(fn (): Builder => Booking::query()
                ->with(['service:id,name', 'patientProfile:id,first_name,last_name', 'professional.user:id,name'])
                ->where(fn (Builder $either) => $either
                    ->whereIn('status', [BookingStatus::Pending, BookingStatus::Confirmed])
                    ->orWhere(fn (Builder $waiting) => $waiting
                        ->where('status', BookingStatus::Assigned)
                        ->whereNull('assignment_confirmed_at'))))
            ->defaultSort('scheduled_at')
            ->paginated([8, 25])
            ->poll('30s')
            ->emptyStateHeading(__('admin.dashboard.requests.empty'))
            ->emptyStateIcon('heroicon-o-check-circle')
            ->columns([
                TextColumn::make('service')
                    ->label(__('admin.dashboard.requests.care'))
                    ->state(fn (Booking $record) => Translated::pick($record->service->name))
                    ->description(fn (Booking $record) => trim($record->patientProfile->first_name.' '.$record->patientProfile->last_name).' · '.$record->reference)
                    ->weight('semibold')
                    ->wrap(),
                TextColumn::make('scheduled_at')
                    ->label(__('admin.bookings.scheduled_at'))
                    ->dateTime('D d/m · H:i', (string) config('nadorcare.timezone'))
                    ->description(fn (Booking $record) => $this->zoneName($record))
                    ->weight('semibold'),
                TextColumn::make('professional.user.name')
                    ->label(__('admin.dashboard.requests.caregiver'))
                    ->placeholder(__('admin.dashboard.requests.not_assigned'))
                    ->weight('semibold'),
                TextColumn::make('answer')
                    ->label(__('admin.bookings.assignment.label'))
                    ->badge()
                    ->state(fn (Booking $record) => BookingResource::assignmentState($record)['label']
                        ?? BookingResource::statusOptions()[$record->status->value])
                    ->color(fn (Booking $record) => BookingResource::assignmentState($record)['color']
                        ?? ($record->status === BookingStatus::Pending ? 'gray' : 'warning'))
                    ->description(fn (Booking $record) => $record->wasDeclined() ? $record->assignment_decline_note : null)
                    ->wrap(),
            ])
            ->recordActions(array_values(array_filter(
                BookingResource::recordActions(),
                // L'annulation reste dans la liste des demandes : le tableau de bord sert à avancer.
                fn (Action $action) => $action->getName() !== 'cancel',
            )));
    }

    private function zoneName(Booking $booking): ?string
    {
        $zoneId = $booking->address_snapshot['zone_id'] ?? null;

        if ($zoneId === null) {
            return $booking->address_snapshot['city'] ?? null;
        }

        if (! array_key_exists($zoneId, $this->zoneNames)) {
            $zone = Zone::query()->find($zoneId, ['id', 'name']);
            $this->zoneNames[$zoneId] = $zone ? Translated::pick($zone->name) : null;
        }

        return $this->zoneNames[$zoneId];
    }
}
