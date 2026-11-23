<?php

namespace App\Actions\Bookings;

use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Address;
use App\Models\Booking;
use App\Models\File;
use App\Models\PatientProfile;
use App\Models\Service;
use App\Models\User;
use App\Services\Bookings\BookingSchedule;
use App\Services\Bookings\PriceCalculator;
use App\Services\Settings\Settings;
use App\Support\Translated;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * Crée une demande de soin. Elle naît « en attente » : c'est la coordination qui la confirme.
 *
 * Règles vérifiées (cahier des charges §4) : le service est proposé, l'adresse est dans une
 * zone ouverte, le créneau est réservable, l'ordonnance est déposée si le soin l'exige.
 * Le prix est figé au moment de la demande.
 */
class CreateBooking
{
    public function __construct(
        private readonly BookingSchedule $schedule,
        private readonly PriceCalculator $prices,
        private readonly Settings $settings,
    ) {}

    /**
     * @param  array{service_id: string, patient_profile_id: string, address_id: string, type: string, scheduled_at?: string|null, payment_method: string, patient_note?: string|null, prescription_file_id?: string|null}  $data
     */
    public function handle(User $booker, array $data, string $channel = 'app', ?User $createdBy = null): Booking
    {
        $service = Service::query()->with('category')->find($data['service_id']);

        if (! $service || ! $service->is_active || ! $service->category->is_active) {
            throw new ApiException('service_unavailable');
        }

        if ($service->isRemote()) {
            if (! $this->settings->bool(Settings::TELECONSULTATION_ENABLED)) {
                throw new ApiException('teleconsultation_unavailable');
            }

            // Personne n'est sur place pour encaisser : une téléconsultation se règle par carte.
            if ($data['payment_method'] === 'cash') {
                throw new ApiException('teleconsultation_requires_card');
            }
        }

        // Seul le paiement en espèces est ouvert tant que le contrat de paiement en ligne n'est pas signé.
        if ($data['payment_method'] !== 'cash') {
            throw new ApiException('payment_method_unavailable');
        }

        $profile = PatientProfile::query()->where('user_id', $booker->getKey())->findOrFail($data['patient_profile_id']);
        $address = Address::query()->with('zone')->where('user_id', $booker->getKey())->findOrFail($data['address_id']);

        if (! $address->zone?->is_active) {
            throw new ApiException('address_not_covered');
        }

        $scheduledAt = $this->resolveSlot($service, $data['type'], $data['scheduled_at'] ?? null);
        $prescription = $this->resolvePrescription($booker, $service, $data['prescription_file_id'] ?? null);
        $quote = $this->prices->quote($service, $scheduledAt);

        return DB::transaction(function () use ($booker, $createdBy, $channel, $data, $service, $profile, $address, $scheduledAt, $prescription, $quote) {
            // Verrou sur le profil : deux envois simultanés de la même demande ne passent pas tous les deux.
            PatientProfile::query()->whereKey($profile->getKey())->lockForUpdate()->first();

            $duplicate = Booking::query()
                ->where('patient_profile_id', $profile->getKey())
                ->where('service_id', $service->getKey())
                ->where('scheduled_at', $scheduledAt)
                ->whereNotIn('status', [BookingStatus::Cancelled, BookingStatus::Completed])
                ->exists();

            if ($duplicate) {
                throw new ApiException('booking_duplicate', 409);
            }

            $booking = new Booking([
                'reference' => $this->nextReference(),
                'user_id' => $booker->getKey(),
                'patient_profile_id' => $profile->getKey(),
                'address_id' => $address->getKey(),
                'address_snapshot' => [
                    'label' => $address->label,
                    'line' => $address->line,
                    'city' => $address->city,
                    'latitude' => $address->location->getLatitude(),
                    'longitude' => $address->location->getLongitude(),
                    'access_notes' => $address->access_notes,
                    'zone_id' => $address->zone_id,
                ],
                'service_id' => $service->getKey(),
                'channel' => $channel,
                'created_by' => $createdBy?->getKey(),
                'type' => $data['type'],
                'scheduled_at' => $scheduledAt,
                'scheduled_end_at' => $scheduledAt->addMinutes($service->duration_minutes),
                'base_price' => $quote->base,
                'surcharges_total' => $quote->surchargesTotal(),
                'total_price' => $quote->total(),
                'price_snapshot' => $quote->toSnapshot(),
                'payment_method' => $data['payment_method'],
                'patient_note' => $data['patient_note'] ?? null,
                'prescription_file_id' => $prescription?->getKey(),
            ]);
            $booking->save();

            foreach ($quote->surcharges as $line) {
                DB::table('booking_surcharges')->insert([
                    'id' => (string) str()->ulid(),
                    'booking_id' => $booking->getKey(),
                    'surcharge_id' => $line['surcharge_id'],
                    'label' => (string) Translated::pick($line['name'], 'fr'),
                    'amount' => $line['amount'],
                ]);
            }

            // Première ligne de l'historique : la création elle-même, attribuée à son auteur.
            $author = $createdBy ?? $booker;
            $booking->statusHistory()->create([
                'from_status' => null,
                'to_status' => BookingStatus::Pending,
                'actor_id' => $author->getKey(),
                'actor_role' => $author->primaryRole(),
            ]);

            return $booking->refresh();
        });
    }

    private function resolveSlot(Service $service, string $type, ?string $scheduledAt): CarbonImmutable
    {
        if ($type === 'immediate') {
            if (! $this->schedule->isOpenNow($service)) {
                throw new ApiException('outside_service_hours');
            }

            return CarbonImmutable::now()->startOfMinute();
        }

        $at = CarbonImmutable::parse((string) $scheduledAt);

        if (! $this->schedule->isBookable($at, $service)) {
            throw new ApiException('slot_unavailable');
        }

        return $at->utc();
    }

    /**
     * Règle du cahier des charges : un soin soumis à prescription exige une ordonnance déposée.
     */
    private function resolvePrescription(User $booker, Service $service, ?string $fileId): ?File
    {
        if ($fileId === null) {
            if ($service->requires_prescription) {
                throw new ApiException('prescription_required');
            }

            return null;
        }

        $file = File::query()
            ->where('category', 'prescription')
            ->where('uploaded_by', $booker->getKey())
            ->find($fileId);

        if (! $file) {
            throw new ApiException('prescription_required');
        }

        return $file;
    }

    private function nextReference(): string
    {
        $number = (int) DB::selectOne("SELECT nextval('booking_reference_seq') AS value")->value;

        return sprintf('NC-%s-%06d', now()->setTimezone($this->schedule->timezone())->format('Y'), $number);
    }
}
