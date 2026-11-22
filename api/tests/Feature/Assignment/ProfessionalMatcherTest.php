<?php

namespace Tests\Feature\Assignment;

use App\Enums\BookingStatus;
use App\Enums\UserStatus;
use App\Models\ProfessionalCategory;
use App\Models\ProfessionalDocument;
use App\Services\Assignment\ProfessionalMatcher;
use Tests\Support\CreatesAssignmentData;
use Tests\TestCase;

class ProfessionalMatcherTest extends TestCase
{
    use CreatesAssignmentData;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpAssignmentData();
    }

    /**
     * @return list<string>
     */
    private function candidateNames(): array
    {
        return app(ProfessionalMatcher::class)->candidatesFor($this->createBooking())
            ->map(fn ($candidate) => $candidate->professional->user->name)->all();
    }

    public function test_a_verified_insured_professional_of_the_right_profession_is_a_candidate(): void
    {
        $this->createProfessional(['name' => 'Samira']);

        $this->assertSame(['Samira'], $this->candidateNames());
    }

    public function test_unverified_or_uninsured_professionals_never_receive_missions(): void
    {
        $this->createProfessional(['name' => 'Samira']);
        $this->createProfessional(['name' => 'Dossier en cours', 'status' => 'under_review']);
        $this->createProfessional(['name' => 'Suspendu', 'status' => 'suspended']);
        $this->createProfessional(['name' => 'Sans assurance', 'insurance' => null]);
        $this->createProfessional(['name' => 'Assurance non contrôlée', 'insurance' => ProfessionalDocument::STATUS_PENDING]);
        $this->createProfessional(['name' => 'Assurance refusée', 'insurance' => ProfessionalDocument::STATUS_REJECTED]);
        $this->createProfessional(['name' => 'Assurance expirée', 'insurance_expires' => '2026-11-30']);

        $this->assertSame(['Samira'], $this->candidateNames());
    }

    public function test_insurance_must_still_be_valid_on_the_day_of_care(): void
    {
        // Valable aujourd'hui (7 décembre), mais plus le jour du soin (8 décembre).
        $this->createProfessional(['name' => 'Expire la veille', 'insurance_expires' => '2026-12-07']);
        $this->createProfessional(['name' => 'Expire le jour même', 'insurance_expires' => '2026-12-08']);

        $this->assertSame(['Expire le jour même'], $this->candidateNames());
    }

    public function test_the_profession_must_match_the_service(): void
    {
        $physios = ProfessionalCategory::factory()->create();
        $this->createProfessional(['name' => 'Kinésithérapeute', 'category' => $physios]);
        $this->createProfessional(['name' => 'Infirmière']);

        $this->assertSame(['Infirmière'], $this->candidateNames());
    }

    public function test_a_suspended_account_is_excluded(): void
    {
        $professional = $this->createProfessional(['name' => 'Compte suspendu']);
        $professional->user->update(['status' => UserStatus::Suspended]);

        $this->assertSame([], $this->candidateNames());
    }

    public function test_a_professional_busy_at_that_time_is_excluded(): void
    {
        $busy = $this->createProfessional(['name' => 'Occupée']);
        $free = $this->createProfessional(['name' => 'Libre']);
        $later = $this->createProfessional(['name' => 'Occupée plus tard']);

        // Chevauche le créneau de 10 h à 10 h 30.
        $this->createBooking(BookingStatus::Assigned, '2026-12-08 10:15', $busy);
        // Ne le chevauche pas : commence quand l'autre finit.
        $this->createBooking(BookingStatus::Assigned, '2026-12-08 10:30', $later);
        // Une mission terminée ou annulée ne bloque pas.
        $this->createBooking(BookingStatus::Completed, '2026-12-08 10:00', $free);

        $this->assertEqualsCanonicalizing(['Libre', 'Occupée plus tard'], $this->candidateNames());
    }

    public function test_candidates_are_ranked_by_zone_availability_distance_then_rating(): void
    {
        $this->createProfessional(['name' => 'Hors zone', 'zone' => false, 'at' => [35.1689, -2.9336]]);
        $this->createProfessional(['name' => 'Hors agenda', 'available' => false, 'at' => [35.1689, -2.9336]]);
        $this->createProfessional(['name' => 'Loin', 'at' => [35.1850, -2.9050]]);
        $this->createProfessional(['name' => 'Proche', 'at' => [35.1690, -2.9340]]);
        $this->createProfessional(['name' => 'Position inconnue, bien notée', 'rating' => 4.9]);
        $this->createProfessional(['name' => 'Position inconnue, moins bien notée', 'rating' => 3.2]);

        $this->assertSame([
            'Proche',
            'Loin',
            'Position inconnue, bien notée',
            'Position inconnue, moins bien notée',
            'Hors agenda',
            'Hors zone',
        ], $this->candidateNames());
    }

    public function test_each_candidate_carries_the_criteria_shown_to_the_coordinator(): void
    {
        $this->createProfessional(['name' => 'Samira', 'at' => [35.1690, -2.9340], 'rating' => 4.5]);
        $this->createProfessional(['name' => 'Dimanche seulement', 'available' => false, 'zone' => false]);

        $candidates = app(ProfessionalMatcher::class)->candidatesFor($this->createBooking());

        $this->assertTrue($candidates[0]->coversZone);
        $this->assertTrue($candidates[0]->available);
        $this->assertSame(4.5, $candidates[0]->rating);
        $this->assertGreaterThan(10, $candidates[0]->distanceMeters);
        $this->assertLessThan(100, $candidates[0]->distanceMeters);

        $this->assertFalse($candidates[1]->coversZone);
        $this->assertFalse($candidates[1]->available);
        $this->assertNull($candidates[1]->distanceMeters);
    }
}
