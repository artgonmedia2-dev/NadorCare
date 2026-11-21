<?php

namespace Database\Seeders;

use App\Models\ProfessionalCategory;
use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Database\Seeder;
use RuntimeException;

/**
 * Catalogue de DÉMONSTRATION, pour développer et montrer les écrans.
 *
 * Les services et surtout les prix sont inventés : la vraie liste et la grille tarifaire
 * sont à fournir par le client (point à trancher n° 3) et se saisissent dans le back-office.
 * Ce seeder ne fait pas partie de DatabaseSeeder et refuse de tourner en production :
 *
 *     php artisan db:seed --class=DemoCatalogueSeeder
 */
class DemoCatalogueSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->isProduction()) {
            throw new RuntimeException('Le catalogue de démonstration ne s\'installe pas en production.');
        }

        $this->call(ReferenceDataSeeder::class);

        $professions = ProfessionalCategory::query()->pluck('id', 'code');

        $catalogue = [
            ['soins-infirmiers', ['fr' => 'Soins infirmiers', 'ar' => 'علاجات تمريضية', 'en' => 'Nursing care'], 'nurse', [
                ['injection', ['fr' => 'Injection', 'ar' => 'حقنة', 'en' => 'Injection'],
                    ['fr' => 'Injection intramusculaire, sous-cutanée ou intraveineuse à domicile.', 'ar' => 'حقنة عضلية أو تحت الجلد أو وريدية في المنزل.', 'en' => 'Intramuscular, subcutaneous or intravenous injection at home.'],
                    20, 8000, true, true],
                ['pansement', ['fr' => 'Pansement', 'ar' => 'تضميد', 'en' => 'Wound dressing'],
                    ['fr' => 'Réfection de pansement, soin de plaie.', 'ar' => 'تغيير الضمادة والعناية بالجرح.', 'en' => 'Dressing change and wound care.'],
                    30, 10000, false, true],
                ['prise-de-sang', ['fr' => 'Prise de sang', 'ar' => 'تحليل الدم', 'en' => 'Blood sample'],
                    ['fr' => 'Prélèvement sanguin à domicile et dépôt au laboratoire.', 'ar' => 'أخذ عينة الدم في المنزل وإيصالها إلى المختبر.', 'en' => 'Blood sample taken at home and delivered to the laboratory.'],
                    20, 12000, true, false],
            ]],
            ['medecine-generale', ['fr' => 'Médecine générale', 'ar' => 'الطب العام', 'en' => 'General medicine'], 'general_practitioner', [
                ['consultation-a-domicile', ['fr' => 'Consultation à domicile', 'ar' => 'استشارة طبية في المنزل', 'en' => 'Home consultation'],
                    ['fr' => 'Visite d\'un médecin généraliste à domicile.', 'ar' => 'زيارة طبيب عام في المنزل.', 'en' => 'Visit from a general practitioner at home.'],
                    30, 30000, false, false],
            ]],
            ['kinesitherapie', ['fr' => 'Kinésithérapie', 'ar' => 'الترويض الطبي', 'en' => 'Physiotherapy'], 'physiotherapist', [
                ['seance-de-reeducation', ['fr' => 'Séance de rééducation', 'ar' => 'حصة ترويض', 'en' => 'Rehabilitation session'],
                    ['fr' => 'Rééducation à domicile après une opération ou un accident.', 'ar' => 'ترويض في المنزل بعد عملية أو حادث.', 'en' => 'Rehabilitation at home after surgery or an accident.'],
                    45, 20000, true, true],
            ]],
            ['aide-a-domicile', ['fr' => 'Aide à domicile', 'ar' => 'المساعدة المنزلية', 'en' => 'Home assistance'], 'care_assistant', [
                ['aide-a-la-toilette', ['fr' => 'Aide à la toilette', 'ar' => 'المساعدة على النظافة', 'en' => 'Help with washing'],
                    ['fr' => 'Aide à la toilette et à l\'habillage d\'une personne âgée ou dépendante.', 'ar' => 'مساعدة شخص مسن أو غير مستقل على النظافة وارتداء الملابس.', 'en' => 'Help with washing and dressing for an elderly or dependent person.'],
                    60, 15000, false, true],
            ]],
        ];

        foreach ($catalogue as $position => [$slug, $name, $profession, $services]) {
            $category = ServiceCategory::updateOrCreate(['slug' => $slug], ['name' => $name, 'sort' => $position + 1, 'is_active' => true]);

            foreach ($services as $order => [$serviceSlug, $serviceName, $description, $duration, $price, $prescription, $series]) {
                Service::updateOrCreate(['slug' => $serviceSlug], [
                    'service_category_id' => $category->id,
                    'professional_category_id' => $professions[$profession],
                    'name' => $serviceName,
                    'description' => $description,
                    'duration_minutes' => $duration,
                    'base_price' => $price,
                    'requires_prescription' => $prescription,
                    'allows_series' => $series,
                    'is_active' => true,
                    'sort' => $order + 1,
                ]);
            }
        }
    }
}
