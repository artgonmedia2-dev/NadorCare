<?php

namespace App\Enums;

/**
 * Lien entre le titulaire du compte et le patient d'un profil.
 */
enum PatientRelationship: string
{
    case Self = 'self';
    case Parent = 'parent';
    case Child = 'child';
    case Spouse = 'spouse';
    case Other = 'other';
}
