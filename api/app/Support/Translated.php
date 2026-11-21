<?php

namespace App\Support;

/**
 * Lecture des textes stockés en `{"fr": "...", "ar": "...", "en": "..."}`.
 */
final class Translated
{
    /**
     * Texte dans la langue de la requête, sinon dans la langue par défaut, sinon le premier disponible.
     *
     * @param  array<string, string>|null  $values
     */
    public static function pick(?array $values, ?string $locale = null): ?string
    {
        if (! $values) {
            return null;
        }

        return $values[$locale ?? app()->getLocale()]
            ?? $values[config('app.fallback_locale')]
            ?? array_values($values)[0];
    }
}
