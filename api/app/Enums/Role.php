<?php

namespace App\Enums;

enum Role: string
{
    case Patient = 'patient';
    case Proche = 'proche';
    case Professionnel = 'professionnel';
    case Coordinateur = 'coordinateur';
    case Administrateur = 'administrateur';
    case Comptable = 'comptable';

    /**
     * Rôles qui donnent accès au back-office.
     *
     * @return list<self>
     */
    public static function staff(): array
    {
        return [self::Coordinateur, self::Administrateur, self::Comptable];
    }

    /**
     * @return list<string>
     */
    public static function staffValues(): array
    {
        return array_map(fn (self $role) => $role->value, self::staff());
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $role) => $role->value, self::cases());
    }
}
