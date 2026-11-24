<?php

namespace App\Enums;

/**
 * Motif pour lequel un soignant signale qu'il ne peut pas prendre une mission affectée.
 */
enum DeclineReason: string
{
    /** Déjà en intervention à ce moment-là. */
    case Busy = 'busy';
    case Sick = 'sick';
    case Personal = 'personal';

    /** Autre : une précision est alors obligatoire. */
    case Other = 'other';
}
