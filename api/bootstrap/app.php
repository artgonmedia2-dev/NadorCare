<?php

use App\Http\Middleware\SetLocale;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(prepend: [SetLocale::class]);
        $middleware->throttleApi('api');
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        // Format d'erreur unique de l'API : { message, code, ... }.
        // `code` est stable pour les applications, `message` est traduit.
        $apiError = function (string $code, int $status, array $extra = [], array $headers = []) {
            return response()->json(['message' => __('api.errors.'.$code), 'code' => $code, ...$extra], $status, $headers);
        };

        $exceptions->render(function (ValidationException $e, Request $request) use ($apiError) {
            return $request->is('api/*') ? $apiError('validation_failed', $e->status, ['errors' => $e->errors()]) : null;
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) use ($apiError) {
            return $request->is('api/*') ? $apiError('unauthenticated', 401) : null;
        });

        $exceptions->render(function (AuthorizationException|AccessDeniedHttpException $e, Request $request) use ($apiError) {
            return $request->is('api/*') ? $apiError('forbidden', 403) : null;
        });

        $exceptions->render(function (ModelNotFoundException|NotFoundHttpException $e, Request $request) use ($apiError) {
            return $request->is('api/*') ? $apiError('not_found', 404) : null;
        });

        $exceptions->render(function (ThrottleRequestsException $e, Request $request) use ($apiError) {
            return $request->is('api/*') ? $apiError('too_many_requests', 429, [], $e->getHeaders()) : null;
        });
    })->create();
