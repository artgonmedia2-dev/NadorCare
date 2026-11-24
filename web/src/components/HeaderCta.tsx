'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

/** Bouton « Réserver » de l'en-tête. Caché pendant une réservation : on y est déjà. */
export function HeaderCta({ href, label }: { href: string; label: string }) {
  const pathname = usePathname() ?? '';
  if (pathname.includes('/reserver/')) {
    return null;
  }
  return (
    <Link className="button button-primary button-small" href={href}>
      {label}
    </Link>
  );
}
