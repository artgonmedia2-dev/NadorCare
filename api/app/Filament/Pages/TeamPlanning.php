<?php

namespace App\Filament\Pages;

use App\Enums\Permission;
use App\Services\Planning\TeamWeek;
use BackedEnum;
use Carbon\CarbonImmutable;
use Filament\Actions\Action;
use Filament\Pages\Page;
use Filament\Support\Icons\Heroicon;

/**
 * Planning global de l'équipe (modèle « agence ») : qui travaille quand, où, et sur quelles
 * missions. Lecture seule ; le planning d'un soignant se règle sur sa fiche.
 */
class TeamPlanning extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCalendarDays;

    protected static ?int $navigationSort = 2;

    protected static ?string $slug = 'planning';

    protected string $view = 'filament.pages.team-planning';

    /** Un jour de la semaine affichée, `AAAA-MM-JJ` (date de Nador). */
    public string $week = '';

    public static function canAccess(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsView->value) ?? false;
    }

    public static function getNavigationLabel(): string
    {
        return __('admin.planning.nav');
    }

    public function getTitle(): string
    {
        return __('admin.planning.nav');
    }

    public function mount(): void
    {
        $this->week = $this->today()->format('Y-m-d');
    }

    public function getSubheading(): ?string
    {
        return __('admin.planning.help');
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('previous')
                ->label(__('admin.planning.previous'))
                ->icon(Heroicon::OutlinedChevronLeft)
                ->color('gray')
                ->action(fn () => $this->shift(-7)),
            Action::make('today')
                ->label(__('admin.planning.today'))
                ->color('gray')
                ->action(fn () => $this->week = $this->today()->format('Y-m-d')),
            Action::make('next')
                ->label(__('admin.planning.next'))
                ->icon(Heroicon::OutlinedChevronRight)
                ->color('gray')
                ->action(fn () => $this->shift(7)),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    protected function getViewData(): array
    {
        $planning = app(TeamWeek::class)->build($this->current());

        return [
            'days' => $planning['days'],
            'rows' => $planning['rows'],
            'today' => $this->today()->format('Y-m-d'),
        ];
    }

    private function shift(int $days): void
    {
        $this->week = $this->current()->addDays($days)->format('Y-m-d');
    }

    private function current(): CarbonImmutable
    {
        // La propriété vient du navigateur : une valeur illisible ramène à la semaine en cours.
        $day = preg_match('/^\d{4}-\d{2}-\d{2}$/', $this->week) === 1
            ? CarbonImmutable::createFromFormat('!Y-m-d', $this->week, (string) config('nadorcare.timezone'))
            : null;

        return $day ?: $this->today();
    }

    private function today(): CarbonImmutable
    {
        return CarbonImmutable::now((string) config('nadorcare.timezone'))->startOfDay();
    }
}
