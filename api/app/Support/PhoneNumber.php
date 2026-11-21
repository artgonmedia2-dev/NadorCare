<?php

namespace App\Support;

/**
 * Normalisation des numéros au format E.164.
 * Les numéros marocains saisis localement (06…, 07…, 05…) reçoivent l'indicatif +212 ;
 * les numéros étrangers (diaspora) doivent être saisis avec leur indicatif.
 */
final class PhoneNumber
{
    public static function normalize(?string $input): ?string
    {
        if ($input === null) {
            return null;
        }

        $digits = preg_replace('/[\s\-.()]/', '', trim($input)) ?? '';

        if (str_starts_with($digits, '00')) {
            $digits = '+'.substr($digits, 2);
        }

        // Numéro marocain en notation locale : 0612345678.
        if (preg_match('/^0([5-7]\d{8})$/', $digits, $matches)) {
            $digits = '+212'.$matches[1];
        }

        // +2120612345678 : zéro en trop après l'indicatif.
        if (preg_match('/^\+2120([5-7]\d{8})$/', $digits, $matches)) {
            $digits = '+212'.$matches[1];
        }

        if (! preg_match('/^\+[1-9]\d{7,14}$/', $digits)) {
            return null;
        }

        if (str_starts_with($digits, '+212') && ! preg_match('/^\+212[5-7]\d{8}$/', $digits)) {
            return null;
        }

        return $digits;
    }

    /**
     * Version masquée pour les journaux applicatifs : +2126•••••678.
     */
    public static function mask(string $phone): string
    {
        return substr($phone, 0, 5).str_repeat('•', max(0, strlen($phone) - 8)).substr($phone, -3);
    }
}
