<?php

namespace App\Contracts;

use App\Services\Video\VideoAccess;
use Carbon\CarbonInterface;

/**
 * Prestataire d'appel vidéo des téléconsultations.
 *
 * Le prestataire n'est pas choisi : seul le pilote factice existe. Rien de ce qui identifie le
 * patient ne lui est transmis — ni nom, ni téléphone, ni motif : la salle porte un identifiant
 * opaque et les participants un simple rôle.
 */
interface VideoGateway
{
    /**
     * Droit d'entrer dans une salle, valable jusqu'à `$expiresAt`.
     *
     * @param  string  $room  identifiant opaque de la salle
     * @param  string  $participant  identifiant opaque du participant, stable pour la durée de l'appel
     * @param  bool  $isHost  vrai pour le professionnel, qui ouvre et ferme l'appel
     */
    public function access(string $room, string $participant, bool $isHost, CarbonInterface $expiresAt): VideoAccess;
}
