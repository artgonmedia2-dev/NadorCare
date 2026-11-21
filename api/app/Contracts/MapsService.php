<?php

namespace App\Contracts;

use App\Services\Maps\RouteEstimate;

interface MapsService
{
    /**
     * Distance et durée du trajet entre deux points (latitude, longitude).
     */
    public function estimateRoute(float $fromLat, float $fromLng, float $toLat, float $toLng): RouteEstimate;
}
