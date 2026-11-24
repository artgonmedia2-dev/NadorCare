<?php

namespace Tests\Feature\Finance;

use App\Actions\Finance\ManageCaregiverAccount;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Exceptions\ApiException;
use App\Filament\Resources\CaregiverAccounts\Pages\ListCaregiverAccounts;
use App\Models\AuditLog;
use App\Models\Booking;
use App\Models\CaregiverRemuneration;
use App\Models\CashHandover;
use App\Models\Professional;
use App\Models\User;
use App\Services\Finance\CaregiverLedger;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Livewire\Livewire;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

/**
 * Modèle « agence » (règles n° 6 et 10 du 2026-11-23) : ni commission ni reversement
 * automatique. Le back-office suit, par soignant et par mois, les missions réalisées, les
 * espèces encaissées et remises, et la rémunération due saisie par le comptable.
 */
class CaregiverAccountTest extends TestCase
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

    /**
     * Mission réalisée (100 DH), réglée en espèces : encaissées par le soignant, ou restées dues.
     */
    private function completedMission(string $slot, bool $collected = true, ?Professional $professional = null): Booking
    {
        $professional ??= $this->samira;
        $booking = $this->createBooking(BookingStatus::Completed, $slot, $professional);

        DB::table('payments')->insert([
            'id' => (string) Str::ulid(), 'booking_id' => $booking->id, 'method' => 'cash', 'provider' => 'cash',
            'status' => $collected ? 'paid' : 'pending', 'amount' => $booking->total_price, 'currency' => 'MAD',
            'collected_by' => $collected ? $professional->id : null, 'paid_at' => $collected ? now() : null,
            'created_at' => now(), 'updated_at' => now(),
        ]);

        return $booking;
    }

    private function ledger(): CaregiverLedger
    {
        $ledger = app(CaregiverLedger::class);
        $ledger->forget();

        return $ledger;
    }

    private function assertRefused(string $code, callable $attempt): void
    {
        try {
            $attempt();
            $this->fail("Un refus [$code] était attendu.");
        } catch (ApiException $exception) {
            $this->assertSame($code, $exception->errorCode);
        }
    }

    // --- Relevé ---

    public function test_the_statement_counts_the_missions_and_the_cash_of_the_month(): void
    {
        $this->completedMission('2026-12-01 10:00');
        $this->completedMission('2026-12-03 15:00');
        $unpaid = $this->completedMission('2026-12-04 09:00', collected: false);
        // Hors du mois, ou pas encore réalisée : ne compte pas dans décembre.
        $this->completedMission('2026-11-28 10:00');
        $this->createBooking(BookingStatus::Assigned, '2026-12-08 10:00', $this->samira);

        $december = $this->ledger()->summary($this->samira->id, '2026-12');
        $this->assertSame(3, $december['missions']);
        $this->assertSame(30000, $december['missions_value']);
        $this->assertSame(20000, $december['collected']);
        $this->assertSame(10000, $december['uncollected']);
        $this->assertSame(0, $december['handed_over']);
        // Le solde court sur toutes les périodes : novembre compris.
        $this->assertSame(30000, $december['balance']);
        $this->assertNull($december['remuneration']);

        $november = $this->ledger()->summary($this->samira->id, '2026-11');
        $this->assertSame(1, $november['missions']);
        $this->assertSame(10000, $november['collected']);

        $missions = $this->ledger()->missions($this->samira->id, '2026-12');
        $this->assertSame(['01/12/2026', '03/12/2026', '04/12/2026'], array_column($missions, 'date'));
        $this->assertSame(['cash_collected', 'cash_collected', 'cash_due'], array_column($missions, 'payment'));
        $this->assertSame(
            ['reference' => $unpaid->reference, 'date' => '04/12/2026', 'time' => '09:00', 'service' => 'Pansement', 'amount' => 10000, 'payment' => 'cash_due'],
            $missions[2],
        );
    }

    public function test_a_caregiver_without_activity_has_an_empty_statement(): void
    {
        $summary = $this->ledger()->summary($this->samira->id, '2026-12');

        $this->assertSame(0, $summary['missions']);
        $this->assertSame(0, $summary['balance']);
        $this->assertSame([], $this->ledger()->missions($this->samira->id, '2026-12'));
    }

    // --- Remise des espèces ---

    public function test_the_accountant_records_the_cash_handed_over_by_a_caregiver(): void
    {
        $this->completedMission('2026-12-01 10:00');
        $this->completedMission('2026-12-03 15:00');
        $accountant = $this->actingAsStaff(Role::Comptable);

        Livewire::test(ListCaregiverAccounts::class)
            ->assertCanSeeTableRecords([$this->samira])
            ->assertTableColumnStateSet('missions', 2, $this->samira)
            ->assertTableColumnStateSet('collected', '200,00', $this->samira)
            ->assertTableColumnStateSet('balance', '200,00', $this->samira)
            ->callTableAction('handover', $this->samira, data: ['amount' => '150', 'handed_on' => '2026-12-05', 'note' => 'Remise en main propre'])
            ->assertHasNoTableActionErrors()
            ->assertNotified(__('admin.finance.handover_recorded'))
            ->assertTableColumnStateSet('handed_over', '150,00', $this->samira)
            ->assertTableColumnStateSet('balance', '50,00', $this->samira);

        $handover = CashHandover::query()->sole();
        $this->assertSame(15000, $handover->amount);
        $this->assertSame('2026-12-05', $handover->handed_on->format('Y-m-d'));
        $this->assertSame($accountant->id, $handover->recorded_by);
        $this->assertSame(5000, $this->ledger()->balance($this->samira->id));
        $this->assertTrue(AuditLog::query()->where('event', 'finance.cash_handed_over')->exists());
        $this->assertSame(
            [['date' => '05/12/2026', 'amount' => 15000, 'note' => 'Remise en main propre']],
            $this->ledger()->handovers($this->samira->id, '2026-12'),
        );
    }

    public function test_a_handover_never_exceeds_what_the_caregiver_holds(): void
    {
        $this->completedMission('2026-12-01 10:00');
        $accountant = $this->actingAsStaff(Role::Comptable);
        $account = app(ManageCaregiverAccount::class);

        $this->assertRefused('handover_exceeds_balance', fn () => $account->recordHandover($this->samira, $accountant, 10001, '2026-12-05'));
        $this->assertRefused('handover_invalid', fn () => $account->recordHandover($this->samira, $accountant, 0, '2026-12-05'));
        // Une remise ne se pointe pas à l'avance.
        $this->assertRefused('handover_invalid', fn () => $account->recordHandover($this->samira, $accountant, 5000, '2026-12-08'));
        $this->assertSame(0, CashHandover::query()->count());

        $account->recordHandover($this->samira, $accountant, 10000, '2026-12-07');
        $this->assertSame(0, $this->ledger()->balance($this->samira->id));

        // Plus rien à remettre : l'action disparaît.
        Livewire::test(ListCaregiverAccounts::class)->assertTableActionHidden('handover', $this->samira);
    }

    public function test_cash_left_unpaid_by_the_patient_is_not_expected_from_the_caregiver(): void
    {
        $this->completedMission('2026-12-04 09:00', collected: false);

        $this->assertSame(0, $this->ledger()->balance($this->samira->id));
        $this->assertSame(10000, $this->ledger()->summary($this->samira->id, '2026-12')['uncollected']);
    }

    // --- Rémunération due ---

    public function test_the_accountant_enters_the_remuneration_due_for_the_displayed_month(): void
    {
        $accountant = $this->actingAsStaff(Role::Comptable);

        Livewire::test(ListCaregiverAccounts::class)
            ->filterTable('period', '2026-11')
            ->assertTableColumnStateNotSet('remuneration', '4 500,50', $this->samira)
            ->callTableAction('remuneration', $this->samira, data: ['amount' => '4500.50', 'note' => 'Contrat de novembre'])
            ->assertHasNoTableActionErrors()
            ->assertNotified(__('admin.finance.remuneration_saved'))
            ->assertTableColumnStateSet('remuneration', '4 500,50', $this->samira);

        $remuneration = CaregiverRemuneration::query()->sole();
        $this->assertSame('2026-11-01', $remuneration->period->format('Y-m-d'));
        $this->assertSame(450050, $remuneration->amount);
        $this->assertSame($accountant->id, $remuneration->set_by);

        // Une correction remplace le montant du même mois, sans créer de doublon ; décembre reste vide.
        app(ManageCaregiverAccount::class)->setRemuneration($this->samira, $accountant, '2026-11', 480000);
        $this->assertSame(480000, CaregiverRemuneration::query()->sole()->amount);
        $this->assertNull($this->ledger()->summary($this->samira->id, '2026-12')['remuneration']);
        $this->assertSame(2, AuditLog::query()->where('event', 'finance.remuneration_set')->count());

        $this->assertRefused('remuneration_invalid', fn () => app(ManageCaregiverAccount::class)->setRemuneration($this->samira, $accountant, '2026-11', -1));
        $this->assertRefused('remuneration_invalid', fn () => app(ManageCaregiverAccount::class)->setRemuneration($this->samira, $accountant, 'novembre', 1000));
    }

    // --- Droits et confidentialité ---

    public function test_the_statement_shows_no_patient_data_to_the_accountant(): void
    {
        $booking = $this->completedMission('2026-12-01 10:00');
        $this->actingAsStaff(Role::Comptable);

        // La fenêtre du relevé s'ouvre sans erreur.
        Livewire::test(ListCaregiverAccounts::class)
            ->assertTableActionVisible('statement', $this->samira)
            ->mountTableAction('statement', $this->samira)
            ->assertOk();

        // Son contenu : la mission, sans rien qui désigne le patient.
        $ledger = $this->ledger();
        $statement = view('filament.finance.statement', [
            'summary' => $ledger->summary($this->samira->id, '2026-12'),
            'missions' => $ledger->missions($this->samira->id, '2026-12'),
            'handovers' => $ledger->handovers($this->samira->id, '2026-12'),
        ])->render();

        $this->assertStringContainsString($booking->reference, $statement);
        $this->assertStringContainsString('Pansement', $statement);
        $this->assertStringContainsString(__('admin.finance.payments.cash_collected'), $statement);
        $this->assertStringContainsString(__('admin.finance.no_handover'), $statement);
        $this->assertStringNotContainsString($booking->patientProfile->last_name, $statement);
        $this->assertStringNotContainsString('Al Massira', $statement);

        // Le comptable n'ouvre toujours pas les demandes de soin.
        $this->get('/admin/bookings')->assertForbidden();
    }

    public function test_the_administrator_reads_the_accounts_and_the_coordinator_has_no_access(): void
    {
        $this->completedMission('2026-12-01 10:00');

        $this->actingAsStaff(Role::Administrateur);
        $this->get('/admin/finance')->assertOk();
        Livewire::test(ListCaregiverAccounts::class)
            ->assertTableActionVisible('statement', $this->samira)
            ->assertTableActionHidden('handover', $this->samira)
            ->assertTableActionHidden('remuneration', $this->samira);

        $this->actingAsStaff(Role::Coordinateur);
        $this->get('/admin/finance')->assertForbidden();
    }
}
