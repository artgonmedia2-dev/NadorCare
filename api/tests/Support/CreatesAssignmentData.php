<?php

namespace Tests\Support;

use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\Professional;
use App\Models\ProfessionalCategory;
use App\Models\ProfessionalDocument;
use App\Models\Service;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Données de test pour l'affectation : une zone, un service, des professionnels
 * en règle ou non, et une réservation confirmée à affecter.
 */
trait CreatesAssignmentData
{
    protected const TZ = 'Africa/Casablanca';

    protected string $zoneId;

    protected ProfessionalCategory $nurses;

    protected Service $nursingService;

    protected function setUpAssignmentData(): void
    {
        // Lundi 7 décembre 2026, 10 h à Nador.
        $this->travelTo(CarbonImmutable::parse('2026-12-07 10:00', self::TZ));

        $this->zoneId = $this->createZone();
        $this->nurses = ProfessionalCategory::factory()->create(['name' => ['fr' => 'Infirmier', 'ar' => 'ممرض', 'en' => 'Nurse']]);
        $this->nursingService = Service::factory()->create([
            'professional_category_id' => $this->nurses->id,
            'name' => ['fr' => 'Pansement', 'ar' => 'تضميد', 'en' => 'Wound dressing'],
            'duration_minutes' => 30,
        ]);
    }

    protected function createZone(): string
    {
        $id = (string) Str::ulid();
        DB::insert(
            'INSERT INTO zones (id, name, slug, boundary, is_active, sort, created_at, updated_at) VALUES (?, ?, ?, ST_GeogFromText(?), true, 1, now(), now())',
            [$id, json_encode(['fr' => 'Nador centre', 'ar' => 'الناظور المركز']), 'zone-'.Str::random(6), 'SRID=4326;MULTIPOLYGON(((-2.96 35.15, -2.90 35.15, -2.90 35.19, -2.96 35.19, -2.96 35.15)))']
        );

        return $id;
    }

    /**
     * Professionnel en règle : vérifié, assuré, de la bonne profession, qui couvre la zone
     * et travaille du lundi au samedi de 8 h à 20 h.
     *
     * @param  array{name?: string, category?: ProfessionalCategory, insurance?: string|null, insurance_expires?: string, zone?: bool, available?: bool, at?: array{float, float}|null, rating?: float|null, status?: string}  $options
     */
    protected function createProfessional(array $options = []): Professional
    {
        $professional = Professional::factory()->create([
            'professional_category_id' => ($options['category'] ?? $this->nurses)->id,
            'verification_status' => $options['status'] ?? 'verified',
        ]);
        $professional->user->update(['name' => $options['name'] ?? 'Soignant '.Str::random(4)]);

        $insurance = array_key_exists('insurance', $options) ? $options['insurance'] : ProfessionalDocument::STATUS_APPROVED;
        if ($insurance !== null) {
            $fileId = (string) Str::ulid();
            DB::table('files')->insert([
                'id' => $fileId, 'disk' => 'local', 'path' => "professional_document/$fileId.enc", 'category' => 'professional_document',
                'mime' => 'application/pdf', 'size' => 10, 'sha256' => str_repeat('0', 64), 'created_at' => now(), 'updated_at' => now(),
            ]);
            ProfessionalDocument::create([
                'professional_id' => $professional->id,
                'type' => ProfessionalDocument::TYPE_RC_INSURANCE,
                'file_id' => $fileId,
                'expires_at' => $options['insurance_expires'] ?? '2027-06-30',
                'status' => $insurance,
            ]);
        }

        if ($options['zone'] ?? true) {
            $professional->zones()->attach($this->zoneId);
        }

        if ($options['available'] ?? true) {
            foreach (range(1, 6) as $weekday) {
                DB::table('availabilities')->insert([
                    'id' => (string) Str::ulid(), 'professional_id' => $professional->id, 'weekday' => $weekday,
                    'start_time' => '08:00', 'end_time' => '20:00', 'created_at' => now(), 'updated_at' => now(),
                ]);
            }
        }

        if (($options['at'] ?? null) !== null) {
            [$latitude, $longitude] = $options['at'];
            DB::update(
                'UPDATE professionals SET last_location = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, last_location_at = now() WHERE id = ?',
                [$longitude, $latitude, $professional->id]
            );
        }

        if (($options['rating'] ?? null) !== null) {
            DB::table('professionals')->where('id', $professional->id)->update(['rating_avg' => $options['rating'], 'rating_count' => 10]);
        }

        return $professional->fresh();
    }

    /**
     * Réservation à affecter : mardi 8 décembre 2026 de 10 h à 10 h 30, au centre de Nador.
     */
    protected function createBooking(BookingStatus $status = BookingStatus::Confirmed, string $slot = '2026-12-08 10:00', ?Professional $professional = null): Booking
    {
        $start = CarbonImmutable::parse($slot, self::TZ);

        return Booking::factory()->inStatus($status, $professional)->create([
            'service_id' => $this->nursingService->id,
            'scheduled_at' => $start,
            'scheduled_end_at' => $start->addMinutes(30),
            'address_snapshot' => [
                'label' => 'Maison', 'line' => '12 rue Al Massira', 'city' => 'Nador', 'access_notes' => 'Porte verte',
                'latitude' => 35.1688, 'longitude' => -2.9335, 'zone_id' => $this->zoneId,
            ],
        ]);
    }
}
