<?php

namespace App\Providers;

use App\Enums\Role;
use App\Models\User;
use Illuminate\Support\Facades\Gate;
use Laravel\Horizon\HorizonApplicationServiceProvider;

class HorizonServiceProvider extends HorizonApplicationServiceProvider
{
    /**
     * Hors environnement local, seul un administrateur ouvre le tableau de bord des files d'attente.
     */
    protected function gate(): void
    {
        Gate::define('viewHorizon', fn (?User $user = null) => $user !== null
            && $user->isActive()
            && $user->hasRole(Role::Administrateur->value));
    }
}
