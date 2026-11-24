<?php

namespace Tests\Feature\Assignment;

use App\Actions\Assignment\AssignProfessional;
use App\Actions\Assignment\RespondToAssignment;
use App\Contracts\PushGateway;
use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Enums\DeclineReason;
use App\Enums\Role;
use App\Exceptions\ApiException;
use App\Filament\Resources\Bookings\Pages\ListBookings;
use App\Models\AccessLog;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\User;
use App\Services\Push\FakePushGateway;
use App\Services\Settings\Settings;
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
        $suspended = $this->createProfessional(['status' => 'suspended']);

        $this->assertRefused('professional_not_eligible', fn () => app(AssignProfessional::class)->handle($booking, $suspended, $this->coordinator));

        $this->assertSame(BookingStatus::Confirmed, $booking->fresh()->status);
        $this->assertNull($booking->fresh()->professional_id);
    }

    public function test_a_request_must_be_confirmed_before_it_is_assigned(): void
    {
        $pending = $this->createBooking(BookingStatus::Pending);

        $this->assertRefused('transition_not_allowed', fn () => app(AssignProfessional::class)->handle($pending, $this->samira, $this->coordinator));
    }

    public function test_only_the_coordination_assigns(): void
    {
        $booking = $this->createBooking();

        foreach ([$booking->user, $this->samira->user, $this->userWithRole(Role::Comptable)] as $actor) {
            $this->assertRefused('transition_forbidden', fn () => app(AssignProfessional::class)->handle($booking, $this->samira, $actor));
        }
    }

    // --- Confirmation par le soignant ---

    public function test_the_caregiver_has_a_delay_to_confirm_shorter_for_a_same_day_care(): void
    {
        // Lundi 7 décembre, 10 h. Soin du lendemain : deux heures pour confirmer.
        $tomorrow = app(AssignProfessional::class)->handle($this->createBooking(), $this->samira, $this->coordinator);
        $this->assertEquals(now()->addMinutes(120), $tomorrow->assignment_confirm_by);
        $this->assertNull($tomorrow->assignment_confirmed_at);

        // Soin du jour même : un quart d'heure.
        $other = $this->createProfessional();
        $today = app(AssignProfessional::class)->handle(
            $this->createBooking(BookingStatus::Confirmed, '2026-12-07 16:00'), $other, $this->coordinator,
        );
        $this->assertEquals(now()->addMinutes(15), $today->assignment_confirm_by);

        // Les deux délais se règlent au back-office.
        app(Settings::class)->set(Settings::ASSIGNMENT_CONFIRM_MINUTES_LATER, 45);
        $later = app(AssignProfessional::class)->handle(
            $this->createBooking(BookingStatus::Confirmed, '2026-12-09 10:00'), $other, $this->coordinator,
        );
        $this->assertEquals(now()->addMinutes(45), $later->assignment_confirm_by);
    }

    public function test_the_caregiver_confirms_the_mission_and_reads_the_patient_record(): void
    {
        $booking = app(AssignProfessional::class)->handle($this->createBooking(), $this->samira, $this->coordinator);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->getJson('/api/v1/pro/missions')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.needs_confirmation', true)
            ->assertJsonPath('data.0.confirm_by', now()->addMinutes(120)->toIso8601String())
            ->assertJsonPath('data.0.patient.last_name', $booking->patientProfile->last_name)
            ->assertJsonPath('data.0.address.line', '12 rue Al Massira')
            ->assertJsonPath('data.0.amount_to_collect', 10000)
            ->assertJsonMissingPath('data.0.patient.care_notes')
            ->assertJsonMissingPath('data.0.patient_note');

        $this->postJson("/api/v1/pro/missions/{$booking->id}/confirm")
            ->assertOk()
            ->assertJsonPath('data.status', 'assigned')
            ->assertJsonPath('data.needs_confirmation', false);
        $this->assertEquals(now(), $booking->fresh()->assignment_confirmed_at);

        // Confirmer deux fois ne change rien.
        $this->travel(5)->minutes();
        $this->postJson("/api/v1/pro/missions/{$booking->id}/confirm")->assertOk();
        $this->assertEquals(now()->subMinutes(5), $booking->fresh()->assignment_confirmed_at);

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

    public function test_leaving_for_the_mission_counts_as_a_confirmation(): void
    {
        $booking = app(AssignProfessional::class)->handle($this->createBooking(), $this->samira, $this->coordinator);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->postJson("/api/v1/pro/missions/{$booking->id}/depart")
            ->assertOk()
            ->assertJsonPath('data.status', 'en_route')
            ->assertJsonPath('data.needs_confirmation', false);

        $this->assertNotNull($booking->fresh()->assignment_confirmed_at);
        // Une fois parti, il n'y a plus rien à confirmer.
        $this->postJson("/api/v1/pro/missions/{$booking->id}/confirm")->assertStatus(409)->assertJsonPath('code', 'assignment_not_pending');
    }

    public function test_without_an_answer_in_time_the_coordination_is_alerted(): void
    {
        $booking = app(AssignProfessional::class)->handle($this->createBooking(), $this->samira, $this->coordinator);

        $this->assertFalse($booking->confirmationOverdue());
        $this->assertSame(0, Booking::query()->needsReassignment()->count());

        $this->travel(121)->minutes();

        $this->assertTrue($booking->fresh()->confirmationOverdue());
        $this->assertSame([$booking->id], Booking::query()->needsReassignment()->pluck('id')->all());

        // La mission reste affectée : c'est le coordinateur qui relance ou réaffecte. Une
        // confirmation tardive lève l'alerte.
        Sanctum::actingAs($this->samira->user, ['app:pro']);
        $this->postJson("/api/v1/pro/missions/{$booking->id}/confirm")->assertOk();
        $this->assertSame(0, Booking::query()->needsReassignment()->count());
    }

    // --- Cloisonnement ---

    public function test_missions_of_other_professionals_are_invisible(): void
    {
        $other = $this->createProfessional();
        $mission = $this->createBooking(BookingStatus::Assigned, '2026-12-08 14:00', $this->samira);

        Sanctum::actingAs($other->user, ['app:pro']);

        $this->getJson('/api/v1/pro/missions')->assertJsonCount(0, 'data');
        $this->getJson("/api/v1/pro/missions/{$mission->id}")->assertNotFound();
        $this->postJson("/api/v1/pro/missions/{$mission->id}/confirm")->assertNotFound();
        $this->postJson("/api/v1/pro/missions/{$mission->id}/decline", ['reason' => 'busy'])->assertNotFound();
        $this->assertSame(BookingStatus::Assigned, $mission->fresh()->status);
        $this->assertSame(0, AccessLog::query()->count());
    }

    public function test_the_timed_offers_are_gone(): void
    {
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->getJson('/api/v1/pro/offers')->assertNotFound();
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

    public function test_a_caregiver_reports_being_unavailable_and_the_request_returns_to_the_coordination(): void
    {
        $mission = app(AssignProfessional::class)->handle(
            $this->createBooking(BookingStatus::Confirmed, '2026-12-08 14:00'), $this->samira, $this->coordinator,
        );
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->postJson("/api/v1/pro/missions/{$mission->id}/decline", [])->assertStatus(422)->assertJsonValidationErrors('reason');
        $this->postJson("/api/v1/pro/missions/{$mission->id}/decline", ['reason' => 'fatigue'])->assertStatus(422)->assertJsonValidationErrors('reason');
        // « Autre » demande une précision.
        $this->postJson("/api/v1/pro/missions/{$mission->id}/decline", ['reason' => 'other'])
            ->assertStatus(422)->assertJsonPath('code', 'decline_note_required');

        $this->postJson("/api/v1/pro/missions/{$mission->id}/decline", ['reason' => 'sick', 'note' => 'Forte fièvre depuis ce matin'])
            ->assertOk()
            ->assertJsonPath('data.status', 'confirmed');

        $mission->refresh();
        $this->assertNull($mission->professional_id);
        $this->assertNull($mission->assignment_confirm_by);
        $this->assertTrue($mission->wasDeclined());
        $this->assertSame('sick', $mission->assignment_decline_reason);
        $this->assertSame($this->samira->id, $mission->assignment_declined_by);
        $this->assertSame('Forte fièvre depuis ce matin', $mission->assignment_decline_note);
        // La précision peut évoquer la santé du soignant : chiffrée en base, absente de l'historique.
        $this->assertStringNotContainsString('fièvre', (string) DB::table('bookings')->where('id', $mission->id)->value('assignment_decline_note'));
        $this->assertSame('declined:sick', $mission->statusHistory()->get()->last()->reason);

        $this->getJson('/api/v1/pro/missions')->assertJsonCount(0, 'data');
        // Le soignant perd aussitôt l'accès au dossier.
        $this->assertFalse($this->samira->user->can('viewHealthData', $mission->patientProfile));

        // La coordination est alertée, puis réaffecte : l'alerte disparaît.
        $this->assertSame([$mission->id], Booking::query()->needsReassignment()->pluck('id')->all());
        $reassigned = app(AssignProfessional::class)->handle($mission, $this->createProfessional(), $this->coordinator);
        $this->assertFalse($reassigned->wasDeclined());
        $this->assertNull($reassigned->assignment_decline_note);
        $this->assertSame(0, Booking::query()->needsReassignment()->count());
    }

    public function test_once_on_the_way_only_the_coordination_can_reassign(): void
    {
        $mission = $this->createBooking(BookingStatus::EnRoute, '2026-12-08 14:00', $this->samira);
        Sanctum::actingAs($this->samira->user, ['app:pro']);

        $this->postJson("/api/v1/pro/missions/{$mission->id}/decline", ['reason' => 'personal'])
            ->assertForbidden()
            ->assertJsonPath('code', 'transition_forbidden');
        $this->assertSame(BookingStatus::EnRoute, $mission->fresh()->status);
        $this->assertNull($mission->fresh()->assignment_declined_at);
    }

    public function test_only_the_assigned_caregiver_answers_an_assignment(): void
    {
        $mission = app(AssignProfessional::class)->handle($this->createBooking(), $this->samira, $this->coordinator);
        $respond = app(RespondToAssignment::class);

        foreach ([$this->coordinator, $this->createProfessional()->user, $mission->user] as $actor) {
            $this->assertRefused('transition_forbidden', fn () => $respond->confirm($mission, $actor));
            $this->assertRefused('transition_forbidden', fn () => $respond->decline($mission, $actor, DeclineReason::Busy));
        }
        $this->assertTrue($mission->fresh()->awaitsConfirmation());
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

    public function test_the_coordinator_assigns_follows_the_answer_and_reassigns_from_the_request_queue(): void
    {
        $this->flushSession();
        $staff = User::factory()->staff(Role::Coordinateur)->create();
        $staff->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($staff);

        $toAssign = $this->createBooking();
        $second = $this->createBooking(BookingStatus::Confirmed, '2026-12-08 15:00');
        $other = $this->createProfessional(['name' => 'Karima']);

        $queue = Livewire::test(ListBookings::class)->filterTable('status', BookingStatus::Confirmed->value);

        $queue->assertTableActionVisible('assign', $toAssign)
            ->assertTableActionDoesNotExist('offer')
            ->assertTableActionHidden('confirm', $toAssign)
            ->assertTableActionHidden('unassign', $toAssign)
            ->callTableAction('assign', $toAssign, data: ['professional_id' => $this->samira->id])
            ->assertHasNoTableActionErrors()
            ->assertNotified(__('admin.bookings.assigned'));
        $this->assertSame($this->samira->id, $toAssign->fresh()->professional_id);

        // Sans professionnel choisi, rien ne se passe.
        $queue->callTableAction('assign', $second, data: ['professional_id' => null])
            ->assertHasTableActionErrors(['professional_id' => 'required']);

        // Le coordinateur suit la réponse du soignant : à confirmer, puis sans réponse après le délai.
        Livewire::test(ListBookings::class)
            ->filterTable('status', BookingStatus::Assigned->value)
            ->assertCanSeeTableRecords([$toAssign])
            ->assertSee('Samira')
            ->assertSee(__('admin.bookings.assignment.waiting'));

        $this->travel(121)->minutes();
        Livewire::test(ListBookings::class)
            ->removeTableFilter('status')
            ->filterTable('needs_reassignment')
            ->assertCanSeeTableRecords([$toAssign])
            ->assertCanNotSeeTableRecords([$second])
            ->assertSee(__('admin.bookings.assignment.overdue'));

        // Karima signale son indisponibilité : sa demande rejoint la file à réaffecter, avec le motif.
        app(AssignProfessional::class)->handle($second, $other, $staff);
        app(RespondToAssignment::class)->decline($second->fresh(), $other->user, DeclineReason::Other, 'Rendez-vous médical');
        Livewire::test(ListBookings::class)
            ->removeTableFilter('status')
            ->filterTable('needs_reassignment')
            ->assertCanSeeTableRecords([$toAssign, $second])
            ->assertSee(__('admin.bookings.assignment.declined', ['reason' => __('admin.bookings.assignment.reasons.other')]))
            ->assertSee('Rendez-vous médical')
            ->assertTableActionVisible('assign', $second);

        Livewire::test(ListBookings::class)
            ->filterTable('status', BookingStatus::Assigned->value)
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
