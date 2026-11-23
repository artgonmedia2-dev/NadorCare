import { NextResponse, type NextRequest } from 'next/server';

import { callApi, forbidden, hasSiteHeader, languageOf } from '@/lib/relay';
import { clearToken, readToken } from '@/lib/session';

/** Dit à la page si quelqu'un est connecté, sans jamais lui donner le jeton. */
export async function GET(request: NextRequest): Promise<NextResponse> {
  const token = await readToken();
  if (!token) {
    return NextResponse.json({ user: null });
  }

  const { status, json } = await callApi('/me', { method: 'GET', language: languageOf(request), token });
  if (status === 401) {
    await clearToken();
    return NextResponse.json({ user: null });
  }

  return NextResponse.json({ user: status === 200 ? (json.data ?? null) : null });
}

/** Déconnexion : le jeton est révoqué côté API, puis le cookie est effacé. */
export async function DELETE(request: NextRequest): Promise<NextResponse> {
  if (!hasSiteHeader(request)) {
    return forbidden();
  }

  const token = await readToken();
  if (token) {
    await callApi('/auth/logout', { method: 'POST', language: languageOf(request), token });
  }
  await clearToken();

  return NextResponse.json({ user: null });
}
