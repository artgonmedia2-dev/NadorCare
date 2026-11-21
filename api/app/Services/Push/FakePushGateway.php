<?php

namespace App\Services\Push;

use App\Contracts\PushGateway;

class FakePushGateway implements PushGateway
{
    /** @var list<array{tokens: list<string>, title: string, body: string, data: array<string, string>}> */
    public array $sent = [];

    public function send(array $deviceTokens, string $title, string $body, array $data = []): void
    {
        $this->sent[] = ['tokens' => $deviceTokens, 'title' => $title, 'body' => $body, 'data' => $data];
    }
}
