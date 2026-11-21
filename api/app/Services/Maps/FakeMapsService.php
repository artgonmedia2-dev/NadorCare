<?php

namespace App\Services\Maps;

use App\Contracts\MapsService;

/**
 * Estimation sans appel externe : distance à vol d'oiseau majorée, vitesse moyenne en ville.
 */
class FakeMapsService implements MapsService
{
    private const EARTH_RADIUS_M = 6_371_000;

    private const DETOUR_FACTOR = 1.3;

    private const AVERAGE_SPEED_KMH = 30;

    public function estimateRoute(float $fromLat, float $fromLng, float $toLat, float $toLng): RouteEstimate
    {
        $dLat = deg2rad($toLat - $fromLat);
        $dLng = deg2rad($toLng - $fromLng);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($fromLat)) * cos(deg2rad($toLat)) * sin($dLng / 2) ** 2;
        $straight = 2 * self::EARTH_RADIUS_M * asin(min(1.0, sqrt($a)));

        $distance = (int) round($straight * self::DETOUR_FACTOR);
        $duration = (int) round($distance / (self::AVERAGE_SPEED_KMH * 1000 / 3600));

        return new RouteEstimate($distance, $duration);
    }
}
