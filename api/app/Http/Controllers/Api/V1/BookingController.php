<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Bookings\CancelBooking;
use App\Actions\Bookings\CreateBooking;
use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreBookingRequest;
use App\Http\Resources\Api\V1\BookingResource;
use App\Models\Booking;
use App\Models\Service;
use App\Services\Bookings\BookingSchedule;
use App\Services\Bookings\PriceCalculator;
use App\Services\Health\AccessLogger;
use App\Support\Translated;
use Carbon\CarbonImmutable;
use Dedoc\Scramble\Attributes\Group;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

#[Group('Réservations', weight: 6)]
class BookingController extends Controller
{
    private const RELATIONS = ['service:id,slug,name', 'patientProfile:id,first_name,last_name'];

    /**
     * Créneaux réservables
     *
     * Débuts de créneau encore disponibles pour un service, un jour donné (heure de Nador).
     * La liste est vide si le jour est passé, trop lointain, ou si les horaires sont dépassés.
     */
    public function slots(Request $request, BookingSchedule $schedule): JsonResponse
    {
        $input = $request->validate([
            'service_id' => ['required', 'string'],
            // Jour voulu, au format `AAAA-MM-JJ`.
            'date' => ['required', 'date_format:Y-m-d'],
        ]);

        $service = $this->activeService($input['service_id']);

        return response()->json([
            'data' => [
                'date' => $input['date'],
                'timezone' => $schedule->timezone(),
                /** @var list<string> */
                'slots' => array_map(
                    fn (CarbonImmutable $slot) => $slot->toIso8601String(),
                    $schedule->slotsFor($input['date'], $service),
                ),
                /** Une demande « dès que possible » est acceptée en ce moment. */
                'immediate_available' => $schedule->isOpenNow($service),
            ],
        ]);
    }

    /**
     * Devis
     *
     * Prix d'un soin à un créneau donné, avec les majorations qui s'appliquent.
     */
    public function quote(Request $request, PriceCalculator $prices): JsonResponse
    {
        $input = $request->validate([
            'service_id' => ['required', 'string'],
            // Début du créneau. Absent : le prix est calculé pour maintenant.
            'scheduled_at' => ['sometimes', 'nullable', 'date'],
        ]);

        $quote = $prices->quote(
            $this->activeService($input['service_id']),
            isset($input['scheduled_at']) ? CarbonImmutable::parse($input['scheduled_at']) : CarbonImmutable::now(),
        );

        return response()->json([
            'data' => [
                'base' => $quote->base,
                /** @var list<array{label: string|null, amount: int}> */
                'surcharges' => array_map(fn (array $line) => [
                    'label' => Translated::pick($line['name']),
                    'amount' => $line['amount'],
                ], $quote->surcharges),
                'total' => $quote->total(),
                'currency' => 'MAD',
            ],
        ]);
    }

    /**
     * Mes réservations
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $input = $request->validate([
            // `upcoming` (à venir ou en cours, par défaut) ou `past` (terminées et annulées).
            'scope' => ['sometimes', Rule::in(['upcoming', 'past'])],
        ]);

        $closed = [BookingStatus::Completed, BookingStatus::Cancelled];
        $past = ($input['scope'] ?? 'upcoming') === 'past';

        return BookingResource::collection(
            $request->user()->bookings()
                ->with(self::RELATIONS)
                ->when($past, fn ($query) => $query->whereIn('status', $closed)->orderByDesc('scheduled_at'))
                ->when(! $past, fn ($query) => $query->whereNotIn('status', $closed)->orderBy('scheduled_at'))
                ->limit(100)
                ->get()
        );
    }

    /**
     * Réserver un soin
     *
     * La demande est créée « en attente » : la coordination la confirme ensuite.
     * Seul le paiement en espèces est ouvert pour l'instant.
     */
    public function store(StoreBookingRequest $request, CreateBooking $create): JsonResponse
    {
        $booking = $create->handle($request->user(), $request->validated());

        return (new BookingResource($booking->load([...self::RELATIONS, 'statusHistory'])))
            ->detailed()->response()->setStatusCode(201);
    }

    /**
     * Détail d'une réservation
     *
     * Renvoie aussi la note du patient et l'historique des statuts. Cette lecture est
     * inscrite au journal des accès.
     */
    public function show(Request $request, string $booking, AccessLogger $logger): BookingResource
    {
        $found = $this->find($request, $booking)->load([...self::RELATIONS, 'statusHistory']);
        $logger->record(AccessAction::View, $found, $found->patient_profile_id, $found->id, $request->user());

        return (new BookingResource($found))->detailed();
    }

    /**
     * Annuler une réservation
     *
     * Gratuit jusqu'à `free_cancellation_until`, avec des frais au-delà.
     */
    public function cancel(Request $request, string $booking, CancelBooking $cancel): BookingResource
    {
        $input = $request->validate(['reason' => ['sometimes', 'nullable', 'string', 'max:500']]);

        $cancelled = $cancel->handle($this->find($request, $booking), $request->user(), $input['reason'] ?? null);

        return (new BookingResource($cancelled->load([...self::RELATIONS, 'statusHistory'])))->detailed();
    }

    private function find(Request $request, string $id): Booking
    {
        return $request->user()->bookings()->findOrFail($id);
    }

    private function activeService(string $id): Service
    {
        $service = Service::query()->with('category')->find($id);

        if (! $service || ! $service->is_active || ! $service->category->is_active) {
            throw new ApiException('service_unavailable');
        }

        return $service;
    }
}
