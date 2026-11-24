<?php

namespace App\Filament\Widgets;

use App\Enums\Permission;
use App\Enums\ScheduleRequestStatus;
use App\Filament\Resources\AgencyInsurances\AgencyInsuranceResource;
use App\Filament\Resources\Professionals\ProfessionalResource;
use App\Filament\Resources\ScheduleRequests\ScheduleRequestResource;
use App\Models\AgencyInsurance;
use App\Models\ProfessionalDocument;
use App\Models\ScheduleRequest;
use Filament\Widgets\Widget;

/**
 * Ce que la coordination doit surveiller sans urgence immédiate : l'assurance de l'agence,
 * les justificatifs qui arrivent à échéance, les demandes de planning des soignants.
 */
class Watchlist extends Widget
{
    /** Chargé avec la page : un tableau de bord qui clignote à l'ouverture se lit mal. */
    protected static bool $isLazy = false;

    protected string $view = 'filament.widgets.watchlist';

    public static function canView(): bool
    {
        return auth()->user()?->can(Permission::ProfessionalsView->value) ?? false;
    }

    /**
     * @return array<string, mixed>
     */
    protected function getViewData(): array
    {
        $items = [];

        if (AgencyInsurance::needsAttention()) {
            $latest = AgencyInsurance::query()->orderByDesc('expires_on')->first();
            $items[] = [
                'tone' => $latest && ! $latest->expires_on->isPast() ? 'warning' : 'danger',
                'icon' => 'shield',
                'title' => __('admin.dashboard.watch.insurance'),
                'hint' => $latest && ! $latest->expires_on->isPast()
                    ? __('admin.dashboard.watch.insurance_soon', ['date' => $latest->expires_on->format('d/m/Y')])
                    : __('admin.dashboard.watch.insurance_none'),
                'url' => AgencyInsuranceResource::getUrl('index'),
            ];
        }

        $documents = ProfessionalDocument::query()->with('professional.user:id,name');
        ProfessionalDocument::constrainToNeedsRenewal($documents, ProfessionalResource::EXPIRY_ALERT_DAYS);
        $documents = $documents->orderBy('expires_at')->get();
        if ($documents->isNotEmpty()) {
            $first = $documents->first();
            $items[] = [
                'tone' => 'danger',
                'icon' => 'file',
                'title' => trans_choice('admin.dashboard.watch.documents', $documents->count(), ['count' => $documents->count()]),
                'hint' => __('admin.dashboard.watch.documents_first', [
                    'type' => __('admin.professionals.document_types.'.$first->type),
                    'name' => $first->professional->user->name ?? '—',
                    'date' => $first->expires_at?->format('d/m/Y'),
                ]),
                'url' => ProfessionalResource::getUrl('index'),
            ];
        }

        $requests = ScheduleRequest::query()->where('status', ScheduleRequestStatus::Pending)->count();
        if ($requests > 0) {
            $items[] = [
                'tone' => 'brand',
                'icon' => 'clock',
                'title' => trans_choice('admin.dashboard.watch.schedule', $requests, ['count' => $requests]),
                'hint' => __('admin.dashboard.watch.schedule_help'),
                'url' => ScheduleRequestResource::getUrl('index'),
            ];
        }

        return ['items' => $items];
    }
}
