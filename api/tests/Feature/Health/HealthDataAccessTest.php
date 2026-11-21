<?php

namespace Tests\Feature\Health;

use App\Actions\Health\ReadPatientRecord;
use App\Enums\AccessAction;
use App\Enums\BookingStatus;
use App\Enums\Role;
use App\Models\AccessLog;
use App\Models\Booking;
use App\Models\PatientProfile;
use App\Models\Professional;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * Loi 09-08 : chiffrement des données de santé, cloisonnement par mission, journal des accès.
 */
class HealthDataAccessTest extends TestCase
{
    private function missionFor(Professional $professional, BookingStatus $status): Booking
    {
        return Booking::factory()->inStatus($status, $professional)->create();
    }

    public function test_care_notes_and_patient_notes_are_encrypted_at_rest(): void
    {
        $booking = Booking::factory()->create();
        $profile = $booking->patientProfile;

        $rawNotes = DB::table('patient_profiles')->where('id', $profile->id)->value('care_notes');
        $rawNote = DB::table('bookings')->where('id', $booking->id)->value('patient_note');

        $this->assertNotSame($profile->care_notes, $rawNotes);
        $this->assertStringNotContainsString('pénicilline', $rawNotes);
        $this->assertStringNotContainsString('Sonner', $rawNote);
        $this->assertSame('Allergie à la pénicilline (donnée de test)', $profile->fresh()->care_notes);
    }

    public function test_the_account_holder_reads_the_record_and_the_access_is_logged(): void
    {
        $profile = PatientProfile::factory()->create();

        app(ReadPatientRecord::class)->handle($profile->user, $profile);

        $log = AccessLog::query()->sole();
        $this->assertSame($profile->user_id, $log->actor_id);
        $this->assertSame(AccessAction::View, $log->action);
        $this->assertSame($profile->id, $log->patient_profile_id);
    }

    public function test_a_professional_without_a_mission_cannot_read_the_record(): void
    {
        $profile = PatientProfile::factory()->create();
        $professional = Professional::factory()->create();

        $this->expectException(AuthorizationException::class);

        try {
            app(ReadPatientRecord::class)->handle($professional->user, $profile);
        } finally {
            $this->assertSame(0, AccessLog::query()->count());
        }
    }

    public function test_the_assigned_professional_reads_the_record_during_the_mission(): void
    {
        $professional = Professional::factory()->create();

        foreach (BookingStatus::activeMission() as $status) {
            $booking = $this->missionFor($professional, $status);

            app(ReadPatientRecord::class)->handle($professional->user, $booking->patientProfile, $booking);

            $log = AccessLog::query()->where('booking_id', $booking->id)->sole();
            $this->assertSame($professional->user_id, $log->actor_id);
            $this->assertSame(Role::Professionnel->value, $log->actor_role);
        }
    }

    public function test_a_mission_gives_no_access_to_other_patients(): void
    {
        $professional = Professional::factory()->create();
        $this->missionFor($professional, BookingStatus::InProgress);
        $otherPatient = PatientProfile::factory()->create();

        $this->assertFalse($professional->user->can('viewHealthData', $otherPatient));
    }

    public function test_a_booking_not_yet_assigned_gives_no_access(): void
    {
        $professional = Professional::factory()->create();

        foreach ([BookingStatus::Pending, BookingStatus::Confirmed, BookingStatus::Cancelled] as $status) {
            $booking = $this->missionFor($professional, $status);
            $this->assertFalse($professional->user->can('viewHealthData', $booking->patientProfile), $status->value);
        }
    }

    public function test_access_ends_after_the_report_window_following_completion(): void
    {
        $professional = Professional::factory()->create();
        $booking = $this->missionFor($professional, BookingStatus::Completed);
        $booking->statusHistory()->create(['from_status' => BookingStatus::InProgress, 'to_status' => BookingStatus::Completed]);

        $this->assertTrue($professional->user->can('viewHealthData', $booking->patientProfile));

        $this->travel(config('nadorcare.health.post_completion_access_hours') + 1)->hours();

        $this->assertFalse($professional->user->can('viewHealthData', $booking->patientProfile));
    }

    public function test_coordination_has_access_but_the_accountant_does_not(): void
    {
        $profile = PatientProfile::factory()->create();

        $this->assertTrue($this->userWithRole(Role::Coordinateur)->can('viewHealthData', $profile));
        $this->assertFalse($this->userWithRole(Role::Comptable)->can('viewHealthData', $profile));
        $this->assertFalse($this->userWithRole(Role::Patient)->can('viewHealthData', $profile));
    }

    public function test_the_access_log_cannot_be_modified_or_deleted(): void
    {
        $profile = PatientProfile::factory()->create();
        app(ReadPatientRecord::class)->handle($profile->user, $profile);
        $log = AccessLog::query()->sole();

        foreach ([
            fn () => DB::table('access_logs')->where('id', $log->id)->update(['actor_id' => null]),
            fn () => DB::table('access_logs')->where('id', $log->id)->delete(),
        ] as $tamper) {
            try {
                DB::transaction($tamper);
                $this->fail('Le journal des accès a pu être modifié.');
            } catch (QueryException $e) {
                $this->assertStringContainsString('insertion seule', $e->getMessage());
            }
        }

        $this->assertSame(1, AccessLog::query()->count());
    }
}
