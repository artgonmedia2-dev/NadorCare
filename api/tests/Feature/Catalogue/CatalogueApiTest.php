<?php

namespace Tests\Feature\Catalogue;

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\Surcharge;
use Tests\TestCase;

class CatalogueApiTest extends TestCase
{
    private ServiceCategory $nursing;

    private ServiceCategory $physio;

    protected function setUp(): void
    {
        parent::setUp();

        $this->nursing = ServiceCategory::factory()->create([
            'slug' => 'soins-infirmiers',
            'name' => ['fr' => 'Soins infirmiers', 'ar' => 'علاجات تمريضية', 'en' => 'Nursing care'],
            'sort' => 1,
        ]);
        $this->physio = ServiceCategory::factory()->create([
            'slug' => 'kinesitherapie',
            'name' => ['fr' => 'Kinésithérapie', 'ar' => 'الترويض الطبي', 'en' => 'Physiotherapy'],
            'sort' => 2,
        ]);

        Service::factory()->create([
            'service_category_id' => $this->nursing->id,
            'slug' => 'injection',
            'name' => ['fr' => 'Injection', 'ar' => 'حقنة', 'en' => 'Injection'],
            'description' => ['fr' => 'Injection intramusculaire ou sous-cutanée à domicile.', 'ar' => 'حقنة في المنزل.', 'en' => 'Injection at home.'],
            'duration_minutes' => 20,
            'base_price' => 8000,
            'requires_prescription' => true,
            'sort' => 1,
        ]);
        Service::factory()->create([
            'service_category_id' => $this->nursing->id,
            'slug' => 'pansement',
            'name' => ['fr' => 'Pansement', 'ar' => 'تضميد', 'en' => 'Wound dressing'],
            'description' => ['fr' => 'Réfection de pansement simple.', 'ar' => 'تغيير الضمادة.', 'en' => 'Simple dressing change.'],
            'base_price' => 10000,
            'sort' => 2,
        ]);
        Service::factory()->create([
            'service_category_id' => $this->physio->id,
            'slug' => 'reeducation',
            'name' => ['fr' => 'Séance de rééducation', 'ar' => 'حصة ترويض', 'en' => 'Rehabilitation session'],
            'description' => ['fr' => 'Rééducation après une opération.', 'ar' => 'ترويض بعد عملية.', 'en' => 'Rehabilitation after surgery.'],
            'duration_minutes' => 45,
            'base_price' => 20000,
        ]);
    }

    public function test_the_catalogue_is_public(): void
    {
        $this->getJson('/api/v1/catalogue/categories')->assertOk();
        $this->getJson('/api/v1/catalogue/services')->assertOk()->assertJsonCount(3, 'data');
        $this->getJson('/api/v1/catalogue/services/injection')->assertOk();
    }

    public function test_categories_are_ordered_and_count_their_services(): void
    {
        $this->getJson('/api/v1/catalogue/categories')
            ->assertOk()
            ->assertJsonPath('data.0.slug', 'soins-infirmiers')
            ->assertJsonPath('data.0.name', 'Soins infirmiers')
            ->assertJsonPath('data.0.services_count', 2)
            ->assertJsonPath('data.1.slug', 'kinesitherapie')
            ->assertJsonPath('data.1.services_count', 1);
    }

    public function test_a_service_exposes_duration_indicative_price_and_prescription_rule(): void
    {
        $this->getJson('/api/v1/catalogue/services/injection')
            ->assertOk()
            ->assertJsonPath('data.name', 'Injection')
            ->assertJsonPath('data.description', 'Injection intramusculaire ou sous-cutanée à domicile.')
            ->assertJsonPath('data.duration_minutes', 20)
            ->assertJsonPath('data.price', ['amount' => 8000, 'currency' => 'MAD'])
            ->assertJsonPath('data.requires_prescription', true)
            ->assertJsonPath('data.category.slug', 'soins-infirmiers')
            ->assertJsonPath('data.professional_category', 'Infirmier');
    }

    public function test_texts_follow_the_requested_language(): void
    {
        $this->getJson('/api/v1/catalogue/services/injection', ['Accept-Language' => 'ar'])
            ->assertJsonPath('data.name', 'حقنة')
            ->assertJsonPath('data.category.name', 'علاجات تمريضية')
            ->assertJsonPath('data.professional_category', 'ممرض');

        $this->getJson('/api/v1/catalogue/categories', ['Accept-Language' => 'en'])
            ->assertJsonPath('data.1.name', 'Physiotherapy');
    }

