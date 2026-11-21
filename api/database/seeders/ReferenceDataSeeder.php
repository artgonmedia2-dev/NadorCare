<?php

namespace Database\Seeders;

use App\Models\ProfessionalCategory;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Données de référence : catégories de professionnels (§2), paramètres de gestion (§4, §5)
 * et une zone de démonstration. Le catalogue des services et la grille tarifaire attendent
 * la décision du client (point à trancher n° 3).
 */
class ReferenceDataSeeder extends Seeder
{
    private const DOCUMENTS = ['identity', 'diploma', 'practice_authorization', 'rc_insurance'];

    public function run(): void
    {
        $this->seedProfessionalCategories();
        $this->seedSettings();
        $this->seedDemoZone();
    }

    private function seedProfessionalCategories(): void
    {
        $categories = [
            ['general_practitioner', 'Médecin généraliste', 'طبيب عام', 'General practitioner', true],
            ['specialist_physician', 'Médecin spécialiste', 'طبيب مختص', 'Specialist physician', true],
            ['nurse', 'Infirmier', 'ممرض', 'Nurse', false],
            ['physiotherapist', 'Kinésithérapeute', 'أخصائي الترويض الطبي', 'Physiotherapist', false],
            ['speech_therapist', 'Orthophoniste', 'أخصائي تقويم النطق', 'Speech therapist', false],
            ['psychomotor_therapist', 'Psychomotricien', 'أخصائي نفسي حركي', 'Psychomotor therapist', false],
            ['midwife', 'Sage-femme', 'قابلة', 'Midwife', true],
            ['care_assistant', 'Aide-soignant', 'مساعد في العلاج', 'Care assistant', false],
            ['home_carer', 'Auxiliaire de vie', 'مساعد الحياة اليومية', 'Home carer', false],
        ];

        foreach ($categories as [$code, $fr, $ar, $en, $hasOrder]) {
            ProfessionalCategory::updateOrCreate(['code' => $code], [
                'name' => ['fr' => $fr, 'ar' => $ar, 'en' => $en],
                'has_order' => $hasOrder,
                'required_document_types' => $hasOrder ? [...self::DOCUMENTS, 'order_registration'] : self::DOCUMENTS,
                'is_active' => true,
            ]);
        }
    }

    /**
     * Valeurs de départ, toutes modifiables dans le back-office.
     */
    private function seedSettings(): void
    {
        $settings = [
            'booking.free_cancellation_minutes' => 120,
            'booking.escalation_minutes' => 10,
            'offer.response_seconds' => 120,
            'location.retention_days' => 30,
        ];

        foreach ($settings as $key => $value) {
            DB::table('settings')->insertOrIgnore([
                'key' => $key,
                'value' => json_encode($value),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Rectangle approximatif autour du centre de Nador, pour le développement uniquement.
     * Le vrai découpage se dessine dans le back-office (lot 6).
     */
    private function seedDemoZone(): void
    {
        if (DB::table('zones')->where('slug', 'nador-centre')->exists()) {
            return;
        }

        DB::insert(
            "INSERT INTO zones (id, name, slug, boundary, is_active, sort, created_at, updated_at)
             VALUES (?, ?, 'nador-centre', ST_GeogFromText(?), true, 1, now(), now())",
            [
                (string) Str::ulid(),
                json_encode(['fr' => 'Nador centre (démo)', 'ar' => 'الناظور المركز (تجريبي)', 'en' => 'Nador centre (demo)']),
                'SRID=4326;MULTIPOLYGON(((-2.96 35.15, -2.90 35.15, -2.90 35.19, -2.96 35.19, -2.96 35.15)))',
            ]
        );
    }
}
