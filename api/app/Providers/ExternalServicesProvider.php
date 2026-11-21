<?php

namespace App\Providers;

use App\Contracts\MapsService;
use App\Contracts\PaymentGateway;
use App\Contracts\PushGateway;
use App\Contracts\SmsGateway;
use App\Contracts\WhatsAppGateway;
use App\Services\Maps\FakeMapsService;
use App\Services\Payment\FakePaymentGateway;
use App\Services\Push\FakePushGateway;
use App\Services\Sms\FakeSmsGateway;
use App\Services\WhatsApp\FakeWhatsAppGateway;
use Illuminate\Support\ServiceProvider;
use RuntimeException;

/**
 * Relie chaque interface de service externe à l'implémentation choisie dans .env.
 * Pour brancher un vrai fournisseur : écrire la classe, puis l'ajouter à la table ci-dessous.
 */
class ExternalServicesProvider extends ServiceProvider
{
    /**
     * @var array<string, array{contract: class-string, drivers: array<string, class-string>}>
     */
    private const SERVICES = [
        'sms' => ['contract' => SmsGateway::class, 'drivers' => ['fake' => FakeSmsGateway::class]],
        'whatsapp' => ['contract' => WhatsAppGateway::class, 'drivers' => ['fake' => FakeWhatsAppGateway::class]],
        'push' => ['contract' => PushGateway::class, 'drivers' => ['fake' => FakePushGateway::class]],
        'payment' => ['contract' => PaymentGateway::class, 'drivers' => ['fake' => FakePaymentGateway::class]],
        'maps' => ['contract' => MapsService::class, 'drivers' => ['fake' => FakeMapsService::class]],
    ];

    public function register(): void
    {
        foreach (self::SERVICES as $service => $definition) {
            $this->app->singleton($definition['contract'], function ($app) use ($service, $definition) {
                $driver = (string) config("nadorcare.drivers.$service");

                if (! isset($definition['drivers'][$driver])) {
                    throw new RuntimeException("Pilote [$driver] inconnu pour le service [$service]. Pilotes disponibles : ".implode(', ', array_keys($definition['drivers'])).'.');
                }

                return $app->make($definition['drivers'][$driver]);
            });
        }
    }
}
