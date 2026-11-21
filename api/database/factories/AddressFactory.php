<?php

namespace Database\Factories;

use App\Models\Address;
use App\Models\User;
use Clickbar\Magellan\Data\Geometries\Point;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Address>
 */
class AddressFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'label' => 'Domicile',
            'line' => fake()->streetAddress(),
            'city' => 'Nador',
            // Point dans le centre de Nador.
            'location' => Point::makeGeodetic(
                fake()->randomFloat(5, 35.155, 35.185),
                fake()->randomFloat(5, -2.955, -2.905),
            ),
            'access_notes' => null,
        ];
    }
}
