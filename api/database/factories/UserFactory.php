<?php

namespace Database\Factories;

use App\Enums\Role;
use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    public function definition(): array
    {
        return [
            'phone' => '+2126'.fake()->unique()->numerify('########'),
            'name' => fake()->name(),
            'locale' => 'fr',
            'status' => UserStatus::Active,
        ];
    }

    public function configure(): static
    {
        return $this->afterMaking(function (User $user) {
            $user->phone_verified_at ??= now();
        });
    }

    public function suspended(): static
    {
        return $this->state(['status' => UserStatus::Suspended]);
    }

    public function withRole(Role $role): static
    {
        return $this->afterCreating(fn (User $user) => $user->assignRole($role->value));
    }

    /**
     * Compte du back-office : e-mail et mot de passe en plus du téléphone.
     */
    public function staff(Role $role = Role::Coordinateur): static
    {
        return $this->state(fn () => [
            'email' => fake()->unique()->safeEmail(),
            'password' => 'password',
        ])->withRole($role);
    }
}
