<?php

namespace Tests\Feature\Professionals;

use App\Actions\Professionals\ManagePlanning;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Enums\ScheduleRequestStatus;
use App\Exceptions\ApiException;
use App\Filament\Pages\TeamPlanning;
use App\Filament\Resources\Professionals\Pages\ViewProfessional;
use App\Filament\Resources\ScheduleRequests\Pages\ListScheduleRequests;
use App\Models\AuditLog;
use App\Models\Professional;
use App\Models\ScheduleRequest;
use App\Models\User;
use App\Services\Assignment\ProfessionalMatcher;
use App\Services\Planning\TeamWeek;
use Carbon\CarbonImmutable;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Livewire\Livewire;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

/**
 * Modèle « agence » (décision du 2026-11-23) : le planning est tenu par la coordination. Le
 * soignant propose une semaine ou signale une indisponibilité ; rien ne change avant l'accord.
 */
class PlanningTest extends TestCase
{
    use CreatesAssignmentData;

    private Professional $samira;

    protected function setUp(): void
    {
        parent::setUp();
        // Lundi 7 décembre 2026, 10 h à Nador.
        $this->setUpAssignmentData();
        $this->samira = $this->createProfessional(['name' => 'Samira El Idrissi']);
    }

    private function actingAsStaff(Role $role): User
    {
        $this->flushSession();
        $staff = User::factory()->staff($role)->create();
        $staff->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($staff, 'web');

        return $staff;
    }

    private function actingAsCaregiver(?Professional $professional = null): void
    {
        Sanctum::actingAs(User::query()->findOrFail(($professional ?? $this->samira)->user_id), ['app:pro']);
    }

    // --- La coordination fixe le planning ---

    public function test_the_coordinator_sets_the_zones_and_the_weekly_template(): void
    {
        $this->actingAsStaff(Role::Coordinateur);
        $other = $this->createZone();

        Livewire::test(ViewProfessional::class, ['record' => $this->samira->id])
            ->callAction('planning', [
                'zone_ids' => [$other],
                'slots' => [
                    ['weekday' => 1, 'start_time' => '09:00', 'end_time' => '13:00'],
                    ['weekday' => 3, 'start_time' => '14:00:00', 'end_time' => '18:00:00'],
                ],
            ])
            ->assertHasNoActionErrors()
            ->assertNotified(__('admin.planning.saved'));

        $this->assertSame([$other], DB::table('professional_zone')->where('professional_id', $this->samira->id)->pluck('zone_id')->all());
        $this->assertSame([
            ['weekday' => 1, 'start_time' => '09:00', 'end_time' => '13:00'],
            ['weekday' => 3, 'start_time' => '14:00', 'end_time' => '18:00'],
        ], TeamWeek::slotsOf($this->samira->id));
        $this->assertTrue(AuditLog::query()->where('event', 'planning.updated')->exists());

        // Le soignant lit le résultat dans l'application.
        $this->actingAsCaregiver();
        $this->getJson('/api/v1/pro/profile')->assertOk()
            ->assertJsonCount(1, 'data.zones')
            ->assertJsonPath('data.availabilities.0', ['weekday' => 1, 'start_time' => '09:00', 'end_time' => '13:00']);
    }

    public function test_an_incoherent_planning_is_refused_and_nothing_changes(): void
    {
        $staff = $this->actingAsStaff(Role::Coordinateur);
        $planning = app(ManagePlanning::class);
        $before = TeamWeek::slotsOf($this->samira->id);

        $closed = $this->createZone();
        DB::table('zones')->where('id', $closed)->update(['is_active' => false]);

        $cases = [
            'zone_unavailable' => [[$closed], []],
            'availability_invalid' => [[$this->zoneId], [
                ['weekday' => 1, 'start_time' => '08:00', 'end_time' => '12:00'],
                ['weekday' => 1, 'start_time' => '11:00', 'end_time' => '15:00'],
            ]],
        ];
        foreach ($cases as $code => [$zones, $slots]) {
            try {
                $planning->set($this->samira, $staff, $zones, $slots);
                $this->fail("$code aurait dû être refusé.");
            } catch (ApiException $exception) {
                $this->assertSame($code, $exception->errorCode);
            }
        }

        try {
            $planning->set($this->samira, $staff, [$this->zoneId], [['weekday' => 2, 'start_time' => '18:00', 'end_time' => '09:00']]);
            $this->fail('Une plage qui finit avant son début aurait dû être refusée.');
        } catch (ApiException $exception) {
            $this->assertSame('availability_invalid', $exception->errorCode);
        }

        $this->assertSame($before, TeamWeek::slotsOf($this->samira->id));
        $this->assertSame([$this->zoneId], DB::table('professional_zone')->where('professional_id', $this->samira->id)->pluck('zone_id')->all());
    }

    // --- Le soignant propose, la coordination décide ---

