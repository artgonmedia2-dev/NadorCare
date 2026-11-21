<?php

namespace Database\Factories;

use App\Models\ServiceCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ServiceCategory>
 */
class ServiceCategoryFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => ['fr' => 'Soins infirmiers', 'ar' => 'علاجات تمريضية', 'en' => 'Nursing care'],
            'slug' => 'cat-'.fake()->unique()->lexify('????????'),
            'is_active' => true,
        ];
    }
}
