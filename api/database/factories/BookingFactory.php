<?php

namespace Database\Factories;

use App\Enums\BookingStatus;
use App\Models\Address;
use App\Models\Booking;
use App\Models\PatientProfile;
use App\Models\Professional;
use App\Models\Service;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Booking>
 */
class BookingFactory extends Factory
{
    public function definition(): array
    {
        return [
            'reference' => 'NC-'.strtoupper(Str::random(10)),
            'user_id' => User::factory(),
            'patient_profile_id' => fn (array $attributes) => PatientProfile::factory()->state(['user_id' => $attributes['user_id']]),
            'address_id' => fn (array $attributes) => Address::factory()->state(['user_id' => $attributes['user_id']]),
            'service_id' => Service::factory(),
            'scheduled_at' => now()->addDay(),
            'base_price' => 10000,
            'total_price' => 10000,
            'payment_method' => 'cash',
            'patient_note' => 'Sonner deux fois (donnée de test)',
        ];
    }

    /**
     * Place la réservation directement dans un statut, sans passer par la machine à états.
     * Réservé aux tests.
     */
    public function inStatus(BookingStatus $status, ?Professional $professional = null): static
    {
        return $this->afterMaking(function (Booking $booking) use ($status, $professional) {
            $booking->status = $status;
            $booking->professional_id = $professional?->getKey();
        });
    }
}
