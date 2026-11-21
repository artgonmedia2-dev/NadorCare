<?php

namespace Tests\Feature\Patients;

use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Models\Address;
use App\Models\Booking;
use App\Models\PatientProfile;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AddressApiTest extends TestCase
{
    /** Point au centre de Nador, dans la zone de test. */
    private const NADOR = ['latitude' => 35.1688, 'longitude' => -2.9335];

    /** Point à Oujda, hors de toute zone. */
    private const OUJDA = ['latitude' => 34.6814, 'longitude' => -1.9086];

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = $this->userWithRole(Role::Patient);
        Sanctum::actingAs($this->user, ['app:patient']);
    }

    private function createZone(string $slug, bool $active, string $polygon = '-2.96 35.15, -2.90 35.15, -2.90 35.19, -2.96 35.19, -2.96 35.15', int $sort = 1): string
    {
        $id = (string) Str::ulid();

        DB::insert(
            'INSERT INTO zones (id, name, slug, boundary, is_active, sort, created_at, updated_at)
             VALUES (?, ?, ?, ST_GeogFromText(?), ?, ?, now(), now())',
            [$id, json_encode(['fr' => 'Nador centre', 'ar' => 'الناظور المركز', 'en' => 'Nador centre']), $slug, "SRID=4326;MULTIPOLYGON((($polygon)))", $active, $sort]
        );

        return $id;
    }

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'label' => 'Maison',
            'line' => '12 rue Al Massira, quartier Laari Cheikh',
            'access_notes' => 'Porte verte, 2e étage',
        ], self::NADOR, $overrides);
    }

    public function test_an_address_inside_an_open_zone_is_covered(): void
    {
        $zoneId = $this->createZone('nador-centre', active: true);

        $this->postJson('/api/v1/addresses', $this->payload())
            ->assertCreated()
            ->assertJsonPath('data.label', 'Maison')
            ->assertJsonPath('data.city', 'Nador')
            ->assertJsonPath('data.latitude', 35.1688)
            ->assertJsonPath('data.longitude', -2.9335)
            ->assertJsonPath('data.zone.id', $zoneId)
            ->assertJsonPath('data.zone.name', 'Nador centre')
            ->assertJsonPath('data.is_covered', true);
    }

    public function test_the_zone_name_follows_the_requested_language(): void
    {
        $this->createZone('nador-centre', active: true);

        $this->postJson('/api/v1/addresses', $this->payload(), ['Accept-Language' => 'ar'])
            ->assertCreated()
            ->assertJsonPath('data.zone.name', 'الناظور المركز');
    }

    public function test_an_address_outside_every_zone_is_saved_but_not_covered(): void
    {
        $this->createZone('nador-centre', active: true);

        $this->postJson('/api/v1/addresses', $this->payload(self::OUJDA))
            ->assertCreated()
            ->assertJsonPath('data.zone', null)
            ->assertJsonPath('data.is_covered', false);
    }

    public function test_an_address_in_a_closed_zone_is_not_covered(): void
    {
        $this->createZone('nador-centre', active: false);

        $this->postJson('/api/v1/addresses', $this->payload())
            ->assertCreated()
            ->assertJsonPath('data.zone.name', 'Nador centre')
            ->assertJsonPath('data.is_covered', false);
    }

    public function test_an_open_zone_wins_over_a_closed_one_that_overlaps_it(): void
    {
        $this->createZone('grand-nador', active: false, polygon: '-3.10 35.05, -2.80 35.05, -2.80 35.30, -3.10 35.30, -3.10 35.05', sort: 0);
        $open = $this->createZone('nador-centre', active: true);

        $this->postJson('/api/v1/addresses', $this->payload())
            ->assertCreated()
            ->assertJsonPath('data.zone.id', $open)
            ->assertJsonPath('data.is_covered', true);
    }

    public function test_moving_an_address_recomputes_its_zone(): void
    {
        $this->createZone('nador-centre', active: true);
        $id = $this->postJson('/api/v1/addresses', $this->payload())->json('data.id');

        $this->patchJson("/api/v1/addresses/$id", self::OUJDA)
            ->assertOk()
            ->assertJsonPath('data.is_covered', false)
            ->assertJsonPath('data.label', 'Maison');

        // Changer le libellé seul ne touche ni aux coordonnées ni à la zone.
        $this->patchJson("/api/v1/addresses/$id", self::NADOR)->assertJsonPath('data.is_covered', true);
        $this->patchJson("/api/v1/addresses/$id", ['label' => 'Chez ma mère'])
            ->assertOk()
            ->assertJsonPath('data.label', 'Chez ma mère')
            ->assertJsonPath('data.latitude', 35.1688)
            ->assertJsonPath('data.is_covered', true);
    }

    public function test_coordinates_are_required_together_and_validated(): void
    {
        $this->postJson('/api/v1/addresses', ['label' => 'Maison', 'line' => '12 rue Al Massira'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['latitude', 'longitude']);

        $this->postJson('/api/v1/addresses', $this->payload(['latitude' => 120, 'longitude' => -300]))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['latitude', 'longitude']);

        $id = $this->postJson('/api/v1/addresses', $this->payload())->json('data.id');
        $this->patchJson("/api/v1/addresses/$id", ['latitude' => 35.2])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['longitude']);
    }

    public function test_an_address_can_be_linked_only_to_a_profile_of_the_same_account(): void
    {
        $mine = PatientProfile::factory()->create(['user_id' => $this->user->id]);
        $theirs = PatientProfile::factory()->create();

        $this->postJson('/api/v1/addresses', $this->payload(['patient_profile_id' => $mine->id]))
            ->assertCreated()
            ->assertJsonPath('data.patient_profile_id', $mine->id);

        $this->postJson('/api/v1/addresses', $this->payload(['patient_profile_id' => $theirs->id]))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['patient_profile_id']);
    }

    public function test_addresses_of_other_accounts_are_invisible(): void
    {
        $other = Address::factory()->create();
        $this->postJson('/api/v1/addresses', $this->payload())->assertCreated();

        $this->getJson('/api/v1/addresses')->assertOk()->assertJsonCount(1, 'data');
        $this->patchJson("/api/v1/addresses/{$other->id}", ['label' => 'Pirate'])->assertNotFound();
        $this->deleteJson("/api/v1/addresses/{$other->id}")->assertNotFound();
        $this->assertSame('Domicile', $other->fresh()->label);
    }

    public function test_an_address_is_removed_unless_care_is_planned_there(): void
    {
        $address = Address::factory()->create(['user_id' => $this->user->id]);
        $booking = Booking::factory()->inStatus(BookingStatus::Assigned)->create([
            'user_id' => $this->user->id,
            'address_id' => $address->id,
        ]);

        $this->deleteJson("/api/v1/addresses/{$address->id}")
            ->assertStatus(409)
            ->assertJsonPath('code', 'address_in_use');

        DB::table('bookings')->where('id', $booking->id)->update(['status' => BookingStatus::Cancelled->value]);

        $this->deleteJson("/api/v1/addresses/{$address->id}")->assertNoContent();
        $this->getJson('/api/v1/addresses')->assertJsonCount(0, 'data');
    }

    public function test_the_number_of_addresses_per_account_is_capped(): void
    {
        config(['nadorcare.limits.addresses' => 1]);

        $this->postJson('/api/v1/addresses', $this->payload())->assertCreated();
        $this->postJson('/api/v1/addresses', $this->payload())
            ->assertStatus(422)
            ->assertJsonPath('code', 'address_limit_reached');
    }

    public function test_a_professional_app_token_cannot_manage_addresses(): void
    {
        Sanctum::actingAs($this->user, ['app:pro']);

        $this->getJson('/api/v1/addresses')->assertForbidden();
    }
}
