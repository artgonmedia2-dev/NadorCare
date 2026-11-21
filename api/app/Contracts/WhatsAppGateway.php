<?php

namespace App\Contracts;

interface WhatsAppGateway
{
    /**
     * Envoie un modèle de message approuvé (WhatsApp Business Platform).
     *
     * @param  string  $to  numéro au format E.164
     * @param  array<int|string, string>  $parameters
     * @return string identifiant du message chez le fournisseur
     */
    public function sendTemplate(string $to, string $template, array $parameters, string $locale): string;
}
