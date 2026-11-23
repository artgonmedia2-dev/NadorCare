import { NextResponse, type NextRequest } from 'next/server';

import { callApi, forbidden, hasSiteHeader, languageOf } from '@/lib/relay';
import { clearToken, readToken } from '@/lib/session';

/**
 * Relais des appels du compte connecté vers l'API. Seules les ressources dont la réservation
 * a besoin sont ouvertes : tout le reste est refusé.
 */
const ALLOWED = [
  /^patient-profiles$/,
  /^addresses$/,
  /^bookings$/,
  /^bookings\/slots$/,
  /^bookings\/quote$/,
  /^files\/prescriptions$/,
];

async function relay(request: NextRequest, segments: string[]): Promise<NextResponse> {
  if (!hasSiteHeader(request)) {
    return forbidden();
  }

  const path = segments.join('/');
  if (!ALLOWED.some((pattern) => pattern.test(path))) {
    return NextResponse.json({ code: 'not_found', message: '' }, { status: 404 });
  }

  const token = await readToken();
  if (!token) {
    return NextResponse.json({ code: 'unauthenticated', message: '' }, { status: 401 });
  }

  const method = request.method;
  const contentType = request.headers.get('content-type');
  // Le corps est transmis tel quel, y compris un envoi de fichier (ordonnance).
  const body = method === 'GET' ? null : await request.arrayBuffer();

  const { status, json } = await callApi(`/${path}${request.nextUrl.search}`, {
    method,
    language: languageOf(request),
    token,
    body,
    contentType: body && body.byteLength > 0 ? contentType : null,
  });

  if (status === 401) {
    await clearToken();
  }

  return NextResponse.json(json, { status });
}

type Context = { params: Promise<{ path: string[] }> };

export async function GET(request: NextRequest, context: Context): Promise<NextResponse> {
  return relay(request, (await context.params).path);
}

export async function POST(request: NextRequest, context: Context): Promise<NextResponse> {
  return relay(request, (await context.params).path);
}
