<?php

namespace Database\Seeders;

use App\Enums\Role;
use App\Enums\UserStatus;
use App\Enums\VerificationStatus;
use App\Models\Professional;
use App\Models\ProfessionalCategory;
use App\Models\ProfessionalDocument;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * Professionnels de DÉMONSTRATION, pour essayer l'affectation tant que l'inscription
 * des professionnels (tâche 5.1) et la vérification des justificatifs (tâche 6.5) n'existent pas.
 *
 * Personnes fictives, numéros de téléphone fictifs, justificatifs sans fichier réel.
 * Ne fait pas partie de DatabaseSeeder et refuse de tourner en production :
 *
 *     php artisan db:seed --class=DemoProfessionalsSeeder
 */
class DemoProfessionalsSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->isProduction()) {
            throw new RuntimeException('Les professionnels de démonstration ne s\'installent pas en production.');
        }

        $this->call([RolesAndPermissionsSeeder::class, ReferenceDataSeeder::class]);

        $zoneId = DB::table('zones')->where('slug', 'nador-centre')->value('id');
        $categories = ProfessionalCategory::query()->pluck('id', 'code');

        $people = [
            ['+212600000101', 'Samira El Idrissi (démo)', 'nurse', [35.1702, -2.9310], 4.8],
            ['+212600000102', 'Youssef Amrani (démo)', 'nurse', [35.1760, -2.9200], 4.4],
            ['+212600000103', 'Dr Nadia Bouzid (démo)', 'general_practitioner', [35.1690, -2.9280], 4.9],
            ['+212600000104', 'Karim Tahiri (démo)', 'physiotherapist', [35.1655, -2.9390], 4.6],
            ['+212600000105', 'Fatima Ouali (démo)', 'care_assistant', [35.1725, -2.9255], 4.7],
        ];

        foreach ($people as [$phone, $name, $category, [$latitude, $longitude], $rating]) {
            $user = User::query()->firstOrNew(['phone' => $phone]);
            $user->fill(['name' => $name, 'locale' => 'fr', 'status' => UserStatus::Active]);
            $user->phone_verified_at ??= now();
            $user->save();
            $user->syncRoles([Role::Professionnel->value]);

            $professional = Professional::query()->firstOrNew(['user_id' => $user->id]);
            $professional->fill([
                'professional_category_id' => $categories[$category],
                'verification_status' => VerificationStatus::Verified,
                'is_online' => true,
            ]);
            $professional->save();

            DB::update(
                'UPDATE professionals SET last_location = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
                    last_location_at = now(), rating_avg = ?, rating_count = 12, verified_at = now() WHERE id = ?',
                [$longitude, $latitude, $rating, $professional->id]
            );

            if ($zoneId) {
                $professional->zones()->syncWithoutDetaching([$zoneId]);
            }

            // Du lundi au samedi, de 8 h à 20 h.
            DB::table('availabilities')->where('professional_id', $professional->id)->delete();
            foreach (range(1, 6) as $weekday) {
                DB::table('availabilities')->insert([
                    'id' => (string) Str::ulid(), 'professional_id' => $professional->id, 'weekday' => $weekday,
                    'start_time' => '08:00', 'end_time' => '20:00', 'created_at' => now(), 'updated_at' => now(),
                ]);
            }

            // Assurance responsabilité civile approuvée, sans fichier réel derrière.
            if (! $professional->documents()->where('type', ProfessionalDocument::TYPE_RC_INSURANCE)->exists()) {
                $fileId = (string) Str::ulid();
                DB::table('files')->insert([
                    'id' => $fileId, 'disk' => 'local', 'path' => "demo/$fileId.enc", 'category' => 'professional_document',
                    'mime' => 'application/pdf', 'size' => 0, 'sha256' => str_repeat('0', 64),
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                ProfessionalDocument::create([
                    'professional_id' => $professional->id,
                    'type' => ProfessionalDocument::TYPE_RC_INSURANCE,
                    'file_id' => $fileId,
                    'expires_at' => now()->addYear()->format('Y-m-d'),
                    'status' => ProfessionalDocument::STATUS_APPROVED,
                ]);
            }
        }
    }
}
