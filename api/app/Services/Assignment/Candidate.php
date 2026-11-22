<?php

namespace App\Services\Assignment;

use App\Models\Professional;

/**
 * Professionnel qui peut recevoir une mission, avec les critères qui aident à choisir.
 */
final readonly class Candidate
{
    public function __construct(
        public Professional $professional,
        /** Le domicile du patient est dans une zone que le professionnel couvre. */
        public bool $coversZone,
        /** Son agenda hebdomadaire couvre le créneau. */
        public bool $available,
        /** Distance entre sa dernière position connue et le domicile, en mètres. */
        public ?int $distanceMeters,
        public ?float $rating,
    ) {}
}
