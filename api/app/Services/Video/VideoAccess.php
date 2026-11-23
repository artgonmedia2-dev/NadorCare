<?php

namespace App\Services\Video;

use Carbon\CarbonInterface;

/**
 * Ce qu'il faut à une application pour entrer dans une salle vidéo.
 */
final readonly class VideoAccess
{
    public function __construct(
        /** Nom du pilote : l'application choisit son module vidéo d'après lui. */
        public string $provider,
        public string $room,
        /** Jeton d'accès à durée limitée, propre au participant. */
        public string $token,
        /** Adresse du serveur vidéo, si le prestataire en a une. */
        public ?string $serverUrl,
        public bool $isHost,
        public CarbonInterface $expiresAt,
    ) {}
}
