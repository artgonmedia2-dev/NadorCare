<?php

namespace Tests\Feature\BackOffice;

use App\Actions\Assignment\AssignProfessional;
use App\Actions\Assignment\RespondToAssignment;
use App\Enums\BookingStatus;
use App\Enums\DeclineReason;
use App\Enums\Role;
use App\Filament\Widgets\CoordinationStats;
use App\Filament\Widgets\FinanceStats;
use App\Filament\Widgets\RequestsToHandle;
use App\Filament\Widgets\TodayMissions;
use App\Filament\Widgets\Watchlist;
use App\Models\ScheduleRequest;
use App\Models\User;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Livewire\Livewire;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

/**
 * Tableau de bord de la coordination (refonte du 2026-11-24) : ce qui attend une décision,
 * la journée de l'équipe, ce qu'il faut surveiller ; et celui du comptable.
 */
class DashboardTest extends TestCase
{
    use CreatesAssignmentData;

    protected function setUp(): void
    {
        parent::setUp();
        // Lundi 7 décembre 2026, 10 h à Nador.
        $this->setUpAssignmentData();
    }

    private function actingAsStaff(Role $role, string $name = 'Salma Bennani'): User
    {
        $this->flushSession();
        $staff = User::factory()->staff($role)->create(['name' => $name]);
        $staff->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($staff, 'web');

        return $staff;
    }

    public function test_the_coordinator_is_greeted_and_sees_what_waits_for_a_decision(): void
    {
        $samira = $this->createProfessional(['name' => 'Samira El Idrissi']);
        $karim = $this->createProfessional(['name' => 'Karim Tahiri']);
        $pending = $this->createBooking(BookingStatus::Pending, '2026-12-07 16:00');
        $coordinator = $this->actingAsStaff(Role::Coordinateur);
        $declined = app(AssignProfessional::class)->handle($this->createBooking(BookingStatus::Confirmed, '2026-12-08 09:00'), $karim, $coordinator);
        app(RespondToAssignment::class)->decline($declined, User::query()->findOrFail($karim->user_id), DeclineReason::Sick, 'Fièvre');
        $this->createBooking(BookingStatus::Completed, '2026-12-07 08:30', $samira);
        $this->createBooking(BookingStatus::EnRoute, '2026-12-07 11:00', $samira);
        // Confirmée par le soignant : rien à faire, elle ne figure pas dans la file.
        $confirmed = app(AssignProfessional::class)->handle($this->createBooking(BookingStatus::Confirmed, '2026-12-09 10:00'), $samira, $coordinator);
        app(RespondToAssignment::class)->confirm($confirmed, User::query()->findOrFail($samira->user_id));

        $this->get('/admin')->assertOk()->assertSee('Bonjour Salma');

        Livewire::test(CoordinationStats::class)
            ->assertSee(__('admin.dashboard.stats.pending'))
            ->assertSee(__('admin.dashboard.stats.today_help', ['done' => 1, 'moving' => 1, 'upcoming' => 0]));

        Livewire::test(RequestsToHandle::class)
            ->assertCanSeeTableRecords([$pending, $declined])
            ->assertCanNotSeeTableRecords([$confirmed])
            ->assertSee(__('admin.bookings.assignment.declined', ['reason' => __('admin.bookings.assignment.reasons.sick')]))
            ->assertTableActionVisible('confirm', $pending)
            ->assertTableActionVisible('assign', $declined)
            ->assertTableActionDoesNotExist('cancel')
            // Valider depuis le tableau de bord fait la même chose que depuis la liste des demandes.
            ->callTableAction('confirm', $pending)
            ->assertNotified(__('admin.bookings.confirmed'));
        $this->assertSame(BookingStatus::Confirmed, $pending->fresh()->status);

        Livewire::test(TodayMissions::class)
            ->assertSee('08:30')
            ->assertSee('Samira El Idrissi')
            ->assertSee(__('admin.bookings.statuses.en_route'))
            // Pas de donnée de santé ni d'adresse dans la journée de l'équipe.
            ->assertDontSee('Al Massira');
    }

    public function test_the_watchlist_lists_the_agency_insurance_documents_and_schedule_requests(): void
    {
        $karim = $this->createProfessional(['name' => 'Karim Tahiri', 'insurance_expires' => '2026-12-20']);
        ScheduleRequest::query()->create(['professional_id' => $karim->id, 'kind' => 'unavailability', 'starts_on' => '2026-12-10', 'ends_on' => '2026-12-10']);
        $this->actingAsStaff(Role::Coordinateur);

        Livewire::test(Watchlist::class)
            ->assertSee(__('admin.dashboard.watch.insurance'))
            ->assertSee(__('admin.dashboard.watch.insurance_none'))
            ->assertSee('Karim Tahiri')
            ->assertSee('20/12/2026')
            ->assertSee(trans_choice('admin.dashboard.watch.schedule', 1, ['count' => 1]));

        DB::table('agency_insurances')->insert(['id' => (string) Str::ulid(), 'insurer' => 'Assurances du Rif', 'policy_number' => 'RC-1', 'expires_on' => '2027-12-31', 'created_at' => now(), 'updated_at' => now()]);
        Livewire::test(Watchlist::class)->assertDontSee(__('admin.dashboard.watch.insurance'));
    }

    public function test_the_accountant_gets_the_money_view_and_no_patient_data(): void
    {
        $samira = $this->createProfessional(['name' => 'Samira El Idrissi']);
        $booking = $this->createBooking(BookingStatus::Completed, '2026-12-03 10:00', $samira);
        DB::table('payments')->insert([
            'id' => (string) Str::ulid(), 'booking_id' => $booking->id, 'method' => 'cash', 'provider' => 'cash', 'status' => 'paid',
            'amount' => 10000, 'currency' => 'MAD', 'collected_by' => $samira->id, 'paid_at' => now(), 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->actingAsStaff(Role::Comptable, 'Nadia Comptable');

        $this->get('/admin')->assertOk()->assertSee('Bonjour Nadia');
        $this->assertTrue(FinanceStats::canView());
        $this->assertFalse(CoordinationStats::canView());
        $this->assertFalse(RequestsToHandle::canView());
        Livewire::test(FinanceStats::class)
            ->assertSee('100,00 DH')
            ->assertSee(trans_choice('admin.dashboard.finance.holders', 1, ['count' => 1]));

        // La coordination n'a pas ce tableau : elle a le sien.
        $this->actingAsStaff(Role::Coordinateur);
        $this->assertFalse(FinanceStats::canView());
    }
}
