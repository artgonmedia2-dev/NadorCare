<?php

namespace Tests\Feature\Catalogue;

use App\Enums\Role;
use App\Filament\Resources\ServiceCategories\Pages\CreateServiceCategory;
use App\Filament\Resources\Services\Pages\CreateService;
use App\Filament\Resources\Services\Pages\EditService;
use App\Models\ProfessionalCategory;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use Database\Seeders\DemoCatalogueSeeder;
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Livewire\Livewire;
use RuntimeException;
use Tests\TestCase;

class CatalogueBackOfficeTest extends TestCase
{
    private function staff(Role $role): User
    {
        $user = User::factory()->staff($role)->create();
        $user->saveAppAuthenticationSecret(AppAuthentication::make()->generateSecret());

        return $user;
    }

    public function test_only_the_administrator_manages_the_catalogue(): void
    {
        $this->actingAs($this->staff(Role::Administrateur));
        $this->get('/admin/services')->assertOk();
        $this->get('/admin/service-categories')->assertOk();
        $this->get('/admin/services/create')->assertOk();

        foreach ([Role::Coordinateur, Role::Comptable] as $role) {
            // Nouvelle session : sinon le changement de compte en cours de test provoque une déconnexion.
            $this->flushSession();
            $this->actingAs($this->staff($role));
            $this->get('/admin/services')->assertForbidden();
            $this->get('/admin/service-categories/create')->assertForbidden();
        }
    }

    public function test_the_administrator_creates_a_category_in_three_languages(): void
    {
        $this->actingAs($this->staff(Role::Administrateur));

        Livewire::test(CreateServiceCategory::class)
            ->fillForm([
                'name' => ['fr' => 'Soins infirmiers', 'ar' => 'علاجات تمريضية', 'en' => 'Nursing care'],
                'slug' => 'soins-infirmiers',
                'sort' => 1,
                'is_active' => true,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $category = ServiceCategory::query()->where('slug', 'soins-infirmiers')->sole();
        // assertEquals : PostgreSQL ne garde pas l'ordre des clés d'un jsonb.
        $this->assertEquals(['fr' => 'Soins infirmiers', 'ar' => 'علاجات تمريضية', 'en' => 'Nursing care'], $category->name);
    }

    public function test_a_price_typed_in_dirhams_is_stored_in_centimes_and_published_by_the_api(): void
    {
        $this->actingAs($this->staff(Role::Administrateur));
        $category = ServiceCategory::factory()->create();
        $profession = ProfessionalCategory::factory()->create();

        Livewire::test(CreateService::class)
            ->fillForm([
                'name' => ['fr' => 'Injection', 'ar' => 'حقنة', 'en' => 'Injection'],
                'description' => ['fr' => 'Injection à domicile.'],
                'service_category_id' => $category->id,
                'professional_category_id' => $profession->id,
                'slug' => 'injection',
                'duration_minutes' => 20,
                'base_price' => 80.5,
                'requires_prescription' => true,
                'allows_series' => true,
                'sort' => 1,
                'is_active' => true,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $service = Service::query()->where('slug', 'injection')->sole();
        $this->assertSame(8050, $service->base_price);
        $this->assertTrue($service->requires_prescription);

        $this->getJson('/api/v1/catalogue/services/injection')
            ->assertOk()
            ->assertJsonPath('data.price.amount', 8050)
            ->assertJsonPath('data.name', 'Injection');

        // À la réouverture, le prix s'affiche de nouveau en dirhams.
        Livewire::test(EditService::class, ['record' => $service->id])
            ->assertSchemaStateSet(['base_price' => 80.5]);
    }

    public function test_the_form_requires_the_french_name_and_a_clean_unique_slug(): void
    {
        $this->actingAs($this->staff(Role::Administrateur));
        $existing = Service::factory()->create(['slug' => 'injection']);

        Livewire::test(CreateService::class)
            ->fillForm([
                'name' => ['ar' => 'حقنة'],
                'service_category_id' => $existing->service_category_id,
                'professional_category_id' => $existing->professional_category_id,
                'slug' => 'injection',
                'duration_minutes' => 20,
                'base_price' => 80,
            ])
            ->call('create')
            ->assertHasFormErrors(['name.fr' => 'required', 'slug' => 'unique']);

        Livewire::test(CreateService::class)
            ->fillForm(['slug' => 'Mon Service !'])
            ->call('create')
            ->assertHasFormErrors(['slug' => 'regex']);
    }

    public function test_the_demo_catalogue_is_complete_and_refuses_production(): void
    {
        $this->seed(DemoCatalogueSeeder::class);
        $this->seed(DemoCatalogueSeeder::class); // rejouable sans doublon

        $this->assertSame(4, ServiceCategory::query()->count());
        $this->assertSame(6, Service::query()->count());
        $this->assertTrue(Service::query()->get()->every(fn (Service $service) => count($service->name) === 3 && count($service->description) === 3));

        $this->getJson('/api/v1/catalogue/categories')->assertJsonCount(4, 'data');

        $this->app->detectEnvironment(fn () => 'production');
        $this->expectException(RuntimeException::class);
        $this->app->make(DemoCatalogueSeeder::class)->run();
    }
}
