<?php

namespace App\Services\Maps;

final readonly class RouteEstimate
{
    public function __construct(
        public int $distanceMeters,
        public int $durationSeconds,
    ) {}
}
