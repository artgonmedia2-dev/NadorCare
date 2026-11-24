import type { Metadata } from 'next';

import { locales, type Locale } from '@/i18n/config';
import { getDictionary } from '@/i18n/dictionary';

/**
 * Adresse publique du site, sans barre finale. Elle sert aux adresses canoniques, aux versions
 * linguistiques, au plan du site et aux données structurées : à renseigner à la mise en ligne.
 */
export function siteUrl(): string {
  return (process.env.NEXT_PUBLIC_SITE_URL?.trim() || 'http://localhost:3000').replace(/\/$/, '');
}

/** Adresse absolue d'un chemin du site (`/fr/soins`). */
export function absoluteUrl(path: string): string {
  return `${siteUrl()}${path}`;
}

/** Langue et région annoncées aux réseaux sociaux : le site s'adresse à Nador. */
const ogLocales: Record<Locale, string> = { fr: 'fr_MA', ar: 'ar_MA', en: 'en_US' };

/**
 * Métadonnées d'une page publique : adresse canonique, versions dans les trois langues
 * (le français par défaut) et aperçu de partage. `path` est le chemin sans la langue
 * (`''` pour l'accueil, `/soins`, `/soins/injection`).
 */
export function pageMetadata(
  locale: Locale,
  path: string,
  { title, description }: { title?: string; description?: string } = {},
): Metadata {
  const t = getDictionary(locale);
  const languages: Record<string, string> = Object.fromEntries(locales.map((code) => [code, `/${code}${path}`]));
  languages['x-default'] = `/fr${path}`;

  return {
    ...(title ? { title } : {}),
    ...(description ? { description } : {}),
    alternates: { canonical: `/${locale}${path}`, languages },
    openGraph: {
      type: 'website',
      siteName: t.siteName,
      locale: ogLocales[locale],
      alternateLocale: locales.filter((code) => code !== locale).map((code) => ogLocales[code]),
      url: `/${locale}${path}`,
      title: title ?? `${t.siteName} — ${t.heroTitle}`,
      description: description ?? t.metaDescription,
      images: [{ url: '/images/hero-1200.webp', width: 1200, alt: t.heroTitle }],
    },
  };
}

/** Identifiants stables des entités, repris d'une page à l'autre. */
export const organizationId = () => `${siteUrl()}/#agence`;
export const websiteId = () => `${siteUrl()}/#site`;

/** Montant de l'API (centimes de dirham) en nombre décimal, pour les données structurées. */
export function dirhams(centimes: number): string {
  return (centimes / 100).toFixed(2);
}
