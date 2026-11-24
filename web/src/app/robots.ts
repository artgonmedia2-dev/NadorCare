import type { MetadataRoute } from 'next';

import { absoluteUrl } from '@/lib/seo';

/**
 * Accès des robots. Tout le site public est ouvert ; seul le relais vers l'API est fermé.
 * Le parcours de réservation reste ouvert mais porte `noindex` : un robot doit pouvoir lire
 * cette consigne pour l'appliquer.
 *
 * Les robots de recherche des assistants (ChatGPT, Claude, Perplexity) sont nommés pour
 * rendre l'intention explicite : un robot nommé ne suit que son propre groupe, d'où la même
 * règle répétée. Les robots d'entraînement (GPTBot, ClaudeBot, Google-Extended, CCBot,
 * Applebot-Extended) suivent la règle générale : les bloquer est un choix de l'agence,
 * sans effet sur la présence dans les moteurs de recherche.
 */
export default function robots(): MetadataRoute.Robots {
  const rule = { allow: '/', disallow: '/api/' };

  return {
    rules: [
      { userAgent: '*', ...rule },
      { userAgent: ['OAI-SearchBot', 'Claude-SearchBot', 'PerplexityBot'], ...rule },
    ],
    sitemap: absoluteUrl('/sitemap.xml'),
  };
}
