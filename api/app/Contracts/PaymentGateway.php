<?php

namespace App\Contracts;

use App\Services\Payment\PaymentResult;
use App\Services\Payment\PaymentSession;

interface PaymentGateway
{
    /**
     * Nom du fournisseur, enregistré dans payments.provider.
     */
    public function name(): string;

    /**
     * Ouvre un paiement par carte et renvoie l'adresse vers laquelle rediriger le payeur.
     *
     * @param  string  $paymentId  identifiant interne du paiement
     * @param  int  $amount  montant en centimes
     */
    public function createSession(string $paymentId, int $amount, string $currency, string $returnUrl, string $locale): PaymentSession;

    /**
     * Vérifie et interprète une notification du fournisseur.
     *
     * @param  array<string, mixed>  $payload
     * @param  array<string, string>  $headers
     */
    public function parseNotification(array $payload, array $headers = []): PaymentResult;

    /**
     * Rembourse tout ou partie d'un paiement. Renvoie la référence du remboursement.
     */
    public function refund(string $providerReference, int $amount): string;
}
