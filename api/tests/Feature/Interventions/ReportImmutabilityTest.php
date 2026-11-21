<?php

namespace Tests\Feature\Interventions;

use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\Professional;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

/**
 * Règle du cahier des charges (§5) : un compte rendu validé n'est plus modifiable,
 * toute correction crée un avenant. La règle est garantie par la base elle-même.
 */
class ReportImmutabilityTest extends TestCase
{
    private function createReport(?string $validatedAt, int $version = 1, ?string $parentId = null, ?string $interventionId = null): array
    {
        if ($interventionId === null) {
            $professional = Professional::factory()->create();
            $booking = Booking::factory()->inStatus(BookingStatus::InProgress, $professional)->create();
            $interventionId = (string) Str::ulid();

            DB::table('interventions')->insert([
                'id' => $interventionId, 'booking_id' => $booking->id, 'professional_id' => $professional->id,
                'arrived_at' => now(), 'created_at' => now(), 'updated_at' => now(),
            ]);
            $authorId = $professional->user_id;
        } else {
            $authorId = DB::table('intervention_reports')->where('intervention_id', $interventionId)->value('author_id');
        }

        $reportId = (string) Str::ulid();
        DB::table('intervention_reports')->insert([
            'id' => $reportId, 'intervention_id' => $interventionId, 'version' => $version, 'parent_report_id' => $parentId,
            'observations' => encrypt('Pansement refait, plaie propre'), 'author_id' => $authorId,
            'validated_at' => $validatedAt, 'created_at' => now(), 'updated_at' => now(),
        ]);

        return [$reportId, $interventionId];
    }

    public function test_a_draft_report_can_still_be_edited(): void
    {
        [$reportId] = $this->createReport(null);

        DB::table('intervention_reports')->where('id', $reportId)->update(['observations' => encrypt('Texte corrigé')]);

        $this->assertSame('Texte corrigé', decrypt(DB::table('intervention_reports')->where('id', $reportId)->value('observations')));
    }

    public function test_a_validated_report_cannot_be_edited_or_deleted(): void
    {
        [$reportId] = $this->createReport(now()->toDateTimeString());

        foreach ([
            fn () => DB::table('intervention_reports')->where('id', $reportId)->update(['observations' => encrypt('Falsifié')]),
            fn () => DB::table('intervention_reports')->where('id', $reportId)->delete(),
        ] as $tamper) {
            try {
                DB::transaction($tamper);
                $this->fail('Un compte rendu validé a pu être modifié.');
            } catch (QueryException $e) {
                $this->assertStringContainsString('avenant', $e->getMessage());
            }
        }

        $this->assertSame('Pansement refait, plaie propre', decrypt(DB::table('intervention_reports')->where('id', $reportId)->value('observations')));
    }

    public function test_a_correction_is_recorded_as_a_new_version(): void
    {
        [$reportId, $interventionId] = $this->createReport(now()->toDateTimeString());

        $this->createReport(now()->toDateTimeString(), version: 2, parentId: $reportId, interventionId: $interventionId);

        $this->assertSame([1, 2], DB::table('intervention_reports')->where('intervention_id', $interventionId)->orderBy('version')->pluck('version')->all());
    }
}
