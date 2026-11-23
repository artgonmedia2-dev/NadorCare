<?php

namespace Database\Seeders;

use App\Models\ProfessionalCategory;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\Surcharge;
use Illuminate\Database\Seeder;

/**
 * Catalogue et grille tarifaire de Nador Care, fournis par le client le 2026-11-23.
 *
 * Règle de prix donnée par le client : le tarif de jour de la grille de référence, plus 150 DH
 * par service. Le tarif du soir de cette grille (50 DH de plus, de 19 h à 8 h) devient la
 * majoration de nuit, appliquée par `PriceCalculator`.
 *
 * Ce que ce seeder ne couvre pas, faute de modèle ou de décision (voir
 * `docs/03-questions-ouvertes.md`) :
 * - la garde-malade (forfaits à la journée et à la semaine, gardes de nuit) : elle ne rentre pas
 *   dans une réservation par créneau ;
 * - la taxe : la grille de référence est hors taxe ;
 * - le supplément de déplacement hors de la ville ;
 * - les durées, estimées ici, et l'exigence d'ordonnance, à confirmer.
 *
 * Il retire du catalogue les services de démonstration, dont les prix étaient inventés.
 *
 *     php artisan db:seed --class=NadorCatalogueSeeder
 */
class NadorCatalogueSeeder extends Seeder
{
    /** Ajouté au tarif de jour de la grille de référence, en centimes. */
    private const MARKUP = 15000;

    /** Services du catalogue de démonstration, remplacés par cette grille. */
    private const DEMO_SLUGS = [
        'injection', 'pansement', 'prise-de-sang', 'consultation-a-domicile', 'seance-de-reeducation', 'aide-a-la-toilette',
    ];

    public function run(): void
    {
        $this->call(ReferenceDataSeeder::class);

        $professions = ProfessionalCategory::query()->pluck('id', 'code');

        foreach ($this->catalogue() as $position => [$slug, $name, $profession, $services]) {
            $category = ServiceCategory::updateOrCreate(['slug' => $slug], ['name' => $name, 'sort' => $position + 1, 'is_active' => true]);

            foreach ($services as $order => $row) {
                [$serviceSlug, $serviceName, $description, $duration, $referencePrice, $prescription, $series] = $row;
                // Huitième valeur facultative : le prix est celui fixé par le client, sans les 150 DH.
                $priceIsFinal = $row[7] ?? false;
                // Neuvième valeur facultative : `remote` pour une téléconsultation.
                $remote = ($row[8] ?? null) === 'remote';

                $service = Service::updateOrCreate(['slug' => $serviceSlug], [
                    'service_category_id' => $category->id,
                    'professional_category_id' => $professions[$profession],
                    'name' => $serviceName,
                    'description' => $description,
                    'duration_minutes' => $duration,
                    'base_price' => $referencePrice * 100 + ($priceIsFinal ? 0 : self::MARKUP),
                    'requires_prescription' => $prescription,
                    'allows_series' => $series,
                    'delivery_mode' => $remote ? 'remote' : 'home',
                    'sort' => $order + 1,
                ]);

                // Une téléconsultation naît désactivée : c'est le back-office qui l'ouvrira, une fois les
                // conditions de lancement validées. Relancer ce seeder ne touche plus à son état.
                if ($remote) {
                    if ($service->wasRecentlyCreated) {
                        $service->update(['is_active' => false]);
                    }
                } else {
                    $service->update(['is_active' => true]);
                }
            }
        }

        Service::query()->whereIn('slug', self::DEMO_SLUGS)->update(['is_active' => false]);
        // Une catégorie de démonstration qui n'a plus de service actif ne s'affiche plus.
        ServiceCategory::query()
            ->whereDoesntHave('services', fn ($query) => $query->where('is_active', true))
            ->update(['is_active' => false]);

        Surcharge::updateOrCreate(['type' => Surcharge::TYPE_NIGHT], [
            'name' => ['fr' => 'Majoration du soir (19 h à 8 h)', 'ar' => 'زيادة المساء (من 19:00 إلى 8:00)', 'en' => 'Evening surcharge (7 pm to 8 am)'],
            'mode' => Surcharge::MODE_FIXED,
            'value' => 5000,
            'config' => ['start' => '19:00', 'end' => '08:00'],
            'is_active' => true,
        ]);
    }

