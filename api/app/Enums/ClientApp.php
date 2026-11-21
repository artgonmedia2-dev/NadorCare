<?php

namespace App\Enums;

/**
 * Application mobile ou site depuis lequel l'utilisateur s'authentifie.
 */
enum ClientApp: string
{
    case Patient = 'patient';
    case Pro = 'pro';

    public function defaultRole(): Role
    {
        return match ($this) {
            self::Patient => Role::Patient,
            self::Pro => Role::Professionnel,
        };
    }

    public function tokenAbility(): string
    {
        return 'app:'.$this->value;
    }
}
