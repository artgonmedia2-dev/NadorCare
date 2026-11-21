<?php

namespace Tests\Feature\Bookings;

use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Models\AccessLog;
use App\Models\Address;
use App\Models\Booking;
use App\Models\Holiday;
use App\Models\PatientProfile;
use App\Models\Service;
use App\Models\Surcharge;
use App\Models\User;
use App\Services\Settings\Settings;
use Carbon\CarbonImmutable;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BookingApiTest extends TestCase
{
    private const TZ = 'Africa/Casablanca';

    private User $user;

    private PatientProfile $profile;

    private Address $address;

    private Service $service;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');

        // Lundi 7 décembre 2026, 10 h à Nador : un jour ordinaire, pendant les horaires de service.
        $this->travelTo(CarbonImmutable::parse('2026-12-07 10:00', self::TZ));

        $this->user = $this->userWithRole(Role::Patient);
        Sanctum::actingAs($this->user, ['app:patient']);

        $this->profile = PatientProfile::factory()->create(['user_id' => $this->user->id, 'first_name' => 'Aïcha', 'last_name' => 'Benali']);
        $this->address = Address::factory()->create(['user_id' => $this->user->id, 'label' => 'Maison', 'zone_id' => $this->createZone(true)]);
        $this->service = Service::factory()->create(['duration_minutes' => 30, 'base_price' => 10000]);
    }

    private function createZone(bool $active): string
    {
        $id = (string) Str::ulid();
        DB::insert(
            'INSERT INTO zones (id, name, slug, boundary, is_active, sort, created_at, updated_at) VALUES (?, ?, ?, ST_GeogFromText(?), ?, 1, now(), now())',
            [$id, json_encode(['fr' => 'Nador centre']), 'zone-'.Str::random(6), 'SRID=4326;MULTIPOLYGON(((-2.96 35.15, -2.90 35.15, -2.90 35.19, -2.96 35.19, -2.96 35.15)))', $active]
        );

        return $id;
    }

    private function at(string $localDateTime): string
    {
        return CarbonImmutable::parse($localDateTime, self::TZ)->toIso8601String();
    }

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'service_id' => $this->service->id,
            'patient_profile_id' => $this->profile->id,
            'address_id' => $this->address->id,
            'type' => 'scheduled',
            'scheduled_at' => $this->at('2026-12-08 09:30'),
            'payment_method' => 'cash',
            'patient_note' => 'Sonner deux fois, chien gentil',
        ], $overrides);
    }

    // --- Créneaux ---

    public function test_slots_respect_service_hours_duration_and_lead_time(): void
    {
        // Aujourd'hui à 10 h, avec 60 minutes de délai : premier créneau à 11 h.
        $today = $this->getJson("/api/v1/bookings/slots?service_id={$this->service->id}&date=2026-12-07")
            ->assertOk()
            ->assertJsonPath('data.timezone', self::TZ)
            ->assertJsonPath('data.immediate_available', true)
            ->json('data.slots');

        $this->assertSame($this->at('2026-12-07 11:00'), $today[0]);
        // Soin de 30 minutes, fermeture à 20 h : dernier début à 19 h 30.
        $this->assertSame($this->at('2026-12-07 19:30'), end($today));

        $tomorrow = $this->getJson("/api/v1/bookings/slots?service_id={$this->service->id}&date=2026-12-08")->json('data.slots');
        $this->assertSame($this->at('2026-12-08 08:00'), $tomorrow[0]);
        $this->assertCount(24, $tomorrow); // de 8 h à 19 h 30, toutes les 30 minutes
    }

    public function test_no_slot_in_the_past_or_too_far_ahead(): void
    {
        $this->getJson("/api/v1/bookings/slots?service_id={$this->service->id}&date=2026-12-06")->assertJsonPath('data.slots', []);
        $this->getJson("/api/v1/bookings/slots?service_id={$this->service->id}&date=2027-01-07")->assertJsonPath('data.slots', []);
        $this->getJson("/api/v1/bookings/slots?service_id={$this->service->id}&date=2027-01-06")->assertJsonCount(24, 'data.slots');
    }

    public function test_service_hours_are_configurable(): void
    {
        app(Settings::class)->set(Settings::DAY_START, '09:00');
        app(Settings::class)->set(Settings::DAY_END, '12:00');
        app(Settings::class)->set(Settings::SLOT_MINUTES, 60);

        $slots = $this->getJson("/api/v1/bookings/slots?service_id={$this->service->id}&date=2026-12-08")->json('data.slots');

        $this->assertSame([$this->at('2026-12-08 09:00'), $this->at('2026-12-08 10:00'), $this->at('2026-12-08 11:00')], $slots);
    }

    // --- Création ---

    public function test_a_booking_is_created_pending_with_a_reference_and_a_frozen_price(): void
    {
        $response = $this->postJson('/api/v1/bookings', $this->payload())
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.type', 'scheduled')
            ->assertJsonPath('data.scheduled_at', CarbonImmutable::parse('2026-12-08 09:30', self::TZ)->utc()->toIso8601String())
            ->assertJsonPath('data.patient.first_name', 'Aïcha')
            ->assertJsonPath('data.address.label', 'Maison')
            ->assertJsonPath('data.price', ['base' => 10000, 'surcharges' => [], 'total' => 10000, 'currency' => 'MAD'])
            ->assertJsonPath('data.payment_method', 'cash')
            ->assertJsonPath('data.can_cancel', true)
            ->assertJsonPath('data.patient_note', 'Sonner deux fois, chien gentil')
            ->assertJsonPath('data.history.0.status', 'pending');

        $this->assertMatchesRegularExpression('/^NC-2026-\d{6}$/', $response->json('data.reference'));

        $booking = Booking::query()->sole();
        $this->assertSame(BookingStatus::Pending, $booking->status);
        $this->assertSame($this->user->id, $booking->statusHistory()->sole()->actor_id);
        $this->assertStringNotContainsString('Sonner', DB::table('bookings')->value('patient_note'));

        // Le prix de la réservation ne suit pas une hausse de tarif ultérieure.
        $this->service->update(['base_price' => 99900]);
        $this->getJson("/api/v1/bookings/{$booking->id}")->assertJsonPath('data.price.total', 10000);
    }

    public function test_references_are_unique_and_sequential(): void
    {
        $first = $this->postJson('/api/v1/bookings', $this->payload())->json('data.reference');
        $second = $this->postJson('/api/v1/bookings', $this->payload(['scheduled_at' => $this->at('2026-12-08 10:00')]))->json('data.reference');

        $this->assertSame((int) substr($first, -6) + 1, (int) substr($second, -6));
    }

    public function test_an_immediate_booking_is_accepted_only_during_service_hours(): void
    {
        $this->postJson('/api/v1/bookings', $this->payload(['type' => 'immediate', 'scheduled_at' => null]))
            ->assertCreated()
            ->assertJsonPath('data.type', 'immediate');

        $this->travelTo(CarbonImmutable::parse('2026-12-07 22:15', self::TZ));

        $this->postJson('/api/v1/bookings', $this->payload(['type' => 'immediate', 'scheduled_at' => null]))
            ->assertStatus(422)
            ->assertJsonPath('code', 'outside_service_hours');
    }

    public function test_only_offered_slots_can_be_booked(): void
    {
        foreach ([
            '2026-12-08 07:30', // avant l'ouverture
            '2026-12-08 19:45', // hors grille, et le soin dépasserait la fermeture
            '2026-12-08 09:10', // hors grille
            '2026-12-07 10:30', // dans moins d'une heure
            '2026-12-06 09:30', // passé
            '2027-02-01 09:30', // trop loin
        ] as $slot) {
            $this->postJson('/api/v1/bookings', $this->payload(['scheduled_at' => $this->at($slot)]))
                ->assertStatus(422)
                ->assertJsonPath('code', 'slot_unavailable');
        }

        $this->assertSame(0, Booking::query()->count());
    }

    public function test_the_address_must_be_in_an_open_zone(): void
    {
        $outside = Address::factory()->create(['user_id' => $this->user->id, 'zone_id' => null]);
        $closed = Address::factory()->create(['user_id' => $this->user->id, 'zone_id' => $this->createZone(false)]);

        foreach ([$outside, $closed] as $address) {
            $this->postJson('/api/v1/bookings', $this->payload(['address_id' => $address->id]))
                ->assertStatus(422)
                ->assertJsonPath('code', 'address_not_covered');
        }
    }

    public function test_profile_and_address_must_belong_to_the_account(): void
    {
        $this->postJson('/api/v1/bookings', $this->payload([
            'patient_profile_id' => PatientProfile::factory()->create()->id,
            'address_id' => Address::factory()->create()->id,
        ]))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['patient_profile_id', 'address_id']);
    }

    public function test_card_payment_is_not_open_yet(): void
    {
        $this->postJson('/api/v1/bookings', $this->payload(['payment_method' => 'card']))
            ->assertStatus(422)
            ->assertJsonPath('code', 'payment_method_unavailable');
    }

    public function test_a_hidden_service_cannot_be_booked(): void
    {
        $this->service->update(['is_active' => false]);

        $this->postJson('/api/v1/bookings', $this->payload())->assertStatus(422)->assertJsonPath('code', 'service_unavailable');
        $this->getJson("/api/v1/bookings/slots?service_id={$this->service->id}&date=2026-12-08")->assertStatus(422);
    }

    public function test_the_same_request_cannot_be_sent_twice(): void
    {
        $this->postJson('/api/v1/bookings', $this->payload())->assertCreated();

        $this->postJson('/api/v1/bookings', $this->payload())
            ->assertStatus(409)
            ->assertJsonPath('code', 'booking_duplicate');

        $this->assertSame(1, Booking::query()->count());
    }

    // --- Ordonnance ---

    public function test_a_service_requiring_a_prescription_cannot_be_booked_without_one(): void
    {
        $this->service->update(['requires_prescription' => true]);

        $this->postJson('/api/v1/bookings', $this->payload())
            ->assertStatus(422)
            ->assertJsonPath('code', 'prescription_required');
    }

    public function test_an_uploaded_prescription_is_encrypted_and_unlocks_the_booking(): void
    {
        $this->service->update(['requires_prescription' => true]);

        $fileId = $this->post('/api/v1/files/prescriptions', [
            'file' => UploadedFile::fake()->createWithContent('ordonnance.pdf', "%PDF-1.4\nAmoxicilline 1 g"),
        ], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonPath('data.mime', 'application/pdf')
            ->json('data.id');

        $stored = DB::table('files')->where('id', $fileId)->first();
        $this->assertStringNotContainsString('Amoxicilline', Storage::disk('local')->get($stored->path));
        $this->assertSame(AccessAction::Create, AccessLog::query()->where('subject_id', $fileId)->sole()->action);

        $this->postJson('/api/v1/bookings', $this->payload(['prescription_file_id' => $fileId]))
            ->assertCreated()
            ->assertJsonPath('data.has_prescription', true);
    }

    public function test_someone_elses_prescription_is_refused(): void
    {
        $this->service->update(['requires_prescription' => true]);

        Sanctum::actingAs($this->userWithRole(Role::Patient), ['app:patient']);
        $foreign = $this->post('/api/v1/files/prescriptions', ['file' => UploadedFile::fake()->image('ordonnance.jpg')], ['Accept' => 'application/json'])->json('data.id');

        Sanctum::actingAs($this->user, ['app:patient']);
        $this->postJson('/api/v1/bookings', $this->payload(['prescription_file_id' => $foreign]))
            ->assertStatus(422)
            ->assertJsonPath('code', 'prescription_required');
    }

    public function test_only_images_and_pdf_are_accepted_as_prescriptions(): void
    {
        $this->post('/api/v1/files/prescriptions', ['file' => UploadedFile::fake()->create('virus.exe', 10)], ['Accept' => 'application/json'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('file');

        $this->post('/api/v1/files/prescriptions', ['file' => UploadedFile::fake()->create('gros.pdf', 11000, 'application/pdf')], ['Accept' => 'application/json'])
            ->assertStatus(422);
    }

    // --- Prix ---

    public function test_a_holiday_surcharge_is_added_to_the_price_and_kept_with_the_booking(): void
    {
        Surcharge::create(['type' => 'holiday', 'name' => ['fr' => 'Jour férié', 'ar' => 'يوم عطلة', 'en' => 'Public holiday'], 'mode' => 'percent', 'value' => 50, 'is_active' => true]);
        Holiday::create(['date' => '2026-12-08', 'name' => ['fr' => 'Fête de démonstration']]);

        $this->postJson('/api/v1/bookings/quote', ['service_id' => $this->service->id, 'scheduled_at' => $this->at('2026-12-08 09:30')])
            ->assertOk()
            ->assertJsonPath('data', ['base' => 10000, 'surcharges' => [['label' => 'Jour férié', 'amount' => 5000]], 'total' => 15000, 'currency' => 'MAD']);

        // Le lendemain, pas de majoration.
        $this->postJson('/api/v1/bookings/quote', ['service_id' => $this->service->id, 'scheduled_at' => $this->at('2026-12-09 09:30')])
            ->assertJsonPath('data.total', 10000);

        $this->postJson('/api/v1/bookings', $this->payload(), ['Accept-Language' => 'ar'])
            ->assertCreated()
            ->assertJsonPath('data.price.total', 15000)
            ->assertJsonPath('data.price.surcharges.0.label', 'يوم عطلة');

        $this->assertDatabaseHas('booking_surcharges', ['label' => 'Jour férié', 'amount' => 5000]);
    }

    public function test_a_night_surcharge_applies_inside_its_time_range_only(): void
    {
        app(Settings::class)->set(Settings::DAY_END, '23:30');
        Surcharge::create(['type' => 'night', 'name' => ['fr' => 'Nuit'], 'mode' => 'fixed', 'value' => 3000, 'config' => ['start' => '21:00', 'end' => '07:00'], 'is_active' => true]);
        Surcharge::create(['type' => 'night', 'name' => ['fr' => 'Ancienne majoration'], 'mode' => 'fixed', 'value' => 9999, 'is_active' => false]);

        $quote = fn (string $slot) => $this->postJson('/api/v1/bookings/quote', ['service_id' => $this->service->id, 'scheduled_at' => $this->at($slot)])->json('data.total');

        $this->assertSame(10000, $quote('2026-12-08 20:30'));
        $this->assertSame(13000, $quote('2026-12-08 21:00'));
        $this->assertSame(13000, $quote('2026-12-08 22:30'));
        $this->assertSame(13000, $quote('2026-12-09 06:30'));
        $this->assertSame(10000, $quote('2026-12-09 07:00'));
    }

    // --- Suivi ---

    public function test_bookings_are_listed_as_upcoming_or_past_and_only_for_the_account(): void
    {
        $mine = $this->postJson('/api/v1/bookings', $this->payload())->json('data.id');
        Booking::factory()->inStatus(BookingStatus::Completed)->create(['user_id' => $this->user->id, 'patient_profile_id' => $this->profile->id, 'address_id' => $this->address->id]);
        Booking::factory()->create(); // un autre compte

        $this->getJson('/api/v1/bookings')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $mine)->assertJsonMissingPath('data.0.patient_note');
        $this->getJson('/api/v1/bookings?scope=past')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.status', 'completed');
    }

    public function test_reading_a_booking_is_logged_and_others_bookings_are_invisible(): void
    {
        $id = $this->postJson('/api/v1/bookings', $this->payload())->json('data.id');
        $foreign = Booking::factory()->create();

        $this->getJson("/api/v1/bookings/$id")->assertOk()->assertJsonPath('data.patient_note', 'Sonner deux fois, chien gentil');

        $log = AccessLog::query()->where('booking_id', $id)->sole();
        $this->assertSame(AccessAction::View, $log->action);
        $this->assertSame($this->profile->id, $log->patient_profile_id);

        $this->getJson("/api/v1/bookings/{$foreign->id}")->assertNotFound();
        $this->postJson("/api/v1/bookings/{$foreign->id}/cancel")->assertNotFound();
        $this->assertSame(BookingStatus::Pending, $foreign->fresh()->status);
    }

    // --- Annulation ---

    public function test_a_pending_booking_is_cancelled_for_free(): void
    {
        $id = $this->postJson('/api/v1/bookings', $this->payload())->json('data.id');

        $this->postJson("/api/v1/bookings/$id/cancel", ['reason' => 'Rendez-vous déplacé'])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.can_cancel', false)
            ->assertJsonPath('data.cancellation_fee', 0)
            ->assertJsonPath('data.history.1.status', 'cancelled');

        $this->assertSame('Rendez-vous déplacé', Booking::query()->sole()->cancellation_reason);

        // Une réservation annulée ne s'annule pas deux fois.
        $this->postJson("/api/v1/bookings/$id/cancel")->assertStatus(409)->assertJsonPath('code', 'transition_not_allowed');
    }

    public function test_a_late_cancellation_of_a_confirmed_booking_costs_the_configured_fee(): void
    {
        app(Settings::class)->set(Settings::LATE_CANCELLATION_FEE_PERCENT, 30);
        $id = $this->postJson('/api/v1/bookings', $this->payload())->json('data.id');
        DB::table('bookings')->where('id', $id)->update(['status' => 'confirmed']);

        // La veille : encore gratuit.
        $this->getJson("/api/v1/bookings/$id")
            ->assertJsonPath('data.free_cancellation_until', CarbonImmutable::parse('2026-12-08 07:30', self::TZ)->utc()->toIso8601String())
            ->assertJsonPath('data.cancellation_fee_if_cancelled_now', 0);

        // Une heure avant le soin : 30 % du prix.
        $this->travelTo(CarbonImmutable::parse('2026-12-08 08:30', self::TZ));
        $this->getJson("/api/v1/bookings/$id")->assertJsonPath('data.cancellation_fee_if_cancelled_now', 3000);

        $this->postJson("/api/v1/bookings/$id/cancel")
            ->assertOk()
            ->assertJsonPath('data.cancellation_fee', 3000);

        $this->assertSame(3000, Booking::query()->sole()->statusHistory()->get()->last()->meta['cancellation_fee']);
    }

    public function test_by_default_late_cancellation_is_free_until_the_client_sets_a_fee(): void
    {
        $id = $this->postJson('/api/v1/bookings', $this->payload())->json('data.id');
        DB::table('bookings')->where('id', $id)->update(['status' => 'confirmed']);
        $this->travelTo(CarbonImmutable::parse('2026-12-08 09:00', self::TZ));

        $this->postJson("/api/v1/bookings/$id/cancel")->assertOk()->assertJsonPath('data.cancellation_fee', 0);
    }

    public function test_a_booking_in_progress_can_no_longer_be_cancelled(): void
    {
        $id = $this->postJson('/api/v1/bookings', $this->payload())->json('data.id');
        DB::table('bookings')->where('id', $id)->update(['status' => 'in_progress']);

        $this->getJson("/api/v1/bookings/$id")->assertJsonPath('data.can_cancel', false);
        $this->postJson("/api/v1/bookings/$id/cancel")->assertStatus(409);
    }

    public function test_a_professional_app_token_cannot_book(): void
    {
        Sanctum::actingAs($this->user, ['app:pro']);

        $this->postJson('/api/v1/bookings', $this->payload())->assertForbidden();
        $this->getJson('/api/v1/bookings')->assertForbidden();
    }
}
