<?php

namespace Database\Factories;

use App\Models\ProfessionalCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProfessionalCategory>
 */
class ProfessionalCategoryFactory extends Factory
{
    public function definition(): array
    {
        return [
            'code' => 'cat_'.fake()->unique()->lexify('????????'),
            'name' => ['fr' => 'Infirmier', 'ar' => 'ممرض', 'en' => 'Nurse'],
            'has_order' => false,
            'is_active' => true,
        ];
    }
}
