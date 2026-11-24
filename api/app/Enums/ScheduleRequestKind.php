<?php

namespace App\Enums;

/**
 * Ce qu'un soignant peut demander à la coordination au sujet de son planning.
 */
enum ScheduleRequestKind: string
{
    /** Une nouvelle semaine type (jours et heures de travail). */
    case Weekly = 'weekly';

    /** Une indisponibilité datée : congé, empêchement. */
    case Unavailability = 'unavailability';
}
