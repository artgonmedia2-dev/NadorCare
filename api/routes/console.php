<?php

use Illuminate\Support\Facades\Schedule;

/*
| Tâches planifiées. En local, le conteneur « scheduler » les exécute (php artisan schedule:work).
*/

// Justificatifs des professionnels arrivés à expiration (assurance, surtout).
Schedule::command('nadorcare:expire-documents')->dailyAt('02:00');
