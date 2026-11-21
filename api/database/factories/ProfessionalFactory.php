<?php

namespace Database\Factories;

use App\Enums\Role;
use App\Enums\VerificationStatus;
use App\Models\Professional;
use App\Models\ProfessionalCategory;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Professional>
 */
class ProfessionalFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->withRole(Role::Professionnel),
            'professional_category_id' => ProfessionalCategory::factory(),
            'verification_status' => VerificationStatus::Verified,
            'is_online' => true,
        ];
    }
}
