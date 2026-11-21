<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Choisit la langue de la réponse : en-tête Accept-Language, sinon langue du compte, sinon français.
 */
class SetLocale
{
    public function handle(Request $request, Closure $next): Response
    {
        $supported = config('nadorcare.locales');

        $locale = $request->hasHeader('Accept-Language')
            ? $request->getPreferredLanguage($supported)
            : ($request->user()?->locale);

        if (in_array($locale, $supported, true)) {
            app()->setLocale($locale);
        }

        $response = $next($request);
        $response->headers->set('Content-Language', app()->getLocale());

        return $response;
    }
}
