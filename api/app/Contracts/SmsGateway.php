<?php

namespace App\Contracts;

interface SmsGateway
{
    /**
     * Envoie un SMS et renvoie l'identifiant du message chez le fournisseur.
     *
     * @param  string  $to  numéro au format E.164
     */
    public function send(string $to, string $message): string;
}
