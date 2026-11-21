<?php

namespace Tests\Feature\Bookings;

use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Filament\Resources\Bookings\Pages\ListBookings;
use App\Filament\Resources\Holidays\Pages\CreateHoliday;
use App\Filament\Resources\Settings\Pages\EditSetting;
use App\Filament\Resources\Surcharges\Pages\CreateSurcharge;
use App\Filament\Resources\Surcharges\Pages\EditSurcharge;
use App\Models\Booking;
use App\Models\Holiday;
use App\Models\Setting;
use App\Models\Surcharge;
use App\Models\User;
use App\Services\Settings\Settings;
use Database\Seeders\ReferenceDataSeeder;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Livewire\Livewire;
use Tests\TestCase;

class BookingBackOfficeTest extends TestCase
{
    private function staff(Role $role): User
    {
        $this->flushSession();
        $user = User::factory()->staff($role)->create();
        $user->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());
        $this->actingAs($user);

        return $user;
    }

    // --- File des demandes ---

    public function test_the_coordinator_sees_pending_requests_and_confirms_one(): void
    {
        $coordinator = $this->staff(Role::Coordinateur);
        $pending = Booking::factory()->create();
        $confirmed = Booking::factory()->inStatus(BookingStatus::Confirmed)->create();

        $this->get('/admin/bookings')->assertOk();

        Livewire::test(ListBookings::class)
            ->assertCanSeeTableRecords([$pending])
            ->assertCanNotSeeTableRecords([$confirmed]) // filtre par défaut : en attente
            ->callTableAction('confirm', $pending)
            ->assertNotified(__('admin.bookings.confirmed'));

        $this->assertSame(BookingStatus::Confirmed, $pending->fresh()->status);

        $history = $pending->statusHistory()->sole();
        $this->assertSame($coordinator->id, $history->actor_id);
        $this->assertSame(Role::Coordinateur->value, $history->actor_role);
    }

    public function test_the_coordinator_cancels_a_request_with_a_reason(): void
    {
        $this->staff(Role::Coordinateur);
        $booking = Booking::factory()->create();

        Livewire::test(ListBookings::class)
            ->callTableAction('cancel', $booking, data: ['reason' => 'Patient injoignable'])
            ->assertHasNoTableActionErrors();

        $booking->refresh();
        $this->assertSame(BookingStatus::Cancelled, $booking->status);
        $this->assertSame('Patient injoignable', $booking->cancellation_reason);

        // Sans motif, l'annulation est refusée.
        $other = Booking::factory()->create();
        Livewire::test(ListBookings::class)
            ->callTableAction('cancel', $other, data: ['reason' => ''])
            ->assertHasTableActionErrors(['reason' => 'required']);
        $this->assertSame(BookingStatus::Pending, $other->fresh()->status);
    }

    public function test_a_confirmed_request_has_no_confirm_button_and_the_list_shows_no_health_data(): void
    {
        $this->staff(Role::Coordinateur);
        $confirmed = Booking::factory()->inStatus(BookingStatus::Confirmed)->create();

        Livewire::test(ListBookings::class)
            ->filterTable('status', BookingStatus::Confirmed->value)
            ->assertCanSeeTableRecords([$confirmed])
            ->assertTableActionHidden('confirm', $confirmed)
            ->assertTableActionVisible('cancel', $confirmed)
            ->assertDontSee('Sonner deux fois'); // note du patient
    }

    public function test_the_accountant_has_no_access_to_requests(): void
    {
        $this->staff(Role::Comptable);

        $this->get('/admin/bookings')->assertForbidden();
    }

    // --- Majorations, jours fériés, paramètres ---

    public function test_the_administrator_creates_a_fixed_night_surcharge_typed_in_dirhams(): void
    {
        $this->staff(Role::Administrateur);

        Livewire::test(CreateSurcharge::class)
            ->fillForm([
                'name' => ['fr' => 'Nuit', 'ar' => 'ليل', 'en' => 'Night'],
                'type' => 'night',
                'mode' => 'fixed',
                'value' => 30,
                'config' => ['start' => '21:00', 'end' => '07:00'],
                'is_active' => true,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $surcharge = Surcharge::query()->sole();
        $this->assertSame(3000, $surcharge->value);
        $this->assertSame('21:00', $surcharge->config['start']);
        $this->assertSame('07:00', $surcharge->config['end']);

        // À la réouverture, la valeur s'affiche de nouveau en dirhams.
        Livewire::test(EditSurcharge::class, ['record' => $surcharge->id])
            ->assertSchemaStateSet(['value' => 30]);
    }

    public function test_a_percentage_surcharge_is_stored_as_typed(): void
    {
        $this->staff(Role::Administrateur);

        Livewire::test(CreateSurcharge::class)
            ->fillForm([
                'name' => ['fr' => 'Jour férié'],
                'type' => 'holiday',
                'mode' => 'percent',
                'value' => 50,
                'is_active' => true,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertSame(50, Surcharge::query()->sole()->value);
    }

    public function test_the_administrator_adds_a_public_holiday(): void
    {
        $this->staff(Role::Administrateur);

        Livewire::test(CreateHoliday::class)
            ->fillForm(['date' => '2027-01-11', 'name' => ['fr' => 'Manifeste de l\'indépendance']])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertSame('2027-01-11', Holiday::query()->sole()->date->format('Y-m-d'));

        Livewire::test(CreateHoliday::class)
            ->fillForm(['date' => '2027-01-11', 'name' => ['fr' => 'Doublon']])
            ->call('create')
            ->assertHasFormErrors(['date' => 'unique']);
    }

    public function test_booking_settings_are_edited_with_validation(): void
    {
        $this->staff(Role::Administrateur);
        $this->seed(ReferenceDataSeeder::class);

        $this->get('/admin/settings')->assertOk()->assertSee(__('admin.settings.keys.booking_day_start'));

        Livewire::test(EditSetting::class, ['record' => Settings::DAY_END])
            ->fillForm(['value' => '22:30'])
            ->call('save')
            ->assertHasNoFormErrors();
        $this->assertSame('22:30', app(Settings::class)->get(Settings::DAY_END));

        Livewire::test(EditSetting::class, ['record' => Settings::DAY_END])
            ->fillForm(['value' => '25h'])
            ->call('save')
            ->assertHasFormErrors(['value']);

        Livewire::test(EditSetting::class, ['record' => Settings::LATE_CANCELLATION_FEE_PERCENT])
            ->fillForm(['value' => '30'])
            ->call('save')
            ->assertHasNoFormErrors();
        $this->assertSame(30, app(Settings::class)->int(Settings::LATE_CANCELLATION_FEE_PERCENT));

        // Chaque paramètre connu a une ligne et un libellé traduit.
        $this->assertSame(count(Settings::DEFAULTS), Setting::query()->count());
        foreach (array_keys(Settings::DEFAULTS) as $key) {
            $this->assertNotSame('admin.settings.keys.'.str_replace('.', '_', $key), __('admin.settings.keys.'.str_replace('.', '_', $key)), $key);
        }
    }

    public function test_only_the_administrator_edits_surcharges_holidays_and_settings(): void
    {
        $this->staff(Role::Coordinateur);

        foreach (['/admin/surcharges', '/admin/holidays', '/admin/settings'] as $url) {
            $this->get($url)->assertForbidden();
        }

        $this->staff(Role::Administrateur);
        foreach (['/admin/surcharges', '/admin/holidays', '/admin/settings', '/admin/surcharges/create'] as $url) {
            $this->get($url)->assertOk();
        }
    }
}
