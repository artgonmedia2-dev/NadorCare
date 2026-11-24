<?php

namespace App\Filament\Resources\CaregiverAccounts;

use App\Actions\Finance\ManageCaregiverAccount;
use App\Enums\Permission;
use App\Enums\VerificationStatus;
use App\Filament\Resources\CaregiverAccounts\Pages\ListCaregiverAccounts;
use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Models\CaregiverRemuneration;
use App\Models\Professional;
use App\Services\Finance\CaregiverLedger;
use App\Support\Translated;
use BackedEnum;
use Carbon\CarbonImmutable;
use Filament\Actions\Action;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * Suivi financier de l'équipe (modèle « agence ») : pour chaque soignant et chaque mois, les
 * missions réalisées, les espèces encaissées pour l'agence, les espèces remises et la
 * rémunération due. Le comptable pointe les remises et saisit la rémunération ; rien n'est
 * calculé ni versé automatiquement.
 *
 * Aucune donnée de patient n'apparaît ici : le comptable n'y a pas droit.
 */
class CaregiverAccountResource extends Resource
{
    protected static ?string $model = Professional::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBanknotes;

    protected static ?int $navigationSort = 5;

    protected static ?string $slug = 'finance';

    /** Nombre de mois proposés dans le filtre, mois en cours compris. */
    private const MONTHS = 12;

    public static function canAccess(): bool
    {
        return auth()->user()?->can(Permission::FinancesView->value) ?? false;
    }

