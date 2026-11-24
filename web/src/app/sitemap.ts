import type { MetadataRoute } from 'next';

import { defaultLocale, locales } from '@/i18n/config';
import { absoluteUrl } from '@/lib/seo';
import { fetchPublic } from '@/lib/server-api';
import type { CareService } from '@/lib/types';

// Le catalogue change peu : le plan du site est recalculé toutes les heures.
export const revalidate = 3600;

/**
 * Plan du site : les pages publiques dans les trois langues, chacune avec ses traductions.
 * Les fiches de soins viennent du catalogue ; les soins fermés (téléconsultation) n'y sont pas,
 * puisque l'API ne les renvoie pas. Pas de date de modification : l'API n'en fournit pas,
 * et une date inventée tromperait les moteurs.
 */
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const services = (await fetchPublic<CareService[]>('/catalogue/services', defaultLocale)) ?? [];
  const paths = [
    '',
    '/soins',
    '/tarifs',
    ...services.filter((service) => service.delivery_mode === 'home').map((service) => `/soins/${service.slug}`),
  ];

  return paths.flatMap((path) =>
    locales.map((locale) => ({
      url: absoluteUrl(`/${locale}${path}`),
      alternates: {
        languages: Object.fromEntries(locales.map((code) => [code, absoluteUrl(`/${code}${path}`)])),
      },
    })),
  );
}
