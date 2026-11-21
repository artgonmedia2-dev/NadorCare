<?php

namespace Tests\Feature\Bookings;

use App\Actions\Bookings\TransitionBooking;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Events\BookingStatusChanged;
use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Str;
use Tests\TestCase;

class BookingTransitionTest extends TestCase
{
    private function transition(Booking $booking, BookingStatus $to, User $actor, ?string $reason = null, array $meta = []): Booking
    {
        return app(TransitionBooking::class)->handle($booking, $to, $actor, $reason, $meta);
    }

    private function assertRefused(string $code, callable $attempt): void
    {
        try {
            $attempt();
            $this->fail("La transition aurait dû être refusée ($code).");
        } catch (ApiException $e) {
            $this->assertSame($code, $e->errorCode);
        }
    }

    public function test_a_new_booking_is_pending(): void
    {
        $this->assertSame(BookingStatus::Pending, Booking::factory()->create()->fresh()->status);
    }

    public function test_a_coordinator_confirms_a_pending_booking_and_the_change_is_attributed(): void
    {
        Event::fake([BookingStatusChanged::class]);
        $coordinator = $this->userWithRole(Role::Coordinateur);
        $booking = Booking::factory()->create();

        $booking = $this->transition($booking, BookingStatus::Confirmed, $coordinator);

        $this->assertSame(BookingStatus::Confirmed, $booking->fresh()->status);

        $history = $booking->statusHistory()->sole();
        $this->assertSame(BookingStatus::Pending, $history->from_status);
        $this->assertSame(BookingStatus::Confirmed, $history->to_status);
        $this->assertSame($coordinator->id, $history->actor_id);
        $this->assertSame(Role::Coordinateur->value, $history->actor_role);
        $this->assertNotNull($history->created_at);

        Event::assertDispatched(BookingStatusChanged::class, fn (BookingStatusChanged $event) => $event->bookingId === $booking->id
            && $event->from === 'pending' && $event->to === 'confirmed');
    }

    public function test_confirmation_is_reserved_to_the_coordination(): void
    {
        $booking = Booking::factory()->create();
        $professional = Professional::factory()->create();

        foreach ([$booking->user, $professional->user, $this->userWithRole(Role::Comptable)] as $actor) {
            $this->assertRefused('transition_forbidden', fn () => $this->transition($booking, BookingStatus::Confirmed, $actor));
        }

        $this->assertSame(BookingStatus::Pending, $booking->fresh()->status);
        $this->assertSame(0, $booking->statusHistory()->count());
    }

    public function test_impossible_transitions_are_refused(): void
    {
        $admin = $this->userWithRole(Role::Administrateur);

        $impossible = [
            [BookingStatus::Pending, BookingStatus::Assigned],
            [BookingStatus::Pending, BookingStatus::Completed],
            [BookingStatus::Confirmed, BookingStatus::InProgress],
            [BookingStatus::Assigned, BookingStatus::Completed],
            [BookingStatus::Completed, BookingStatus::Cancelled],
            [BookingStatus::Cancelled, BookingStatus::Confirmed],
            [BookingStatus::Confirmed, BookingStatus::Pending],
        ];

        foreach ($impossible as [$from, $to]) {
            $booking = Booking::factory()->inStatus($from)->create();
            $this->assertRefused('transition_not_allowed', fn () => $this->transition($booking, $to, $admin, null, ['professional_id' => 'x']));
        }
    }

    public function test_the_whole_journey_from_request_to_completion(): void
    {
        $coordinator = $this->userWithRole(Role::Coordinateur);
        $professional = Professional::factory()->create();
        $booking = Booking::factory()->create();

        $this->transition($booking, BookingStatus::Confirmed, $coordinator);
        $this->transition($booking, BookingStatus::Assigned, $coordinator, null, ['professional_id' => $professional->id]);
        $this->assertSame($professional->id, $booking->fresh()->professional_id);

        $this->transition($booking, BookingStatus::EnRoute, $professional->user);
        $this->transition($booking, BookingStatus::InProgress, $professional->user);
        $this->transition($booking, BookingStatus::Completed, $professional->user);

        $this->assertSame(BookingStatus::Completed, $booking->fresh()->status);
        $this->assertSame(
            ['confirmed', 'assigned', 'en_route', 'in_progress', 'completed'],
            $booking->statusHistory()->get()->map(fn ($row) => $row->to_status->value)->all(),
        );
    }

    public function test_assignment_requires_a_professional(): void
    {
        $coordinator = $this->userWithRole(Role::Coordinateur);
        $booking = Booking::factory()->inStatus(BookingStatus::Confirmed)->create();

        $this->assertRefused('professional_required', fn () => $this->transition($booking, BookingStatus::Assigned, $coordinator));
    }

