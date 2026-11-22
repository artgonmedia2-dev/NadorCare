<?php

use Illuminate\Support\Facades\Schedule;

/*
| Tâches planifiées. En local, le conteneur « scheduler » les exécute (php artisan schedule:work).
*/

// Propositions de mission restées sans réponse après le délai.
Schedule::command('nadorcare:expire-offers')->everyMinute()->withoutOverlapping();
