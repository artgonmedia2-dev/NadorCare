<?php

namespace App\Filament\Widgets;

use App\Enums\BookingStatus;
use App\Enums\Permission;
use App\Models\Booking;
use App\Models\Service;
use App\Models\Zone;
use App\Support\Translated;
use Carbon\CarbonImmutable;
use Filament\Widgets\Widget;

/**
 * La journée de l'équipe, heure par heure : qui intervient, pour quel soin, où, et où en est
 * la mission. Aucune donnée de santé.
 */
class TodayMissions extends Widget
{
    /** Chargé avec la page : un tableau de bord qui clignote à l'ouverture se lit mal. */
    protected static bool $isLazy = false;

    protected string $view = 'filament.widgets.today-missions';

    public static function canView(): bool
    {
        return auth()->user()?->can(Permission::BookingsView->value) ?? false;
    }

    /**
     * @return array<string, mixed>
     */
    protected function getViewData(): array
    {
        $timezone = (string) config('nadorcare.timezone');
        $today = CarbonImmutable::now($timezone)->startOfDay();

        $bookings = Booking::query()
            ->with('professional.user:id,name')
            ->where('scheduled_at', '>=', $today->utc())
            ->where('scheduled_at', '<', $today->addDay()->utc())
            ->whereNotIn('status', [BookingStatus::Cancelled])
            ->orderBy('scheduled_at')
            ->limit(12)
            ->get(['id', 'service_id', 'professional_id', 'status', 'scheduled_at', 'address_snapshot', 'assignment_confirmed_at', 'assignment_declined_at']);

        $services = Service::query()->withTrashed()->whereIn('id', $bookings->pluck('service_id')->unique()->all())
            ->get(['id', 'name'])->mapWithKeys(fn (Service $s) => [$s->id => Translated::pick($s->name)]);
        $zones = Zone::query()->get(['id', 'name'])->mapWithKeys(fn (Zone $z) => [$z->id => Translated::pick($z->name)]);

        return [
            'missions' => $bookings->map(fn (Booking $booking) => [
                'time' => CarbonImmutable::instance($booking->scheduled_at)->setTimezone($timezone)->format('H:i'),
                'who' => $booking->professional?->user?->name,
                'what' => collect([$services[$booking->service_id] ?? null, $zones[$booking->address_snapshot['zone_id'] ?? ''] ?? null])->filter()->implode(' · '),
                ...$this->state($booking),
            ])->all(),
        ];
    }

    /**
     * @return array{label: string, color: string}
     */
    private function state(Booking $booking): array
    {
        if ($booking->awaitsConfirmation()) {
            return ['label' => __('admin.bookings.assignment.waiting'), 'color' => 'warning'];
        }

        return [
            'label' => __('admin.bookings.statuses.'.$booking->status->value),
            'color' => match ($booking->status) {
                BookingStatus::Pending, BookingStatus::Confirmed => 'warning',
                BookingStatus::EnRoute, BookingStatus::InProgress => 'info',
                BookingStatus::Completed => 'gray',
                BookingStatus::Disputed => 'danger',
                default => 'primary',
            },
        ];
    }
}