    /**
     * Chaque service : identifiant, nom, description, durée estimée en minutes, tarif de jour de
     * la grille de référence en dirhams (avant les 150 DH), ordonnance exigée, série possible.
     *
     * @return list<array{string, array<string, string>, string, list<array<int, mixed>>}>
     */
    private function catalogue(): array
    {
        return [
            // Tarif fixé directement par le client le 2026-11-23 : 500 DH, sans les 150 DH de la règle générale.
            ['medecine-a-domicile', ['fr' => 'Médecine à domicile', 'ar' => 'الطب في المنزل', 'en' => 'Doctor at home'], 'general_practitioner', [
                ['consultation-medecin-generaliste', ['fr' => 'Consultation d\'un médecin généraliste', 'ar' => 'استشارة طبيب عام', 'en' => 'General practitioner consultation'],
                    ['fr' => 'Visite d\'un médecin généraliste à domicile : examen, diagnostic et ordonnance si nécessaire.', 'ar' => 'زيارة طبيب عام في المنزل: فحص وتشخيص ووصفة طبية عند الحاجة.', 'en' => 'Visit from a general practitioner at home: examination, diagnosis and prescription if needed.'],
                    30, 500, false, false, true],
            ]],
            // Première phase de la téléconsultation (décision du 2026-11-23) : médecin généraliste seulement,
            // 20 minutes, 150 DH. Créée désactivée, et invisible tant que la téléconsultation est fermée.
            ['teleconsultation', ['fr' => 'Téléconsultation', 'ar' => 'استشارة عن بعد', 'en' => 'Teleconsultation'], 'general_practitioner', [
                ['teleconsultation-medecin-generaliste', ['fr' => 'Téléconsultation avec un médecin généraliste', 'ar' => 'استشارة عن بعد مع طبيب عام', 'en' => 'Teleconsultation with a general practitioner'],
                    ['fr' => 'Consultation d\'un médecin généraliste par appel vidéo, dans l\'application.', 'ar' => 'استشارة طبيب عام عبر مكالمة فيديو داخل التطبيق.', 'en' => 'Consultation with a general practitioner by video call, in the app.'],
                    20, 150, false, false, true, 'remote'],
            ]],
            ['soins-infirmiers', ['fr' => 'Soins infirmiers', 'ar' => 'علاجات تمريضية', 'en' => 'Nursing care'], 'nurse', [
                ['injection-im-sc', ['fr' => 'Injection intramusculaire ou sous-cutanée', 'ar' => 'حقنة عضلية أو تحت الجلد', 'en' => 'Intramuscular or subcutaneous injection'],
                    ['fr' => 'Injection réalisée à domicile par un infirmier.', 'ar' => 'حقنة يقوم بها ممرض في المنزل.', 'en' => 'Injection given at home by a nurse.'],
                    20, 195, true, true],
                ['injection-intraveineuse', ['fr' => 'Injection intraveineuse', 'ar' => 'حقنة وريدية', 'en' => 'Intravenous injection'],
                    ['fr' => 'Injection intraveineuse directe ou lente à domicile. Consommable inclus.', 'ar' => 'حقنة وريدية مباشرة أو بطيئة في المنزل. المستلزمات مشمولة.', 'en' => 'Direct or slow intravenous injection at home. Supplies included.'],
                    30, 260, true, true],
                ['perfusion-jusqu-a-1h', ['fr' => 'Perfusion de 30 minutes à 1 heure', 'ar' => 'تسريب وريدي من 30 دقيقة إلى ساعة', 'en' => 'Infusion of 30 minutes to 1 hour'],
                    ['fr' => 'Pose et surveillance d\'une perfusion à domicile. Consommable inclus.', 'ar' => 'وضع ومراقبة تسريب وريدي في المنزل. المستلزمات مشمولة.', 'en' => 'Setting up and monitoring an infusion at home. Supplies included.'],
                    60, 260, true, true],
                ['perfusion-plus-d-1h', ['fr' => 'Perfusion de plus d\'une heure', 'ar' => 'تسريب وريدي لأكثر من ساعة', 'en' => 'Infusion of more than 1 hour'],
                    ['fr' => 'Pose et surveillance d\'une perfusion longue à domicile. Consommable inclus.', 'ar' => 'وضع ومراقبة تسريب وريدي طويل في المنزل. المستلزمات مشمولة.', 'en' => 'Setting up and monitoring a long infusion at home. Supplies included.'],
                    120, 325, true, true],
                ['constantes-vitales', ['fr' => 'Prise des constantes vitales', 'ar' => 'قياس العلامات الحيوية', 'en' => 'Vital signs check'],
                    ['fr' => 'Tension artérielle, saturation en oxygène, fréquences cardiaque et respiratoire, glycémie.', 'ar' => 'ضغط الدم، تشبع الأكسجين، نبض القلب، وتيرة التنفس، نسبة السكر في الدم.', 'en' => 'Blood pressure, oxygen saturation, heart rate, respiratory rate, blood glucose.'],
                    20, 130, false, true],
            ]],
            ['pansements-et-plaies', ['fr' => 'Pansements et plaies', 'ar' => 'الضمادات والجروح', 'en' => 'Dressings and wounds'], 'nurse', [
                ['pansement-chirurgical-propre', ['fr' => 'Pansement chirurgical propre', 'ar' => 'ضمادة جراحية نظيفة', 'en' => 'Clean surgical dressing'],
                    ['fr' => 'Réfection d\'un pansement après une opération. Consommable inclus.', 'ar' => 'تغيير الضمادة بعد عملية جراحية. المستلزمات مشمولة.', 'en' => 'Dressing change after surgery. Supplies included.'],
                    30, 195, false, true],
                ['pansement-chirurgical-infecte', ['fr' => 'Pansement chirurgical infecté', 'ar' => 'ضمادة جراحية لجرح ملتهب', 'en' => 'Infected surgical dressing'],
                    ['fr' => 'Soin et pansement d\'une plaie opératoire infectée. Consommable inclus.', 'ar' => 'علاج وتضميد جرح جراحي ملتهب. المستلزمات مشمولة.', 'en' => 'Care and dressing of an infected surgical wound. Supplies included.'],
                    45, 260, false, true],
                ['escarres-stade-1-2', ['fr' => 'Soins d\'escarres, stades 1 et 2', 'ar' => 'علاج تقرحات الفراش، الدرجتان 1 و2', 'en' => 'Pressure sore care, stages 1 and 2'],
                    ['fr' => 'Soin d\'escarres de stade 1 ou 2. Consommable non inclus.', 'ar' => 'علاج تقرحات الفراش من الدرجة 1 أو 2. المستلزمات غير مشمولة.', 'en' => 'Care of stage 1 or 2 pressure sores. Supplies not included.'],
                    45, 260, false, true],
                ['escarres-stade-3', ['fr' => 'Soins d\'escarres, stade 3', 'ar' => 'علاج تقرحات الفراش، الدرجة 3', 'en' => 'Pressure sore care, stage 3'],
                    ['fr' => 'Soin d\'escarres de stade 3. Consommable non inclus.', 'ar' => 'علاج تقرحات الفراش من الدرجة 3. المستلزمات غير مشمولة.', 'en' => 'Care of stage 3 pressure sores. Supplies not included.'],
                    60, 390, false, true],
                ['pied-diabetique-stade-1-2', ['fr' => 'Soins du pied diabétique, stades 1 et 2', 'ar' => 'علاج القدم السكرية، الدرجتان 1 و2', 'en' => 'Diabetic foot care, stages 1 and 2'],
                    ['fr' => 'Soin d\'une plaie du pied diabétique de stade 1 ou 2. Consommable non inclus.', 'ar' => 'علاج جرح القدم السكرية من الدرجة 1 أو 2. المستلزمات غير مشمولة.', 'en' => 'Care of a stage 1 or 2 diabetic foot wound. Supplies not included.'],
                    45, 260, false, true],
                ['pied-diabetique-stade-3', ['fr' => 'Soins du pied diabétique, stade 3', 'ar' => 'علاج القدم السكرية، الدرجة 3', 'en' => 'Diabetic foot care, stage 3'],
                    ['fr' => 'Soin d\'une plaie du pied diabétique de stade 3. Consommable non inclus.', 'ar' => 'علاج جرح القدم السكرية من الدرجة 3. المستلزمات غير مشمولة.', 'en' => 'Care of a stage 3 diabetic foot wound. Supplies not included.'],
                    60, 390, false, true],
            ]],
            ['sondes', ['fr' => 'Sondes', 'ar' => 'القساطر والأنابيب', 'en' => 'Catheters and tubes'], 'nurse', [
                ['sonde-urinaire-hors-consommable', ['fr' => 'Sonde urinaire, sans le matériel', 'ar' => 'قسطرة بولية، دون المستلزمات', 'en' => 'Urinary catheter, supplies not included'],
                    ['fr' => 'Pose ou changement d\'une sonde urinaire. Consommable et matériel non inclus.', 'ar' => 'وضع أو تغيير قسطرة بولية. المستلزمات والمعدات غير مشمولة.', 'en' => 'Placing or changing a urinary catheter. Supplies and equipment not included.'],
                    45, 325, true, false],
                ['sonde-urinaire-avec-consommable', ['fr' => 'Sonde urinaire, matériel inclus', 'ar' => 'قسطرة بولية، المستلزمات مشمولة', 'en' => 'Urinary catheter, supplies included'],
                    ['fr' => 'Pose ou changement d\'une sonde urinaire. Consommable et matériel inclus.', 'ar' => 'وضع أو تغيير قسطرة بولية. المستلزمات والمعدات مشمولة.', 'en' => 'Placing or changing a urinary catheter. Supplies and equipment included.'],
                    45, 390, true, false],
                ['sonde-urinaire-silicone', ['fr' => 'Sonde urinaire en silicone, matériel inclus', 'ar' => 'قسطرة بولية من السيليكون، المستلزمات مشمولة', 'en' => 'Silicone urinary catheter, supplies included'],
                    ['fr' => 'Pose ou changement d\'une sonde urinaire en silicone. Consommable et matériel inclus.', 'ar' => 'وضع أو تغيير قسطرة بولية من السيليكون. المستلزمات والمعدات مشمولة.', 'en' => 'Placing or changing a silicone urinary catheter. Supplies and equipment included.'],
                    45, 455, true, false],
                ['sonde-gastrique-hors-consommable', ['fr' => 'Sonde gastrique, sans le matériel', 'ar' => 'أنبوب معدي، دون المستلزمات', 'en' => 'Gastric tube, supplies not included'],
                    ['fr' => 'Pose ou changement d\'une sonde gastrique. Consommable et matériel non inclus.', 'ar' => 'وضع أو تغيير أنبوب معدي. المستلزمات والمعدات غير مشمولة.', 'en' => 'Placing or changing a gastric tube. Supplies and equipment not included.'],
                    45, 325, true, false],
                // La grille de référence répète « hors consommable » sur ses deux dernières lignes de sonde
                // gastrique (390 et 455 DH). Elles sont lues comme pour la sonde urinaire : avec matériel,
                // puis silicone. À confirmer par le client.
                ['sonde-gastrique-avec-consommable', ['fr' => 'Sonde gastrique, matériel inclus', 'ar' => 'أنبوب معدي، المستلزمات مشمولة', 'en' => 'Gastric tube, supplies included'],
                    ['fr' => 'Pose ou changement d\'une sonde gastrique. Consommable et matériel inclus.', 'ar' => 'وضع أو تغيير أنبوب معدي. المستلزمات والمعدات مشمولة.', 'en' => 'Placing or changing a gastric tube. Supplies and equipment included.'],
                    45, 390, true, false],
                ['sonde-gastrique-silicone', ['fr' => 'Sonde gastrique en silicone, matériel inclus', 'ar' => 'أنبوب معدي من السيليكون، المستلزمات مشمولة', 'en' => 'Silicone gastric tube, supplies included'],
                    ['fr' => 'Pose ou changement d\'une sonde gastrique en silicone. Consommable et matériel inclus.', 'ar' => 'وضع أو تغيير أنبوب معدي من السيليكون. المستلزمات والمعدات مشمولة.', 'en' => 'Placing or changing a silicone gastric tube. Supplies and equipment included.'],
                    45, 455, true, false],
            ]],
            ['sage-femme', ['fr' => 'Sage-femme', 'ar' => 'القابلة', 'en' => 'Midwife'], 'midwife', [
                ['passage-sage-femme', ['fr' => 'Passage d\'une sage-femme', 'ar' => 'زيارة قابلة', 'en' => 'Midwife visit'],
                    ['fr' => 'Examen et prise des constantes vitales à domicile par une sage-femme.', 'ar' => 'فحص وقياس العلامات الحيوية في المنزل من طرف قابلة.', 'en' => 'Examination and vital signs check at home by a midwife.'],
                    45, 520, false, true],
            ]],
            ['kinesitherapie', ['fr' => 'Kinésithérapie', 'ar' => 'الترويض الطبي', 'en' => 'Physiotherapy'], 'physiotherapist', [
                ['seance-de-kinesitherapie', ['fr' => 'Séance de kinésithérapie', 'ar' => 'حصة ترويض طبي', 'en' => 'Physiotherapy session'],
                    ['fr' => 'Kinésithérapie motrice ou respiratoire à domicile.', 'ar' => 'ترويض حركي أو تنفسي في المنزل.', 'en' => 'Motor or respiratory physiotherapy at home.'],
                    45, 250, true, true],
            ]],
            ['hygiene-et-confort', ['fr' => 'Hygiène et confort', 'ar' => 'النظافة والراحة', 'en' => 'Hygiene and comfort'], 'care_assistant', [
                ['passage-d-hygiene', ['fr' => 'Passage d\'hygiène', 'ar' => 'زيارة للنظافة', 'en' => 'Hygiene visit'],
                    ['fr' => 'Toilette intime ou douche au lit pour une personne âgée ou dépendante.', 'ar' => 'نظافة شخصية أو استحمام في السرير لشخص مسن أو غير مستقل.', 'en' => 'Intimate washing or bed bath for an elderly or dependent person.'],
                    60, 260, false, true],
            ]],
        ];
    }
}
