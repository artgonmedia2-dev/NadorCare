<?php

namespace App\Filament\Support;

use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;

/**
 * Champs de saisie pour les textes stockés en `{fr, ar, en}` : un champ par langue.
 * Le français est obligatoire (langue de repli), les deux autres sont facultatifs.
 */
final class TranslatableFields
{
    /**
     * @return list<TextInput>
     */
    public static function inputs(string $attribute, string $labelKey = 'admin.common.name_in', int $maxLength = 120): array
    {
        return array_map(
            fn (string $locale) => TextInput::make("$attribute.$locale")
                ->label(__($labelKey, ['language' => __("admin.languages.$locale")]))
                ->required($locale === 'fr')
                ->maxLength($maxLength)
                ->extraInputAttributes(['dir' => $locale === 'ar' ? 'rtl' : 'ltr']),
            config('nadorcare.locales'),
        );
    }

    /**
     * @return list<Textarea>
     */
    public static function textareas(string $attribute, string $labelKey = 'admin.common.description_in', int $maxLength = 1000): array
    {
        return array_map(
            fn (string $locale) => Textarea::make("$attribute.$locale")
                ->label(__($labelKey, ['language' => __("admin.languages.$locale")]))
                ->rows(3)
                ->maxLength($maxLength)
                ->extraInputAttributes(['dir' => $locale === 'ar' ? 'rtl' : 'ltr']),
            config('nadorcare.locales'),
        );
    }
}
