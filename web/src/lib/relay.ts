import 'server-only';

import { NextResponse, type NextRequest } from 'next/server';

import { apiBaseUrl } from './server-api';

/**
 * Garde contre les requêtes forgées depuis un autre site : nos appels portent un en-tête
 * qu'un formulaire ou une image d'un site tiers ne peut pas ajouter.
 */
export function hasSiteHeader(request: NextRequest): boolean {
  return request.headers.get('x-nadorcare-site') === '1';
}

export function forbidden(): NextResponse {
  return NextResponse.json({ code: 'forbidden', message: 'Forbidden' }, { status: 403 });
}

/** Langue demandée par la page, transmise à l'API qui traduit ses messages. */
export function languageOf(request: NextRequest): string {
  const value = request.headers.get('accept-language') ?? 'fr';
  return /^(fr|ar|en)$/.test(value) ? value : 'fr';
}

/** Appelle l'API et renvoie son corps JSON avec son code d'état. */
export async function callApi(
  path: string,
  init: { method: string; language: string; token?: string | null; body?: BodyInit | null; contentType?: string | null },
): Promise<{ status: number; json: Record<string, unknown> }> {
  const headers: Record<string, string> = { Accept: 'application/json', 'Accept-Language': init.language };
  if (init.token) {
    headers.Authorization = `Bearer ${init.token}`;
  }
  if (init.contentType) {
    headers['Content-Type'] = init.contentType;
  }

  try {
    const response = await fetch(`${apiBaseUrl()}${path}`, {
      method: init.method,
      headers,
      body: init.body ?? undefined,
      cache: 'no-store',
    });
    const text = await response.text();
    let json: Record<string, unknown> = {};
    try {
      json = text ? (JSON.parse(text) as Record<string, unknown>) : {};
    } catch {
      json = { code: 'unknown', message: '' };
    }
    return { status: response.status, json };
  } catch {
    return { status: 503, json: { code: 'network', message: '' } };
  }
}