    public function test_a_professional_takes_a_mission_only_through_a_pending_offer(): void
    {
        $professional = Professional::factory()->create();
        $booking = Booking::factory()->inStatus(BookingStatus::Confirmed)->create();
        $meta = ['professional_id' => $professional->id];

        $this->assertRefused('transition_forbidden', fn () => $this->transition($booking, BookingStatus::Assigned, $professional->user, null, $meta));

        DB::table('booking_offers')->insert([
            'id' => (string) Str::ulid(), 'booking_id' => $booking->id, 'professional_id' => $professional->id,
            'status' => 'pending', 'expires_at' => now()->addMinutes(2), 'created_at' => now(), 'updated_at' => now(),
        ]);

        $this->transition($booking, BookingStatus::Assigned, $professional->user, null, $meta);
        $this->assertSame($professional->id, $booking->fresh()->professional_id);
    }

    public function test_an_expired_offer_cannot_be_accepted(): void
    {
        $professional = Professional::factory()->create();
        $booking = Booking::factory()->inStatus(BookingStatus::Confirmed)->create();

        DB::table('booking_offers')->insert([
            'id' => (string) Str::ulid(), 'booking_id' => $booking->id, 'professional_id' => $professional->id,
            'status' => 'pending', 'expires_at' => now()->subMinute(), 'created_at' => now(), 'updated_at' => now(),
        ]);

        $this->assertRefused('transition_forbidden', fn () => $this->transition(
            $booking, BookingStatus::Assigned, $professional->user, null, ['professional_id' => $professional->id]
        ));
    }

    public function test_only_the_assigned_professional_runs_the_mission(): void
    {
        $assigned = Professional::factory()->create();
        $other = Professional::factory()->create();
        $booking = Booking::factory()->inStatus(BookingStatus::Assigned, $assigned)->create();

        $this->assertRefused('transition_forbidden', fn () => $this->transition($booking, BookingStatus::EnRoute, $other->user));
        $this->assertRefused('transition_forbidden', fn () => $this->transition($booking, BookingStatus::EnRoute, $booking->user));

        $this->transition($booking, BookingStatus::EnRoute, $assigned->user);
        $this->assertSame(BookingStatus::EnRoute, $booking->fresh()->status);
    }

    public function test_the_booker_cancels_and_the_reason_is_kept(): void
    {
        $booking = Booking::factory()->inStatus(BookingStatus::Confirmed)->create();

        $this->transition($booking, BookingStatus::Cancelled, $booking->user, 'Rendez-vous médical déplacé');

        $booking->refresh();
        $this->assertSame(BookingStatus::Cancelled, $booking->status);
        $this->assertSame($booking->user_id, $booking->cancelled_by);
        $this->assertSame('Rendez-vous médical déplacé', $booking->cancellation_reason);
    }

    public function test_a_stranger_cannot_cancel_someone_elses_booking(): void
    {
        $booking = Booking::factory()->inStatus(BookingStatus::Confirmed)->create();
        $stranger = $this->userWithRole(Role::Patient);

        $this->assertRefused('transition_forbidden', fn () => $this->transition($booking, BookingStatus::Cancelled, $stranger));
    }

    public function test_reassignment_releases_the_professional(): void
    {
        $coordinator = $this->userWithRole(Role::Coordinateur);
        $professional = Professional::factory()->create();
        $booking = Booking::factory()->inStatus(BookingStatus::Assigned, $professional)->create();

        $this->transition($booking, BookingStatus::Confirmed, $coordinator, 'Professionnel indisponible');

        $booking->refresh();
        $this->assertSame(BookingStatus::Confirmed, $booking->status);
        $this->assertNull($booking->professional_id);
        $this->assertSame($professional->id, $booking->statusHistory()->sole()->meta['previous_professional_id']);
    }

    public function test_disputes_are_opened_and_closed_by_the_coordination_only(): void
    {
        $coordinator = $this->userWithRole(Role::Coordinateur);
        $professional = Professional::factory()->create();
        $booking = Booking::factory()->inStatus(BookingStatus::Completed, $professional)->create();

        $this->assertRefused('transition_forbidden', fn () => $this->transition($booking, BookingStatus::Disputed, $booking->user));

        $this->transition($booking, BookingStatus::Disputed, $coordinator, 'Réclamation du patient');
        $this->assertRefused('transition_forbidden', fn () => $this->transition($booking, BookingStatus::Completed, $professional->user));

        $this->transition($booking, BookingStatus::Completed, $coordinator, 'Réclamation non fondée');
        $this->assertSame(BookingStatus::Completed, $booking->fresh()->status);
    }

    public function test_the_status_history_cannot_be_rewritten(): void
    {
        $booking = Booking::factory()->create();
        $this->transition($booking, BookingStatus::Confirmed, $this->userWithRole(Role::Coordinateur));

        try {
            DB::transaction(fn () => DB::table('booking_status_history')->where('booking_id', $booking->id)->update(['actor_id' => null]));
            $this->fail('L\'historique des statuts a pu être modifié.');
        } catch (QueryException $e) {
            $this->assertStringContainsString('insertion seule', $e->getMessage());
        }
    }
}
