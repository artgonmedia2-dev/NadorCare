<?php

use Illuminate\Support\Facades\Schedule;

/*
| Tâches planifiées. En local, le conteneur « scheduler » les exécute (php artisan schedule:work).
*/

// Justificatifs des professionnels arrivés à expiration (assurance, surtout).
Schedule::command('nadorcare:expire-documents')->dailyAt('02:00');

// Propositions de mission restées sans réponse après le délai.
Schedule::command('nadorcare:expire-offers')->everyMinute()->withoutOverlapping();
