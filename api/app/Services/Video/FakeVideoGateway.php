<?php

namespace App\Services\Video;

use App\Contracts\VideoGateway;
use Carbon\CarbonInterface;

/**
 * Pilote factice : délivre un jeton sans ouvrir de vraie salle. Les applications affichent alors
 * un appel simulé. Sert au développement et aux tests, jamais avec de vrais patients.
 */
class FakeVideoGateway implements VideoGateway
{
    public function access(string $room, string $participant, bool $isHost, CarbonInterface $expiresAt): VideoAccess
    {
        return new VideoAccess(
            provider: 'fake',
            room: $room,
            token: hash('sha256', implode('|', [$room, $participant, $isHost ? 'host' : 'guest', $expiresAt->getTimestamp()])),
            serverUrl: null,
            isHost: $isHost,
            expiresAt: $expiresAt,
        );
    }
}
