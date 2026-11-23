'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

import { localeNames, locales, type Locale } from '@/i18n/config';

/** Change de langue en restant sur la même page. */
export function LanguageSwitch({ current, label }: { current: Locale; label: string }) {
  const pathname = usePathname() ?? `/${current}`;
  const rest = pathname.split('/').slice(2).join('/');

  return (
    <nav className="lang-switch" aria-label={label}>
      {locales.map((code) => (
        <Link
          key={code}
          href={`/${code}${rest ? `/${rest}` : ''}`}
          lang={code}
          hrefLang={code}
          aria-current={code === current ? 'true' : undefined}
        >
          {localeNames[code]}
        </Link>
      ))}
    </nav>
  );
}
