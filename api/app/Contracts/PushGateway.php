<?php

namespace App\Contracts;

interface PushGateway
{
    /**
     * Envoie une notification push. Ne jamais y mettre de donnée de santé :
     * le contenu transite par des serveurs tiers et s'affiche sur l'écran verrouillé.
     *
     * @param  list<string>  $deviceTokens
     * @param  array<string, string>  $data
     */
    public function send(array $deviceTokens, string $title, string $body, array $data = []): void;
}