    public function test_a_proposed_week_changes_nothing_until_the_coordinator_accepts(): void
    {
        $this->actingAsCaregiver();
        $before = TeamWeek::slotsOf($this->samira->id);

        $id = $this->postJson('/api/v1/pro/schedule-requests', [
            'kind' => 'weekly',
            'slots' => [['weekday' => 1, 'start_time' => '14:00', 'end_time' => '20:00']],
            'note' => 'Je préfère les après-midi.',
        ])->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.slots.0.start_time', '14:00')
            ->json('data.id');

        // Tant que la coordination n'a pas répondu, le planning est celui d'avant.
        $this->assertSame($before, TeamWeek::slotsOf($this->samira->id));
        // La précision du soignant est chiffrée en base.
        $this->assertStringNotContainsString('après-midi', (string) DB::table('schedule_requests')->where('id', $id)->value('note'));

        $this->actingAsStaff(Role::Coordinateur);
        Livewire::test(ListScheduleRequests::class)
            ->assertCanSeeTableRecords([ScheduleRequest::query()->findOrFail($id)])
            ->callTableAction('accept', $id)
            ->assertNotified(__('admin.schedule_requests.accepted'));

        $this->assertSame([['weekday' => 1, 'start_time' => '14:00', 'end_time' => '20:00']], TeamWeek::slotsOf($this->samira->id));
        $this->assertTrue(AuditLog::query()->where('event', 'planning.request_accepted')->exists());

        $this->actingAsCaregiver();
        $this->getJson('/api/v1/pro/schedule-requests')->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.status', 'accepted')
            ->assertJsonPath('data.0.note', 'Je préfère les après-midi.');
    }

    public function test_an_accepted_unavailability_takes_the_caregiver_out_of_the_available_ones(): void
    {
        $this->actingAsCaregiver();
        // Mardi 8 et mercredi 9 décembre : la réservation d'essai tombe le mardi à 10 h.
        $id = $this->postJson('/api/v1/pro/schedule-requests', [
            'kind' => 'unavailability', 'starts_on' => '2026-12-08', 'ends_on' => '2026-12-09',
        ])->assertCreated()->assertJsonPath('data.starts_on', '2026-12-08')->json('data.id');

        $matcher = app(ProfessionalMatcher::class);
        $this->assertTrue($matcher->candidatesFor($this->createBooking())->sole()->available);

        $staff = $this->actingAsStaff(Role::Coordinateur);
        app(ManagePlanning::class)->accept(ScheduleRequest::query()->findOrFail($id), $staff);

        // Elle reste proposée (le coordinateur peut toujours forcer), mais signalée indisponible.
        $this->assertFalse($matcher->candidatesFor($this->createBooking())->sole()->available);
        $this->assertTrue($matcher->candidatesFor($this->createBooking(BookingStatus::Confirmed, '2026-12-10 10:00'))->sole()->available);
    }

    public function test_a_refused_request_keeps_the_planning_and_tells_the_caregiver_why(): void
    {
        $this->actingAsCaregiver();
        $id = $this->postJson('/api/v1/pro/schedule-requests', [
            'kind' => 'unavailability', 'starts_on' => '2026-12-08', 'ends_on' => '2026-12-08',
        ])->json('data.id');

        $this->actingAsStaff(Role::Coordinateur);
        Livewire::test(ListScheduleRequests::class)
            ->callTableAction('refuse', $id, ['reason' => 'Équipe déjà réduite ce jour-là.'])
            ->assertNotified(__('admin.schedule_requests.refused'));

        $this->assertTrue(app(ProfessionalMatcher::class)->candidatesFor($this->createBooking())->sole()->available);

        // Une demande déjà traitée ne se décide pas deux fois.
        try {
            app(ManagePlanning::class)->accept(ScheduleRequest::query()->findOrFail($id), User::factory()->staff(Role::Coordinateur)->create());
            $this->fail('Une demande close aurait dû être refusée.');
        } catch (ApiException $exception) {
            $this->assertSame('schedule_request_closed', $exception->errorCode);
        }

        $this->actingAsCaregiver();
        $this->getJson('/api/v1/pro/schedule-requests')
            ->assertJsonPath('data.0.status', 'refused')
            ->assertJsonPath('data.0.decision_note', 'Équipe déjà réduite ce jour-là.');
    }

    public function test_requests_are_validated(): void
    {
        $this->actingAsCaregiver();

        $this->postJson('/api/v1/pro/schedule-requests', ['kind' => 'weekly'])
            ->assertStatus(422)->assertJsonValidationErrors(['slots']);
        $this->postJson('/api/v1/pro/schedule-requests', ['kind' => 'weekly', 'slots' => [
            ['weekday' => 1, 'start_time' => '08:00', 'end_time' => '12:00'],
            ['weekday' => 1, 'start_time' => '11:00', 'end_time' => '15:00'],
        ]])->assertStatus(422)->assertJsonPath('code', 'availability_invalid');
        $this->postJson('/api/v1/pro/schedule-requests', ['kind' => 'unavailability', 'starts_on' => '2026-12-08'])
            ->assertStatus(422)->assertJsonValidationErrors(['ends_on']);

        // Fin avant le début, date passée, durée excessive.
        foreach ([['2026-12-10', '2026-12-09'], ['2026-12-01', '2026-12-08'], ['2026-12-08', '2027-03-01']] as [$from, $to]) {
            $this->postJson('/api/v1/pro/schedule-requests', ['kind' => 'unavailability', 'starts_on' => $from, 'ends_on' => $to])
                ->assertStatus(422)->assertJsonPath('code', 'unavailability_invalid');
        }

        $this->assertSame(0, ScheduleRequest::query()->count());
    }