    public static function mayManage(): bool
    {
        return auth()->user()?->can(Permission::PayoutsManage->value) ?? false;
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

    public static function getModelLabel(): string
    {
        return __('admin.finance.label');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.finance.plural');
    }

    public static function getNavigationLabel(): string
    {
        return __('admin.finance.plural');
    }

    /**
     * @return Builder<Professional>
     */
    public static function getEloquentQuery(): Builder
    {
        // Un dossier refusé n'a jamais travaillé ; un compte suspendu peut encore devoir des espèces.
        return Professional::query()
            ->with(['user:id,name', 'category:id,name'])
            ->where('verification_status', '!=', VerificationStatus::Rejected);
    }

    /**
     * Mois proposés, du plus récent au plus ancien : `AAAA-MM` → « décembre 2026 ».
     *
     * @return array<string, string>
     */
    public static function periodOptions(): array
    {
        $month = CaregiverLedger::month(CaregiverLedger::currentPeriod());
        $options = [];

        for ($i = 0; $i < self::MONTHS; $i++) {
            $options[$month->format('Y-m')] = ucfirst($month->locale(app()->getLocale())->isoFormat('MMMM YYYY'));
            $month = $month->subMonth();
        }

        return $options;
    }

    /**
     * Mois choisi dans le filtre de la liste ; le mois en cours par défaut.
     */
    public static function periodOf(HasTable $livewire): string
    {
        $period = $livewire->getTableFilterState('period')['value'] ?? null;

        return is_string($period) && array_key_exists($period, self::periodOptions())
            ? $period
            : CaregiverLedger::currentPeriod();
    }

    public static function money(int $centimes): string
    {
        return number_format($centimes / 100, 2, ',', ' ');
    }

    /**
     * Montant saisi en dirhams (virgule ou point) → centimes.
     */
    public static function centimes(mixed $dirhams): int
    {
        return (int) round(((float) str_replace(',', '.', (string) $dirhams)) * 100);
    }

    public static function table(Table $table): Table
    {
        $figure = fn (string $key) => fn (Professional $record, HasTable $livewire): string => self::money(
            (int) app(CaregiverLedger::class)->summary($record->id, self::periodOf($livewire))[$key],
        );

        return $table
            ->defaultSort('created_at')
            ->columns([
                TextColumn::make('user.name')
                    ->label(__('admin.finance.caregiver'))
                    ->description(fn (Professional $record) => Translated::pick($record->category->name))
                    ->placeholder('—')
                    ->searchable(),
                TextColumn::make('missions')
                    ->label(__('admin.finance.missions'))
                    ->state(fn (Professional $record, HasTable $livewire) => app(CaregiverLedger::class)->summary($record->id, self::periodOf($livewire))['missions'])
                    ->alignEnd(),
                TextColumn::make('missions_value')
                    ->label(__('admin.finance.missions_value'))
                    ->state($figure('missions_value'))
                    ->alignEnd(),
                TextColumn::make('collected')
                    ->label(__('admin.finance.collected'))
                    ->state($figure('collected'))
                    ->alignEnd(),
                TextColumn::make('handed_over')
                    ->label(__('admin.finance.handed_over'))
                    ->state($figure('handed_over'))
                    ->alignEnd(),
                // Toutes périodes confondues : ce que le soignant doit encore remettre à l'agence.
                TextColumn::make('balance')
                    ->label(__('admin.finance.balance'))
                    ->state($figure('balance'))
                    ->badge()
                    ->color(fn (Professional $record) => app(CaregiverLedger::class)->balance($record->id) > 0 ? 'warning' : 'gray')
                    ->alignEnd(),
                TextColumn::make('remuneration')
                    ->label(__('admin.finance.remuneration'))
                    ->state(function (Professional $record, HasTable $livewire): ?string {
                        $amount = app(CaregiverLedger::class)->summary($record->id, self::periodOf($livewire))['remuneration'];

                        return $amount === null ? null : self::money($amount);
                    })
                    ->placeholder(__('admin.finance.not_set'))
                    ->alignEnd(),
            ])
            ->filters([
                // Le mois ne restreint pas la liste des soignants : il choisit les chiffres affichés.
                SelectFilter::make('period')
                    ->label(__('admin.finance.period'))
                    ->options(self::periodOptions())
                    ->default(CaregiverLedger::currentPeriod())
                    ->selectablePlaceholder(false)
                    ->query(fn (Builder $query) => $query),
            ])
            ->recordActions([
                Action::make('statement')
                    ->label(__('admin.finance.statement'))
                    ->icon(Heroicon::OutlinedDocumentText)
                    ->color('gray')
                    ->modalHeading(fn (Professional $record, HasTable $livewire) => __('admin.finance.statement_of', [
                        'name' => $record->user->name,
                        'month' => self::periodOptions()[self::periodOf($livewire)],
                    ]))
                    ->modalContent(function (Professional $record, HasTable $livewire) {
                        $ledger = app(CaregiverLedger::class);
                        $period = self::periodOf($livewire);

                        return view('filament.finance.statement', [
                            'summary' => $ledger->summary($record->id, $period),
                            'missions' => $ledger->missions($record->id, $period),
                            'handovers' => $ledger->handovers($record->id, $period),
                        ]);
                    })
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel(__('admin.finance.close')),
                // Le comptable pointe les espèces que le soignant vient de remettre.
                Action::make('handover')
                    ->label(__('admin.finance.handover'))
                    ->icon(Heroicon::OutlinedArrowDownOnSquare)
                    ->visible(fn (Professional $record) => self::mayManage() && app(CaregiverLedger::class)->balance($record->id) > 0)
                    ->modalDescription(fn (Professional $record) => __('admin.finance.handover_help', [
                        'amount' => self::money(app(CaregiverLedger::class)->balance($record->id)),
                    ]))
                    ->fillForm(fn (Professional $record) => [
                        'amount' => number_format(app(CaregiverLedger::class)->balance($record->id) / 100, 2, '.', ''),
                        'handed_on' => CarbonImmutable::now((string) config('nadorcare.timezone'))->format('Y-m-d'),
                    ])
                    ->schema([
                        TextInput::make('amount')
                            ->label(__('admin.finance.amount'))
                            ->numeric()
                            ->minValue(0.01)
                            ->required(),
                        DatePicker::make('handed_on')
                            ->label(__('admin.finance.handed_on'))
                            ->required(),
                        Textarea::make('note')
                            ->label(__('admin.finance.note'))
                            ->maxLength(500),
                    ])
                    ->action(fn (Professional $record, array $data) => ProfessionalResource::run(
                        fn () => app(ManageCaregiverAccount::class)->recordHandover(
                            $record,
                            auth()->user(),
                            self::centimes($data['amount']),
                            (string) $data['handed_on'],
                            $data['note'] ?? null,
                        ),
                        __('admin.finance.handover_recorded'),
                    )),
                // La rémunération due se saisit à la main, pour le mois affiché.
                Action::make('remuneration')
                    ->label(__('admin.finance.set_remuneration'))
                    ->icon(Heroicon::OutlinedPencilSquare)
                    ->visible(fn () => self::mayManage())
                    ->modalHeading(fn (Professional $record, HasTable $livewire) => __('admin.finance.remuneration_of', [
                        'name' => $record->user->name,
                        'month' => self::periodOptions()[self::periodOf($livewire)],
                    ]))
                    ->modalDescription(__('admin.finance.remuneration_help'))
                    ->fillForm(function (Professional $record, HasTable $livewire): array {
                        $current = CaregiverRemuneration::query()
                            ->where('professional_id', $record->id)
                            ->whereDate('period', CaregiverLedger::month(self::periodOf($livewire))->format('Y-m-d'))
                            ->first();

                        return [
                            'amount' => $current === null ? null : number_format($current->amount / 100, 2, '.', ''),
                            'note' => $current?->note,
                        ];
                    })
                    ->schema([
                        TextInput::make('amount')
                            ->label(__('admin.finance.amount'))
                            ->numeric()
                            ->minValue(0)
                            ->required(),
                        Textarea::make('note')
                            ->label(__('admin.finance.note'))
                            ->maxLength(500),
                    ])
                    ->action(fn (Professional $record, array $data, HasTable $livewire) => ProfessionalResource::run(
                        fn () => app(ManageCaregiverAccount::class)->setRemuneration(
                            $record,
                            auth()->user(),
                            self::periodOf($livewire),
                            self::centimes($data['amount']),
                            $data['note'] ?? null,
                        ),
                        __('admin.finance.remuneration_saved'),
                    )),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListCaregiverAccounts::route('/'),
        ];
    }
}
