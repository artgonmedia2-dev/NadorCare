<?php

namespace Tests\Feature\Assignment;

use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\Service;
use App\Services\Assignment\ProfessionalMatcher;
use Carbon\CarbonImmutable;
use Database\Seeders\DemoCatalogueSeeder;
use Database\Seeders\DemoProfessionalsSeeder;
use Illuminate\Support\Facades\DB;
use RuntimeException;
use Tests\TestCase;

class DemoProfessionalsSeederTest extends TestCase
{
    public function test_demo_professionals_are_eligible_for_the_demo_catalogue_and_ranked_by_distance(): void
    {
        $this->travelTo(CarbonImmutable::parse('2026-12-07 10:00', 'Africa/Casablanca'));
        $this->seed(DemoCatalogueSeeder::class);
        $this->seed(DemoProfessionalsSeeder::class);
        $this->seed(DemoProfessionalsSeeder::class); // rejouable sans doublon

        $this->assertSame(5, Professional::query()->count());

        $start = CarbonImmutable::parse('2026-12-08 10:00', 'Africa/Casablanca');
        $booking = Booking::factory()->inStatus(BookingStatus::Confirmed)->create([
            'service_id' => Service::query()->where('slug', 'pansement')->value('id'),
            'scheduled_at' => $start,
            'scheduled_end_at' => $start->addMinutes(30),
            'address_snapshot' => [
                'line' => '12 rue Al Massira', 'latitude' => 35.1688, 'longitude' => -2.9335,
                'zone_id' => DB::table('zones')->where('slug', 'nador-centre')->value('id'),
            ],
        ]);

        $candidates = app(ProfessionalMatcher::class)->candidatesFor($booking);

        // Un pansement est un soin infirmier : les deux infirmiers, le plus proche d'abord.
        $this->assertSame(
            ['Samira El Idrissi (démo)', 'Youssef Amrani (démo)'],
            $candidates->map(fn ($candidate) => $candidate->professional->user->name)->all(),
        );
        $this->assertTrue($candidates->every(fn ($candidate) => $candidate->coversZone && $candidate->available));
    }

    public function test_demo_professionals_are_never_installed_in_production(): void
    {
        $this->app->detectEnvironment(fn () => 'production');

        $this->expectException(RuntimeException::class);
        $this->app->make(DemoProfessionalsSeeder::class)->run();
    }
}
