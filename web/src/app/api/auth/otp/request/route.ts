import { NextResponse, type NextRequest } from 'next/server';

import { callApi, forbidden, hasSiteHeader, languageOf } from '@/lib/relay';

/** Demande d'un code par SMS. */
export async function POST(request: NextRequest): Promise<NextResponse> {
  if (!hasSiteHeader(request)) {
    return forbidden();
  }

  const body = (await request.json().catch(() => ({}))) as { phone?: unknown };
  const { status, json } = await callApi('/auth/otp/request', {
    method: 'POST',
    language: languageOf(request),
    contentType: 'application/json',
    body: JSON.stringify({ phone: String(body.phone ?? '') }),
  });

  return NextResponse.json(json, { status });
}
