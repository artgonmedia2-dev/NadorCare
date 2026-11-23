<?php

namespace App\Http\Resources\Api\V1;

use App\Services\Video\VideoAccess;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Accès à la salle vidéo d'une téléconsultation.
 *
 * @mixin VideoAccess
 */
class VideoAccessResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            /** Prestataire vidéo. `fake` : appel simulé, pour le développement. */
            'provider' => $this->provider,
            'room' => $this->room,
            /** Jeton propre au participant, à durée limitée. */
            'token' => $this->token,
            'server_url' => $this->serverUrl,
            /** Vrai pour le professionnel, qui ouvre et ferme l'appel. */
            'is_host' => $this->isHost,
            'expires_at' => $this->expiresAt->toIso8601String(),
        ];
    }
}
