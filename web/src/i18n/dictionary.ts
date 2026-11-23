import type { Locale } from './config';
import ar from './generated/ar.json';
import en from './generated/en.json';
import fr from './generated/fr.json';

export type Dictionary = typeof fr;
export type TextKey = keyof Dictionary;

const dictionaries: Record<Locale, Dictionary> = { fr, ar, en };

export function getDictionary(locale: Locale): Dictionary {
  return dictionaries[locale];
}

/** Remplace les `{nom}` d'un texte par leurs valeurs. */
export function fill(text: string, values: Record<string, string | number>): string {
  return text.replace(/\{(\w+)\}/g, (match, name: string) =>
    name in values ? String(values[name]) : match,
  );
}

/**
 * Isole un numéro ou une référence pour qu'il se lise de gauche à droite dans une phrase
 * en arabe (marques Unicode U+2066 et U+2069).
 */
export function isolateLtr(text: string): string {
  return `${String.fromCharCode(0x2066)}${text}${String.fromCharCode(0x2069)}`;
}
