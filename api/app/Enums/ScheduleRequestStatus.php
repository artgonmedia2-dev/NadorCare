<?php

namespace App\Enums;

enum ScheduleRequestStatus: string
{
    case Pending = 'pending';
    case Accepted = 'accepted';
    case Refused = 'refused';

    /** Retirée par le soignant avant la décision. */
    case Cancelled = 'cancelled';
}