    public function test_the_caregiver_withdraws_a_pending_request_and_cannot_flood_the_coordination(): void
    {
        $this->actingAsCaregiver();
        $request = ['kind' => 'unavailability', 'starts_on' => '2026-12-08', 'ends_on' => '2026-12-08'];

        $ids = [];
        foreach (range(1, ManagePlanning::MAX_PENDING) as $ignored) {
            $ids[] = $this->postJson('/api/v1/pro/schedule-requests', $request)->assertCreated()->json('data.id');
        }
        $this->postJson('/api/v1/pro/schedule-requests', $request)
            ->assertStatus(409)->assertJsonPath('code', 'schedule_request_limit');

        $this->deleteJson("/api/v1/pro/schedule-requests/{$ids[0]}")->assertOk()->assertJsonPath('data.status', 'cancelled');
        $this->deleteJson("/api/v1/pro/schedule-requests/{$ids[0]}")
            ->assertStatus(409)->assertJsonPath('code', 'schedule_request_closed');
        $this->assertSame(ScheduleRequestStatus::Cancelled, ScheduleRequest::query()->findOrFail($ids[0])->status);

        // Une place s'est libérée.
        $this->postJson('/api/v1/pro/schedule-requests', $request)->assertCreated();
    }

    public function test_a_caregiver_only_sees_and_withdraws_their_own_requests(): void
    {
        $this->actingAsCaregiver();
        $id = $this->postJson('/api/v1/pro/schedule-requests', [
            'kind' => 'unavailability', 'starts_on' => '2026-12-08', 'ends_on' => '2026-12-08',
        ])->json('data.id');

        $this->actingAsCaregiver($this->createProfessional(['name' => 'Karim Bennani']));
        $this->getJson('/api/v1/pro/schedule-requests')->assertOk()->assertJsonCount(0, 'data');
        $this->deleteJson("/api/v1/pro/schedule-requests/$id")->assertNotFound();
        $this->assertSame(ScheduleRequestStatus::Pending, ScheduleRequest::query()->findOrFail($id)->status);
    }

    // --- Planning global ---

    public function test_the_team_planning_shows_hours_absences_and_missions_without_patient_data(): void
    {
        $staff = $this->actingAsStaff(Role::Coordinateur);
        $this->actingAsCaregiver();
        $absence = app(ManagePlanning::class)->reportUnavailability($this->samira, '2026-12-11', '2026-12-11');
        app(ManagePlanning::class)->accept($absence, $staff);
        $booking = $this->createBooking(BookingStatus::Assigned, '2026-12-08 10:00', $this->samira);

        $week = app(TeamWeek::class)->build(CarbonImmutable::parse('2026-12-09', self::TZ));

        $this->assertSame('2026-12-07', $week['days'][0]->format('Y-m-d'));
        $row = collect($week['rows'])->firstWhere('id', $this->samira->id);
        $this->assertSame(['08:00 – 20:00'], $row['days']['2026-12-07']['hours']);
        $this->assertSame([], $row['days']['2026-12-13']['hours']);
        $this->assertTrue($row['days']['2026-12-11']['off']);
        $this->assertFalse($row['days']['2026-12-08']['off']);
        $this->assertSame(
            ['time' => '10:00', 'service' => 'Pansement', 'zone' => 'Nador centre', 'reference' => $booking->reference, 'status' => 'assigned', 'awaiting' => true],
            $row['days']['2026-12-08']['missions'][0],
        );

        $this->actingAs($staff, 'web');
        Livewire::test(TeamPlanning::class)
            ->assertSee('Samira El Idrissi')
            ->assertSee('Pansement')
            ->assertSee(__('admin.planning.off'))
            // Ni l'adresse ni le nom du patient ne figurent dans le planning.
            ->assertDontSee('12 rue Al Massira')
            ->callAction('next')
            ->assertDontSee('Pansement');
    }

    public function test_only_the_coordination_reaches_the_planning(): void
    {
        $this->actingAsStaff(Role::Comptable);
        $this->get('/admin/planning')->assertForbidden();
        $this->get('/admin/schedule-requests')->assertForbidden();

        $this->actingAsStaff(Role::Coordinateur);
        $this->get('/admin/planning')->assertOk();
        $this->get('/admin/schedule-requests')->assertOk();
    }
}
