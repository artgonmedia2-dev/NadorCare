<?php

namespace App\Services\WhatsApp;

use App\Contracts\WhatsAppGateway;
use Illuminate\Support\Str;

class FakeWhatsAppGateway implements WhatsAppGateway
{
    /** @var list<array{to: string, template: string, parameters: array<int|string, string>, locale: string}> */
    public array $sent = [];

    public function sendTemplate(string $to, string $template, array $parameters, string $locale): string
    {
        $this->sent[] = compact('to', 'template', 'parameters', 'locale');

        return 'fake-wa-'.Str::ulid();
    }
}
