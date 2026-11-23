<?php

namespace Tests\Feature\Teleconsultation;

use App\Actions\Bookings\CreateBooking;
use App\Enums\BookingStatus;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\Intervention;
use App\Models\Professional;
use App\Models\Service;
use App\Models\Surcharge;
use App\Models\User;
use App\Services\Bookings\PriceCalculator;
use App\Services\Settings\Settings;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

/**
 * Téléconsultation (décision du 2026-11-23) : soin à distance, sans trajet, par appel vidéo.
 */
class TeleconsultationTest extends TestCase
{
    use CreatesAssignmentData;

    private Service $remoteService;

    private Professional $doctor;

    private Booking $mission;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        $this->setUpAssignmentData();

        $this->remoteService = Service::factory()->remote()->create([
            'slug' => 'teleconsultation',
            'name' => ['fr' => 'Téléconsultation', 'ar' => 'استشارة عن بعد', 'en' => 'Teleconsultation'],
            'professional_category_id' => $this->nurses->id,
        ]);

        $this->doctor = $this->createProfessional(['name' => 'Dr Karim']);
        $this->mission = $this->createBooking(BookingStatus::Assigned, '2026-12-08 10:00', $this->doctor);
        $this->mission->update(['service_id' => $this->remoteService->id, 'payment_method' => 'card']);
    }

    private function asDoctor(): void
    {
        Sanctum::actingAs($this->doctor->user, ['app:pro']);
    }

    private function asPatient(): void
    {
        Sanctum::actingAs(User::query()->findOrFail($this->mission->user_id), ['app:patient']);
    }

    /** Dix minutes avant l'heure prévue : la salle vient de s'ouvrir. */
    private function openTheRoom(): void
    {
        $this->travelTo(CarbonImmutable::parse('2026-12-08 09:55', self::TZ));
    }

    private function url(string $suffix = ''): string
    {
        return "/api/v1/pro/missions/{$this->mission->id}$suffix";
    }

    // --- Catalogue et réservation ---

    public function test_teleconsultation_is_hidden_from_the_catalogue_until_it_is_opened(): void
    {
        $this->getJson('/api/v1/catalogue/services')->assertOk()->assertJsonMissing(['slug' => 'teleconsultation']);
        $this->getJson('/api/v1/catalogue/services/teleconsultation')->assertNotFound();

        app(Settings::class)->set(Settings::TELECONSULTATION_ENABLED, true);

        $this->getJson('/api/v1/catalogue/services/teleconsultation')
            ->assertOk()
            ->assertJsonPath('data.delivery_mode', 'remote');
        $this->getJson("/api/v1/catalogue/services/{$this->nursingService->slug}")
            ->assertJsonPath('data.delivery_mode', 'home');
    }

    public function test_teleconsultation_cannot_be_booked_while_closed_nor_paid_in_cash(): void
    {
        $booker = User::factory()->create();
        $payload = ['service_id' => $this->remoteService->id, 'patient_profile_id' => 'x', 'address_id' => 'x', 'type' => 'scheduled'];

        $attempt = function (string $method) use ($booker, $payload): string {
            try {
                app(CreateBooking::class)->handle($booker, [...$payload, 'payment_method' => $method]);
            } catch (ApiException $exception) {
                return $exception->getMessage();
            }

            return 'created';
        };

        $this->assertSame('teleconsultation_unavailable', $attempt('card'));

        app(Settings::class)->set(Settings::TELECONSULTATION_ENABLED, true);

        // Personne n'est sur place pour encaisser.
        $this->assertSame('teleconsultation_requires_card', $attempt('cash'));
        // Et le paiement par carte n'existe pas encore : la téléconsultation reste donc fermée de fait.
        $this->assertSame('payment_method_unavailable', $attempt('card'));
    }

    public function test_a_teleconsultation_costs_the_same_at_any_hour(): void
    {
        Surcharge::create([
            'type' => Surcharge::TYPE_NIGHT,
            'name' => ['fr' => 'Majoration du soir'],
            'mode' => Surcharge::MODE_FIXED,
            'value' => 5000,
            'config' => ['start' => '19:00', 'end' => '08:00'],
            'is_active' => true,
        ]);
        DB::table('holidays')->insert(['id' => (string) str()->ulid(), 'date' => '2026-12-09', 'name' => json_encode(['fr' => 'Férié'])]);
        Surcharge::create([
            'type' => Surcharge::TYPE_HOLIDAY,
            'name' => ['fr' => 'Jour férié'],
            'mode' => Surcharge::MODE_PERCENT,
            'value' => 25,
            'is_active' => true,
        ]);

        $prices = app(PriceCalculator::class);
        $this->remoteService->update(['base_price' => 15000]);

        $evening = CarbonImmutable::parse('2026-12-08 19:30', self::TZ);
        $holidayNight = CarbonImmutable::parse('2026-12-09 23:00', self::TZ);

        // Le soir, la nuit ou un jour férié : toujours le tarif de base.
        $this->assertSame(15000, $prices->quote($this->remoteService->fresh(), $evening)->total());
        $this->assertSame(15000, $prices->quote($this->remoteService->fresh(), $holidayNight)->total());
        $this->assertSame([], $prices->quote($this->remoteService->fresh(), $holidayNight)->surcharges);

        // Un soin à domicile garde ses majorations.
        $this->assertSame(
            $this->nursingService->base_price + 5000,
            $prices->quote($this->nursingService->fresh(), $evening)->total(),
        );
    }

    // --- Déroulement ---

    public function test_a_teleconsultation_has_no_journey(): void
    {
        $this->asDoctor();

        $this->getJson($this->url())
            ->assertOk()
            ->assertJsonPath('data.delivery_mode', 'remote')
            ->assertJsonPath('data.teleconsultation.opens_at', CarbonImmutable::parse('2026-12-08 09:50', self::TZ)->utc()->toIso8601String());

        $this->postJson($this->url('/depart'))->assertStatus(409)->assertJsonPath('code', 'transition_not_allowed');
        $this->assertSame(BookingStatus::Assigned, $this->mission->fresh()->status);
    }

    public function test_the_room_opens_shortly_before_the_appointment(): void
    {
        $this->asDoctor();

        // La veille : trop tôt.
        $this->getJson($this->url('/teleconsultation'))->assertStatus(409)->assertJsonPath('code', 'teleconsultation_not_open');
        $this->postJson($this->url('/start'))->assertStatus(409)->assertJsonPath('code', 'teleconsultation_not_open');
        $this->assertSame(BookingStatus::Assigned, $this->mission->fresh()->status);

        $this->openTheRoom();

        $this->getJson($this->url('/teleconsultation'))
            ->assertOk()
            ->assertJsonPath('data.provider', 'fake')
            ->assertJsonPath('data.is_host', true)
            ->assertJsonPath('data.room', 'nc-'.strtolower($this->mission->id));

        // Bien après la fin prévue : la salle est refermée.
        $this->travelTo(CarbonImmutable::parse('2026-12-08 11:30', self::TZ));
        $this->getJson($this->url('/teleconsultation'))->assertStatus(409)->assertJsonPath('code', 'teleconsultation_not_open');
    }

    public function test_the_professional_starts_the_call_and_the_report_opens(): void
    {
        $this->asDoctor();
        $this->openTheRoom();

        $this->postJson($this->url('/start'))->assertCreated();

        $this->assertSame(BookingStatus::InProgress, $this->mission->fresh()->status);
        $this->assertTrue(Intervention::query()->where('booking_id', $this->mission->id)->exists());

        // Le compte rendu se valide sans signature : le patient n'est pas devant le téléphone du professionnel.
        $this->putJson($this->url('/report'), ['observations' => 'Renouvellement de traitement, pas de signe d\'alerte.'])->assertOk();
        $this->postJson($this->url('/complete'), ['cash_collected' => false])->assertOk();

        $this->assertSame(BookingStatus::Completed, $this->mission->fresh()->status);
    }

    public function test_the_patient_joins_as_a_guest_and_nobody_else_can(): void
    {
        $this->openTheRoom();

        $this->asPatient();
        $response = $this->getJson("/api/v1/bookings/{$this->mission->id}/teleconsultation")
            ->assertOk()
            ->assertJsonPath('data.is_host', false)
            ->assertJsonPath('data.room', 'nc-'.strtolower($this->mission->id));

        // Rien qui identifie le patient ne part vers le prestataire vidéo.
        $this->assertStringNotContainsString((string) $this->mission->user_id, (string) $response->getContent());

        $this->getJson("/api/v1/bookings/{$this->mission->id}")
            ->assertOk()
            ->assertJsonPath('data.delivery_mode', 'remote')
            ->assertJsonStructure(['data' => ['teleconsultation' => ['opens_at', 'closes_at']]]);

        // Un autre compte ne voit pas cette réservation.
        Sanctum::actingAs(User::factory()->create(), ['app:patient']);
        $this->getJson("/api/v1/bookings/{$this->mission->id}/teleconsultation")->assertNotFound();

        // Un autre professionnel non plus.
        Sanctum::actingAs($this->createProfessional(['name' => 'Autre'])->user, ['app:pro']);
        $this->getJson($this->url('/teleconsultation'))->assertNotFound();
    }

    public function test_a_home_visit_is_not_a_teleconsultation(): void
    {
        $home = $this->createBooking(BookingStatus::Assigned, '2026-12-08 14:00', $this->doctor);
        $this->asDoctor();
        $this->travelTo(CarbonImmutable::parse('2026-12-08 13:55', self::TZ));

        $this->postJson("/api/v1/pro/missions/{$home->id}/start")->assertStatus(409)->assertJsonPath('code', 'not_a_teleconsultation');
        $this->getJson("/api/v1/pro/missions/{$home->id}/teleconsultation")->assertStatus(409)->assertJsonPath('code', 'not_a_teleconsultation');
        $this->getJson("/api/v1/pro/missions/{$home->id}")->assertJsonPath('data.delivery_mode', 'home')->assertJsonMissingPath('data.teleconsultation');

        // Un soin à domicile garde son trajet.
        $this->postJson("/api/v1/pro/missions/{$home->id}/depart")->assertOk();
    }
}
