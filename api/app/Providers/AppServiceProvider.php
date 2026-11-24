<?php

namespace App\Providers;

use App\Models\User;
use App\Services\Finance\CaregiverLedger;
use Dedoc\Scramble\Scramble;
use Dedoc\Scramble\Support\Generator\OpenApi;
use Dedoc\Scramble\Support\Generator\SecurityScheme;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Une seule instance par requête : elle garde les chiffres du mois déjà calculés.
        $this->app->scoped(CaregiverLedger::class);
    }

    public function boot(): void
    {
        // Hors production, remplir un attribut absent de $fillable lève une erreur au lieu d'être ignoré.
        Model::preventSilentlyDiscardingAttributes(! app()->isProduction());

        $this->configureRateLimiting();
        $this->configureApiDocumentation();
    }

    private function configureRateLimiting(): void
    {
        RateLimiter::for('api', fn (Request $request) => Limit::perMinute(120)->by($request->user()?->getKey() ?: $request->ip()));

        // Demande de code : limitée par numéro (coût des SMS, harcèlement) et par adresse IP.
        RateLimiter::for('otp-request', fn (Request $request) => [
            Limit::perMinutes(10, 5)->by('otp-request:phone:'.$request->input('phone')),
            Limit::perMinute(10)->by('otp-request:ip:'.$request->ip()),
        ]);

        // Vérification : freine la recherche exhaustive du code, en plus du plafond de tentatives par code.
        RateLimiter::for('otp-verify', fn (Request $request) => [
            Limit::perMinutes(10, 10)->by('otp-verify:phone:'.$request->input('phone')),
            Limit::perMinute(20)->by('otp-verify:ip:'.$request->ip()),
        ]);
    }

    private function configureApiDocumentation(): void
    {
        // Hors environnement local, la documentation en ligne ne s'ouvre que si SCRAMBLE_ENABLED=true.
        Gate::define('viewApiDocs', fn (?User $user = null) => (bool) config('nadorcare.api_docs_enabled'));

        Scramble::configure()->withDocumentTransformers(function (OpenApi $openApi) {
            $openApi->secure(SecurityScheme::http('bearer'));
        });
    }
}
