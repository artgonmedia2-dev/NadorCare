import { NextResponse, type NextRequest } from 'next/server';

import { callApi, forbidden, hasSiteHeader, languageOf } from '@/lib/relay';
import { writeToken } from '@/lib/session';

/**
 * Vérification du code. Le jeton renvoyé par l'API est rangé dans un cookie `httpOnly`
 * et n'est jamais transmis à la page.
 */
export async function POST(request: NextRequest): Promise<NextResponse> {
  if (!hasSiteHeader(request)) {
    return forbidden();
  }

  const language = languageOf(request);
  const body = (await request.json().catch(() => ({}))) as {
    phone?: unknown;
    code?: unknown;
    accept_terms?: unknown;
  };

  const { status, json } = await callApi('/auth/otp/verify', {
    method: 'POST',
    language,
    contentType: 'application/json',
    body: JSON.stringify({
      phone: String(body.phone ?? ''),
      code: String(body.code ?? ''),
      // Le site ouvre une session de patient, comme l'application patient.
      app: 'patient',
      device_name: 'web',
      accept_terms: body.accept_terms === true,
      locale: language,
    }),
  });

  if (status >= 200 && status < 300 && typeof json.token === 'string') {
    await writeToken(json.token);
    return NextResponse.json({ user: json.user ?? null }, { status: 200 });
  }

  return NextResponse.json(json, { status });
}
