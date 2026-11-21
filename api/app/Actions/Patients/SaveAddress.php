<?php

namespace App\Actions\Patients;

use App\Exceptions\ApiException;
use App\Models\Address;
use App\Models\User;
use App\Services\Geo\ZoneLocator;
use Clickbar\Magellan\Data\Geometries\Point;

/**
 * Crée ou modifie une adresse et la rattache à la zone qui contient ses coordonnées.
 * Une adresse hors zone est acceptée : c'est la réservation qui sera refusée, pas l'adresse.
 */
class SaveAddress
{
    public function __construct(private readonly ZoneLocator $zones) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public function create(User $owner, array $data): Address
    {
        if ($owner->addresses()->count() >= (int) config('nadorcare.limits.addresses')) {
            throw new ApiException('address_limit_reached');
        }

        // refresh() : relit les valeurs par défaut posées par la base (la ville).
        return $owner->addresses()->create($this->attributes($data))->refresh();
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function update(Address $address, array $data): Address
    {
        // Latitude et longitude vont ensemble : la validation l'impose déjà.
        $address->update($this->attributes($data));

        return $address;
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function attributes(array $data): array
    {
        $attributes = array_diff_key($data, ['latitude' => true, 'longitude' => true]);

        if (isset($data['latitude'], $data['longitude'])) {
            $latitude = (float) $data['latitude'];
            $longitude = (float) $data['longitude'];

            $attributes['location'] = Point::makeGeodetic($latitude, $longitude);
            $attributes['zone_id'] = $this->zones->locate($latitude, $longitude)?->getKey();
        }

        return $attributes;
    }
}
