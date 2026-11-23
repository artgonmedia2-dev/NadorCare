import 'server-only';

import type { Locale } from '@/i18n/config';

/** Adresse de l'API, connue du serveur seulement. */
export function apiBaseUrl(): string {
  return (process.env.API_BASE_URL ?? 'http://127.0.0.1:8000/api/v1').replace(/\/$/, '');
}

/**
 * Lecture publique du catalogue, depuis le serveur. Renvoie `null` si l'API ne répond pas,
 * pour que la page s'affiche quand même avec un message.
 */
export async function fetchPublic<T>(path: string, locale: Locale): Promise<T | null> {
  try {
    const response = await fetch(`${apiBaseUrl()}${path}`, {
      headers: { Accept: 'application/json', 'Accept-Language': locale },
      // Le catalogue change peu : une minute de cache suffit.
      next: { revalidate: 60 },
    });
    if (!response.ok) {
      return null;
    }
    const json = (await response.json()) as { data: T };
    return json.data;
  } catch {
    return null;
  }
}
