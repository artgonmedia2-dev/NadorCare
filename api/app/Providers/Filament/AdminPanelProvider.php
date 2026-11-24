<?php

namespace App\Providers\Filament;

use Filament\Auth\MultiFactor\App\AppAuthentication;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\View\PanelsRenderHook;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\PreventRequestForgery;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

/**
 * Back-office Nador Care (coordinateurs, administrateurs, comptables).
 *
 * L'accès est limité par User::canAccessPanel(). Le double facteur est obligatoire
 * (cahier des charges §10) : un compte sans double facteur est renvoyé vers sa configuration.
 */
class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->brandName('Nador Care')
            // Refonte du 2026-11-24 : même identité que le site (teal, Figtree, Noto Sans).
            ->brandLogo(fn () => view('filament.brand'))
            ->brandLogoHeight('2.5rem')
            ->favicon(asset('favicon.svg'))
            ->font('Noto Sans')
            ->renderHook(PanelsRenderHook::HEAD_END, fn () => view('filament.head'))
            ->login()
            // Le mode sombre est une fonctionnalité V2 : le panneau reste clair, quel que soit le thème du poste.
            ->darkMode(false)
            ->profile()
            ->multiFactorAuthentication([
                AppAuthentication::make()->recoverable()->brandName('Nador Care'),
            ], isRequired: true)
            ->colors([
                // Nuances fixées à la main : la palette générée par Color::hex() éclaircit trop le teal. Les
                // nuances 500 et 600 gardent un contraste d'au moins 4,5:1 avec le texte blanc, sinon
                // Filament passe les boutons sur une nuance claire avec un texte sombre.
                'primary' => [
                    50 => '#f0fdfa', 100 => '#ccfbf1', 200 => '#99f6e4', 300 => '#5eead4', 400 => '#2dd4bf',
                    500 => '#11807a', 600 => '#0f766e', 700 => '#0b5c56', 800 => '#083f3b', 900 => '#062e2b', 950 => '#042220',
                ],
            ])
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\Filament\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\Filament\Pages')
            ->pages([
                // Tableau de bord de la coordination (App\Filament\Pages\Dashboard), trouvé par discoverPages.
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\Filament\Widgets')
            ->widgets([])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                PreventRequestForgery::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }
}