    public function test_a_missing_translation_falls_back_to_french(): void
    {
        Service::factory()->create([
            'service_category_id' => $this->nursing->id,
            'slug' => 'perfusion',
            'name' => ['fr' => 'Perfusion'],
            'description' => null,
        ]);

        $this->getJson('/api/v1/catalogue/services/perfusion', ['Accept-Language' => 'ar'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Perfusion')
            ->assertJsonPath('data.description', null);
    }

    public function test_services_are_filtered_by_category(): void
    {
        $this->getJson('/api/v1/catalogue/services?category=soins-infirmiers')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.slug', 'injection')
            ->assertJsonPath('data.1.slug', 'pansement');

        $this->getJson('/api/v1/catalogue/services?category=inconnue')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_search_ignores_accents_and_case_and_works_across_languages(): void
    {
        // Sans accent, en minuscules.
        $this->getJson('/api/v1/catalogue/services?q=reeducation')->assertJsonCount(1, 'data')->assertJsonPath('data.0.slug', 'reeducation');
        $this->getJson('/api/v1/catalogue/services?q=PANSEMENT')->assertJsonCount(1, 'data');
        // Dans la description.
        $this->getJson('/api/v1/catalogue/services?q=sous-cutanee')->assertJsonCount(1, 'data')->assertJsonPath('data.0.slug', 'injection');
        // En arabe alors que la réponse est demandée en français.
        $this->getJson('/api/v1/catalogue/services?q='.urlencode('حقنة'))->assertJsonCount(1, 'data')->assertJsonPath('data.0.name', 'Injection');
        // En anglais.
        $this->getJson('/api/v1/catalogue/services?q=dressing')->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/catalogue/services?q=introuvable')->assertJsonCount(0, 'data');
    }

    public function test_search_treats_special_characters_literally(): void
    {
        $this->getJson('/api/v1/catalogue/services?q='.urlencode('%%'))->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/catalogue/services?q='.urlencode("' OR 1=1 --"))->assertOk()->assertJsonCount(0, 'data');
        // Un seul caractère : la recherche est ignorée, tout le catalogue est renvoyé.
        $this->getJson('/api/v1/catalogue/services?q=a')->assertOk()->assertJsonCount(3, 'data');
    }

    public function test_inactive_services_and_categories_are_hidden(): void
    {
        Service::query()->where('slug', 'pansement')->update(['is_active' => false]);
        $this->physio->update(['is_active' => false]);

        $this->getJson('/api/v1/catalogue/services')->assertJsonCount(1, 'data')->assertJsonPath('data.0.slug', 'injection');
        $this->getJson('/api/v1/catalogue/services/pansement')->assertNotFound()->assertJsonPath('code', 'not_found');
        $this->getJson('/api/v1/catalogue/services/reeducation')->assertNotFound();

        $this->getJson('/api/v1/catalogue/categories')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.services_count', 1);
    }

    public function test_active_surcharges_are_announced_publicly(): void
    {
        Surcharge::create([
            'type' => Surcharge::TYPE_NIGHT,
            'name' => ['fr' => 'Majoration du soir', 'ar' => 'زيادة المساء', 'en' => 'Evening surcharge'],
            'mode' => Surcharge::MODE_FIXED,
            'value' => 5000,
            'config' => ['start' => '19:00', 'end' => '08:00'],
            'is_active' => true,
        ]);
        Surcharge::create([
            'type' => Surcharge::TYPE_HOLIDAY,
            'name' => ['fr' => 'Jour férié'],
            'mode' => Surcharge::MODE_PERCENT,
            'value' => 25,
            'is_active' => false,
        ]);
        // La majoration de distance n'est pas appliquée par le calcul du prix : elle n'est pas annoncée.
        Surcharge::create([
            'type' => Surcharge::TYPE_DISTANCE,
            'name' => ['fr' => 'Distance'],
            'mode' => Surcharge::MODE_FIXED,
            'value' => 5000,
            'is_active' => true,
        ]);

        $this->getJson('/api/v1/catalogue/surcharges')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.type', 'night')
            ->assertJsonPath('data.0.name', 'Majoration du soir')
            ->assertJsonPath('data.0.mode', 'fixed')
            ->assertJsonPath('data.0.value', 5000)
            ->assertJsonPath('data.0.starts_at', '19:00')
            ->assertJsonPath('data.0.ends_at', '08:00');
    }

    public function test_a_category_without_active_service_is_not_listed(): void
    {
        ServiceCategory::factory()->create(['slug' => 'vide']);

        $this->getJson('/api/v1/catalogue/categories')->assertJsonCount(2, 'data');
    }
}
