<?php

namespace App\Filament\Resources\ScheduleRequests;

use App\Actions\Professionals\ManagePlanning;
use App\Enums\Permission;
use App\Enums\ScheduleRequestKind;
use App\Enums\ScheduleRequestStatus;
use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Filament\Resources\ScheduleRequests\Pages\ListScheduleRequests;
use App\Models\ScheduleRequest;
use App\Services\Planning\TeamWeek;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * Demandes des soignants sur leur planning (modèle « agence ») : une nouvelle semaine type ou
 * une indisponibilité datée. La coordination accepte ou refuse ; la règle est dans `ManagePlanning`.
 */
class ScheduleRequestResource extends Resource
{
    protected static ?string $model = ScheduleRequest::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedClock;

    protected static ?int $navigationSort = 3;

    protected static ?string $slug = 'schedule-requests';

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

    public static function mayDecide(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsManage->value) ?? false;
    }

    public static function getNavigationLabel(): string
    {
        return __('admin.schedule_requests.nav');
    }

    public static function getModelLabel(): string
    {
        return __('admin.schedule_requests.label');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.schedule_requests.plural');
    }

    /**
     * Nombre de demandes sans réponse, affiché dans le menu.
     */
    public static function getNavigationBadge(): ?string
    {
        $pending = ScheduleRequest::query()->where('status', ScheduleRequestStatus::Pending)->count();

        return $pending > 0 ? (string) $pending : null;
    }

    /**
     * @return array<string, string>
     */
    public static function statusOptions(): array
    {
        $options = [];
        foreach (ScheduleRequestStatus::cases() as $status) {
            $options[$status->value] = __('admin.schedule_requests.statuses.'.$status->value);
        }

        return $options;
    }

    /**
     * Ce qui est demandé, en clair : les dates d'une indisponibilité, ou la semaine proposée.
     *
     * @return list<string>
     */
    public static function detail(ScheduleRequest $request): array
    {
        if ($request->kind === ScheduleRequestKind::Unavailability) {
            return [__('admin.schedule_requests.from_to', [
                'from' => $request->starts_on?->format('d/m/Y'),
                'to' => $request->ends_on?->format('d/m/Y'),
            ])];
        }

        return TeamWeek::describe($request->slots ?? []);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with('professional.user:id,name'))
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('professional.user.name')
                    ->label(__('admin.schedule_requests.caregiver'))
                    ->placeholder('—')
                    ->url(fn (ScheduleRequest $record) => ProfessionalResource::getUrl('view', ['record' => $record->professional_id])),
                TextColumn::make('kind')
                    ->label(__('admin.schedule_requests.kind'))
                    ->state(fn (ScheduleRequest $record) => __('admin.schedule_requests.kinds.'.$record->kind->value)),
                TextColumn::make('detail')
                    ->label(__('admin.schedule_requests.detail'))
                    ->state(fn (ScheduleRequest $record) => self::detail($record))
                    ->listWithLineBreaks(),
                TextColumn::make('note')
                    ->label(__('admin.schedule_requests.note'))
                    ->placeholder('—')
                    ->wrap(),
                TextColumn::make('status')
                    ->label(__('admin.schedule_requests.status'))
                    ->badge()
                    ->state(fn (ScheduleRequest $record) => self::statusOptions()[$record->status->value])
                    ->color(fn (ScheduleRequest $record) => match ($record->status) {
                        ScheduleRequestStatus::Pending => 'warning',
                        ScheduleRequestStatus::Accepted => 'success',
                        ScheduleRequestStatus::Refused => 'danger',
                        ScheduleRequestStatus::Cancelled => 'gray',
                    }),
                TextColumn::make('created_at')
                    ->label(__('admin.schedule_requests.received'))
                    ->dateTime('d/m/Y H:i', (string) config('nadorcare.timezone')),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label(__('admin.schedule_requests.status'))
                    ->options(self::statusOptions())
                    ->default(ScheduleRequestStatus::Pending->value),
            ])
            ->recordActions([
                Action::make('accept')
                    ->label(__('admin.schedule_requests.accept'))
                    ->icon(Heroicon::OutlinedCheck)
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalDescription(fn (ScheduleRequest $record) => $record->kind === ScheduleRequestKind::Weekly
                        ? __('admin.schedule_requests.accept_week')
                        : __('admin.schedule_requests.accept_off'))
                    ->visible(fn (ScheduleRequest $record) => self::mayDecide() && $record->status === ScheduleRequestStatus::Pending)
                    ->action(fn (ScheduleRequest $record) => ProfessionalResource::run(
                        fn () => app(ManagePlanning::class)->accept($record, auth()->user()),
                        __('admin.schedule_requests.accepted'),
                    )),
                Action::make('refuse')
                    ->label(__('admin.schedule_requests.refuse'))
                    ->icon(Heroicon::OutlinedXMark)
                    ->color('danger')
                    ->schema([
                        Textarea::make('reason')
                            ->label(__('admin.schedule_requests.refuse_reason'))
                            ->maxLength(500),
                    ])
                    ->visible(fn (ScheduleRequest $record) => self::mayDecide() && $record->status === ScheduleRequestStatus::Pending)
                    ->action(fn (ScheduleRequest $record, array $data) => ProfessionalResource::run(
                        fn () => app(ManagePlanning::class)->refuse($record, auth()->user(), $data['reason'] ?? null),
                        __('admin.schedule_requests.refused'),
                    )),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListScheduleRequests::route('/'),
        ];
    }
}
