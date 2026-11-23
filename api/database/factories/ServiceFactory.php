<?php

namespace Database\Factories;

use App\Models\ProfessionalCategory;
use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Service>
 */
class ServiceFactory extends Factory
{
    public function definition(): array
    {
        return [
            'service_category_id' => ServiceCategory::factory(),
            'professional_category_id' => ProfessionalCategory::factory(),
            'name' => ['fr' => 'Injection', 'ar' => 'حقنة', 'en' => 'Injection'],
            'slug' => 'service-'.fake()->unique()->lexify('????????'),
            'duration_minutes' => 30,
            'base_price' => 10000,
            'requires_prescription' => false,
            'allows_series' => true,
            'is_active' => true,
        ];
    }

    /** Téléconsultation. */
    public function remote(): static
    {
        return $this->state(['delivery_mode' => 'remote', 'allows_series' => false]);
    }
}
