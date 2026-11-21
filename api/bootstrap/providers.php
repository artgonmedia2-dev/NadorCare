<?php

use App\Providers\AppServiceProvider;
use App\Providers\ExternalServicesProvider;
use App\Providers\Filament\AdminPanelProvider;
use App\Providers\HorizonServiceProvider;

return [
    AppServiceProvider::class,
    ExternalServicesProvider::class,
    AdminPanelProvider::class,
    HorizonServiceProvider::class,
];
