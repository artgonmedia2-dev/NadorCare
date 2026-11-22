<?php

namespace Tests\Feature\Assignment;

use App\Actions\Assignment\AssignProfessional;
use App\Actions\Assignment\OfferMission;
use App\Contracts\PushGateway;
use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Exceptions\ApiException;
use App\Filament\Resources\Bookings\Pages\ListBookings;
use App\Models\AccessLog;
use App\Models\BookingOffer;
use App\Models\Professional;
use App\Models\User;
use App\Services\Push\FakePushGateway;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Livewire\Livewire;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

class AssignmentFlowTest extends TestCase
{
    use CreatesAssignmentData;

    private User $coordinator;

    private Professional $samira;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpAssignmentData();

        $this->coordinator = $this->userWithRole(Role::Coordinateur);
        $this->samira = $this->createProfessional(['name' => 'Samira']);
    }

    private function push(): FakePushGateway
    {
        return app(PushGateway::class);
    }

    private function registerDevice(Professional $professional, string $locale = 'fr'): void
    {
        $professional->user->update(['locale' => $locale]);
        Sanctum::actingAs($professional->user, ['app:pro']);
        $this->postJson('/api/v1/me/devices', ['app' => 'pro', 'platform' => 'android', 'fcm_token' => 'jeton-'.$professional->id])
            ->assertNoContent();
    }

    private function assertRefused(string $code, callable $attempt): void
    {
        try {
            $attempt();
            $this->fail("Un refus [$code] était attendu.");
        } catch (ApiException $e) {
            $this->assertSame($code, $e->errorCode);
        }
    }

    // --- Affectation directe ---

    public function test_the_coordinator_assigns_a_professional_who_is_notified_without_patient_data(): void
    {
        $this->registerDevice($this->samira, 'ar');
        $booking = $this->createBooking();

        app(AssignProfessional::class)->handle($booking, $this->samira, $this->coordinator);

        $booking->refresh();
        $this->assertSame(BookingStatus::Assigned, $booking->status);
        $this->assertSame($this->samira->id, $booking->professional_id);

        $history = $booking->statusHistory()->sole();
        $this->assertSame($this->coordinator->id, $history->actor_id);
        $this->assertSame('direct', $history->meta['mode']);

        $notification = $this->push()->sent[0];
        $this->assertSame(['jeton-'.$this->samira->id], $notification['tokens']);
        $this->assertSame(__('api.push.assigned.title', locale: 'ar'), $notification['title']);
        $this->assertSame(['type' => 'mission_assigned', 'booking_id' => $booking->id], $notification['data']);
        $this->assertStringNotContainsString($booking->patientProfile->last_name, $notification['title'].$notification['body']);
    }

    public function test_even_forced_an_assignment_never_goes_to_an_ineligible_professional(): void
    {
        $booking = $this->createBooking();
        $uninsured = $this->createProfessional(['insurance_expires' => '2026-11-01']);

        $this->assertRefused('professional_not_eligible', fn () => app(AssignProfessional::class)->handle($booking, $uninsured, $this->coordinator));

        $this->assertSame(BookingStatus::Confirmed, $booking->fresh()->status);
        $this->assertNull($booking->fresh()->professional_id);
    }

    public function test_a_request_must_be_confirmed_before_it_is_assigned(): void
    {
        $pending = $this->createBooking(BookingStatus::Pending);

        $this->assertRefused('transition_not_allowed', fn () => app(AssignProfessional::class)->handle($pending, $this->samira, $this->coordinator));
        $this->assertRefused('transition_not_allowed', fn () => app(OfferMission::class)->handle($pending, $this->samira, $this->coordinator));
    }

    public function test_only_the_coordination_assigns(): void
    {
        $booking = $this->createBooking();

        foreach ([$booking->user, $this->samira->user, $this->userWithRole(Role::Comptable)] as $actor) {
            $this->assertRefused('transition_forbidden', fn () => app(AssignProfessional::class)->handle($booking, $this->samira, $actor));
        }
    }

    // --- Proposition de mission ---

    public function test_an_offer_gives_the_professional_a_limited_time_and_hides_the_patient(): void
    {
        $this->registerDevice($this->samira);
        $booking = $this->createBooking();

        $offer = app(OfferMission::class)->handle($booking, $this->samira, $this->coordinator);

        $this->assertSame(BookingOffer::STATUS_PENDING, $offer->status);
        $this->assertEquals(now()->addSeconds(120), $offer->expires_at);
        $this->assertSame(BookingStatus::Confirmed, $booking->fresh()->status);
        $this->assertSame('mission_offer', $this->push()->sent[0]['data']['type']);

        Sanctum::actingAs($this->samira->user, ['app:pro']);
        $response = $this->getJson('/api/v1/pro/offers')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $offer->id)
            ->assertJsonPath('data.0.service.name', 'Pansement')
            ->assertJsonPath('data.0.scheduled_date', '2026-12-08')
            ->assertJsonPath('data.0.scheduled_time', '10:00')
            ->assertJsonPath('data.0.zone', 'Nador centre');

        // Avant d'accepter : ni nom, ni adresse, ni note.
        $body = $response->getContent();
        $this->assertStringNotContainsString($booking->patientProfile->last_name, $body);
        $this->assertStringNotContainsString('Al Massira', $body);
        $this->assertStringNotContainsString('Sonner', $body);
        $this->assertSame(0, AccessLog::query()->count());
    }

    public function test_only_one_offer_waits_for_an_answer_at_a_time(): void
    {
        $booking = $this->createBooking();
        $other = $this->createProfessional();

        app(OfferMission::class)->handle($booking, $this->samira, $this->coordinator);

        $this->assertRefused('offer_already_pending', fn () => app(OfferMission::class)->handle($booking, $other, $this->coordinator));
    }

    public function test_accepting_an_offer_assigns_the_mission_and_opens_the_patient_record(): void
    {
        $booking = $this->createBooking();
        $offer = app(OfferMission::class)->handle($booking, $this->samira, $this->coordinator);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->postJson("/api/v1/pro/offers/{$offer->id}/accept")
            ->assertOk()
            ->assertJsonPath('data.status', 'assigned')
            ->assertJsonPath('data.patient.last_name', $booking->patientProfile->last_name)
            ->assertJsonPath('data.address.line', '12 rue Al Massira')
            ->assertJsonPath('data.amount_to_collect', 10000)
            ->assertJsonMissingPath('data.patient_note');

        $this->assertSame(BookingOffer::STATUS_ACCEPTED, $offer->fresh()->status);
        $this->assertSame($this->samira->id, $booking->fresh()->professional_id);
        $this->assertSame($this->samira->user_id, $booking->statusHistory()->sole()->actor_id);

        $this->getJson('/api/v1/pro/offers')->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/pro/missions')->assertJsonCount(1, 'data')->assertJsonMissingPath('data.0.patient.care_notes');

        // Le détail donne les données de santé utiles, et chaque lecture est journalisée.
        $this->getJson("/api/v1/pro/missions/{$booking->id}")
            ->assertOk()
            ->assertJsonPath('data.patient.care_notes', 'Allergie à la pénicilline (donnée de test)')
            ->assertJsonPath('data.patient_note', 'Sonner deux fois (donnée de test)')
            ->assertJsonPath('data.address.access_notes', 'Porte verte');

        $logs = AccessLog::query()->where('booking_id', $booking->id)->get();
        $this->assertCount(2, $logs);
        $this->assertTrue($logs->every(fn (AccessLog $log) => $log->actor_id === $this->samira->user_id && $log->action === AccessAction::View));
    }

    public function test_a_declined_offer_leaves_the_request_to_be_offered_to_someone_else(): void
    {
        $booking = $this->createBooking();
        $offer = app(OfferMission::class)->handle($booking, $this->samira, $this->coordinator);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->postJson("/api/v1/pro/offers/{$offer->id}/decline", ['reason' => 'Déjà en déplacement'])
            ->assertOk()
            ->assertJsonPath('data.status', 'declined');

        $this->assertSame('Déjà en déplacement', $offer->fresh()->decline_reason);
        $this->assertSame(BookingStatus::Confirmed, $booking->fresh()->status);

        // Une réponse ne se donne qu'une fois.
        $this->postJson("/api/v1/pro/offers/{$offer->id}/accept")->assertStatus(409)->assertJsonPath('code', 'offer_unavailable');

        $other = $this->createProfessional();
        $this->assertSame(BookingOffer::STATUS_PENDING, app(OfferMission::class)->handle($booking, $other, $this->coordinator)->status);
    }

    public function test_an_offer_expires_after_the_response_delay(): void
    {
        $booking = $this->createBooking();
        $offer = app(OfferMission::class)->handle($booking, $this->samira, $this->coordinator);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->travel(121)->seconds();

        $this->getJson('/api/v1/pro/offers')->assertJsonCount(0, 'data');
        $this->postJson("/api/v1/pro/offers/{$offer->id}/accept")->assertStatus(409)->assertJsonPath('code', 'offer_unavailable');
        $this->assertSame(BookingStatus::Confirmed, $booking->fresh()->status);

        $this->artisan('nadorcare:expire-offers')->assertSuccessful();
        $this->assertSame(BookingOffer::STATUS_EXPIRED, $offer->fresh()->status);

        // La demande peut alors être proposée à un autre professionnel.
        app(OfferMission::class)->handle($booking, $this->createProfessional(), $this->coordinator);
    }

    public function test_a_direct_assignment_cancels_the_pending_offer(): void
    {
        $booking = $this->createBooking();
        $other = $this->createProfessional();
        $offer = app(OfferMission::class)->handle($booking, $other, $this->coordinator);

        app(AssignProfessional::class)->handle($booking, $this->samira, $this->coordinator);

        $this->assertSame(BookingOffer::STATUS_CANCELLED, $offer->fresh()->status);
        Sanctum::actingAs($other->user, ['app:pro']);
        $this->postJson("/api/v1/pro/offers/{$offer->id}/accept")->assertStatus(409);
        $this->assertSame($this->samira->id, $booking->fresh()->professional_id);
    }

    public function test_an_offer_cannot_be_accepted_if_the_professional_became_ineligible(): void
    {
        $booking = $this->createBooking();
        $offer = app(OfferMission::class)->handle($booking, $this->samira, $this->coordinator);
        DB::table('professional_documents')->where('professional_id', $this->samira->id)->update(['status' => 'expired']);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->postJson("/api/v1/pro/offers/{$offer->id}/accept")->assertStatus(422)->assertJsonPath('code', 'professional_not_eligible');
        $this->assertSame(BookingStatus::Confirmed, $booking->fresh()->status);
    }

    // --- Cloisonnement ---

    public function test_offers_and_missions_of_other_professionals_are_invisible(): void
    {
        $other = $this->createProfessional();
        $offered = $this->createBooking();
        $offer = app(OfferMission::class)->handle($offered, $this->samira, $this->coordinator);
        $mission = $this->createBooking(BookingStatus::Assigned, '2026-12-08 14:00', $this->samira);

        Sanctum::actingAs($other->user, ['app:pro']);

        $this->getJson('/api/v1/pro/offers')->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/pro/missions')->assertJsonCount(0, 'data');
        $this->postJson("/api/v1/pro/offers/{$offer->id}/accept")->assertNotFound();
        $this->getJson("/api/v1/pro/missions/{$mission->id}")->assertNotFound();
        $this->assertSame(0, AccessLog::query()->count());
    }

    public function test_a_finished_mission_is_no_longer_readable(): void
    {
        $mission = $this->createBooking(BookingStatus::Completed, '2026-12-08 14:00', $this->samira);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->getJson('/api/v1/pro/missions')->assertJsonCount(0, 'data');
        $this->getJson("/api/v1/pro/missions/{$mission->id}")->assertNotFound();
    }

    public function test_the_professional_api_requires_the_professional_app_and_a_professional_file(): void
    {
        Sanctum::actingAs($this->samira->user, ['app:patient']);
        $this->getJson('/api/v1/pro/missions')->assertForbidden()->assertJsonPath('code', 'forbidden');

        Sanctum::actingAs($this->userWithRole(Role::Professionnel), ['app:pro']);
        $this->getJson('/api/v1/pro/missions')->assertForbidden()->assertJsonPath('code', 'professional_profile_required');
    }

    // --- Désistement et réaffectation ---

    public function test_a_professional_withdraws_before_leaving_and_the_request_returns_to_the_coordination(): void
    {
        $mission = $this->createBooking(BookingStatus::Assigned, '2026-12-08 14:00', $this->samira);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->postJson("/api/v1/pro/missions/{$mission->id}/withdraw", [])->assertStatus(422)->assertJsonValidationErrors('reason');

        $this->postJson("/api/v1/pro/missions/{$mission->id}/withdraw", ['reason' => 'Panne de voiture'])
            ->assertOk()
            ->assertJsonPath('data.status', 'confirmed');

        $mission->refresh();
        $this->assertNull($mission->professional_id);
        $this->assertSame('Panne de voiture', $mission->statusHistory()->sole()->reason);
        $this->getJson('/api/v1/pro/missions')->assertJsonCount(0, 'data');
        // Le professionnel perd aussitôt l'accès au dossier.
        $this->assertFalse($this->samira->user->can('viewHealthData', $mission->patientProfile));
    }

    public function test_once_on_the_way_only_the_coordination_can_reassign(): void
    {
        $mission = $this->createBooking(BookingStatus::EnRoute, '2026-12-08 14:00', $this->samira);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->postJson("/api/v1/pro/missions/{$mission->id}/withdraw", ['reason' => 'Changement d\'avis'])
            ->assertForbidden()
            ->assertJsonPath('code', 'transition_forbidden');
        $this->assertSame(BookingStatus::EnRoute, $mission->fresh()->status);
    }

    // --- Appareils ---

    public function test_a_device_token_follows_the_account_that_last_signed_in(): void
    {
        $other = $this->createProfessional();
        $payload = ['app' => 'pro', 'platform' => 'android', 'fcm_token' => 'jeton-partage'];

        Sanctum::actingAs($this->samira->user, ['app:pro']);
        $this->postJson('/api/v1/me/devices', $payload)->assertNoContent();
        Sanctum::actingAs($other->user, ['app:pro']);
        $this->postJson('/api/v1/me/devices', $payload)->assertNoContent();

        $this->assertSame($other->user_id, DB::table('devices')->where('fcm_token', 'jeton-partage')->sole()->user_id);

        $this->postJson('/api/v1/me/devices', ['app' => 'tv', 'platform' => 'windows'])->assertStatus(422);
    }

    // --- Back-office ---

    public function test_the_coordinator_assigns_offers_and_reassigns_from_the_request_queue(): void
    {
        $this->flushSession();
        $staff = User::factory()->staff(Role::Coordinateur)->create();
        $staff->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($staff);

        $toAssign = $this->createBooking();
        $toOffer = $this->createBooking(BookingStatus::Confirmed, '2026-12-08 15:00');
        $other = $this->createProfessional(['name' => 'Karima']);

        $queue = Livewire::test(ListBookings::class)->filterTable('status', BookingStatus::Confirmed->value);

        $queue->assertTableActionVisible('assign', $toAssign)
            ->assertTableActionVisible('offer', $toAssign)
            ->assertTableActionHidden('confirm', $toAssign)
            ->assertTableActionHidden('unassign', $toAssign)
            ->callTableAction('assign', $toAssign, data: ['professional_id' => $this->samira->id])
            ->assertHasNoTableActionErrors()
            ->assertNotified(__('admin.bookings.assigned'));
        $this->assertSame($this->samira->id, $toAssign->fresh()->professional_id);

        $queue->callTableAction('offer', $toOffer, data: ['professional_id' => $other->id])
            ->assertNotified(__('admin.bookings.offered'));
        $this->assertSame(BookingOffer::STATUS_PENDING, BookingOffer::query()->where('booking_id', $toOffer->id)->sole()->status);

        // Sans professionnel choisi, rien ne se passe.
        $queue->callTableAction('assign', $toOffer, data: ['professional_id' => null])
            ->assertHasTableActionErrors(['professional_id' => 'required']);

        Livewire::test(ListBookings::class)
            ->filterTable('status', BookingStatus::Assigned->value)
            ->assertCanSeeTableRecords([$toAssign])
            ->assertSee('Samira')
            ->callTableAction('unassign', $toAssign, data: ['reason' => 'Soignant indisponible'])
            ->assertNotified(__('admin.bookings.unassigned'));

        $this->assertSame(BookingStatus::Confirmed, $toAssign->fresh()->status);
        $this->assertNull($toAssign->fresh()->professional_id);
    }

    public function test_a_professional_who_became_busy_can_no_longer_be_chosen(): void
    {
        $this->flushSession();
        $staff = User::factory()->staff(Role::Coordinateur)->create();
        $staff->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($staff);

        $booking = $this->createBooking();
        // Le professionnel devient indisponible entre l'ouverture de la liste et la validation.
        $queue = Livewire::test(ListBookings::class)->filterTable('status', BookingStatus::Confirmed->value);
        $this->createBooking(BookingStatus::Assigned, '2026-12-08 10:00', $this->samira);

        // Le formulaire revérifie la liste au moment de valider : le choix n'est plus accepté.
        $queue->callTableAction('assign', $booking, data: ['professional_id' => $this->samira->id])
            ->assertHasTableActionErrors(['professional_id' => 'in']);

        $this->assertSame(BookingStatus::Confirmed, $booking->fresh()->status);
    }
}
