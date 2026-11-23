import 'server-only';

import { cookies } from 'next/headers';

/**
 * Le jeton de l'API vit dans un cookie `httpOnly` : le JavaScript de la page ne peut pas le lire,
 * ce qui le protège d'un script injecté. Le navigateur ne parle jamais directement à l'API.
 */
const COOKIE = 'nc_session';
const THIRTY_DAYS = 60 * 60 * 24 * 30;

export async function readToken(): Promise<string | null> {
  return (await cookies()).get(COOKIE)?.value ?? null;
}

export async function writeToken(token: string): Promise<void> {
  (await cookies()).set(COOKIE, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: THIRTY_DAYS,
  });
}

export async function clearToken(): Promise<void> {
  (await cookies()).delete(COOKIE);
}
