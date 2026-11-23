import type { Locale } from '@/i18n/config';

import type { ApiError } from './types';

/** Erreur renvoyée par l'API, avec son message déjà traduit. */
export class ApiFailure extends Error {
  constructor(readonly detail: ApiError) {
    super(detail.message);
  }

  get code(): string {
    return this.detail.code;
  }

  firstErrorFor(field: string): string | undefined {
    return this.detail.errors?.[field]?.[0];
  }
}

/**
 * Appel du navigateur vers les relais du site (`/api/...`). Le navigateur ne connaît ni
 * l'adresse de l'API ni le jeton.
 */
export async function call<T>(
  locale: Locale,
  path: string,
  init: { method?: 'GET' | 'POST' | 'DELETE'; json?: unknown; form?: FormData } = {},
): Promise<T> {
  const headers: Record<string, string> = { 'x-nadorcare-site': '1', 'accept-language': locale };
  let body: BodyInit | undefined;

  if (init.form) {
    body = init.form;
  } else if (init.json !== undefined) {
    headers['content-type'] = 'application/json';
    body = JSON.stringify(init.json);
  }

  let response: Response;
  try {
    response = await fetch(path, { method: init.method ?? 'GET', headers, body, credentials: 'same-origin' });
  } catch {
    throw new ApiFailure({ code: 'network', message: '', status: 0 });
  }

  const payload = (await response.json().catch(() => ({}))) as Record<string, unknown>;

  if (!response.ok) {
    throw new ApiFailure({
      code: typeof payload.code === 'string' ? payload.code : 'unknown',
      message: typeof payload.message === 'string' ? payload.message : '',
      status: response.status,
      errors: payload.errors as Record<string, string[]> | undefined,
      retry_after: typeof payload.retry_after === 'number' ? payload.retry_after : undefined,
    });
  }

  return payload as T;
}
