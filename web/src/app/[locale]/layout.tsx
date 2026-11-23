import type { Metadata, Viewport } from 'next';
import { Figtree, Noto_Sans, Noto_Sans_Arabic } from 'next/font/google';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import type { ReactNode } from 'react';

import { BrandMark, ChatIcon, PhoneIcon, WarningIcon } from '@/components/icons';
import { LanguageSwitch } from '@/components/LanguageSwitch';
import { direction, isLocale, locales } from '@/i18n/config';
import { getDictionary } from '@/i18n/dictionary';
import { fetchPublic } from '@/lib/server-api';
import type { CareCategory } from '@/lib/types';

import '../globals.css';
import '../sections.css';
import '../home.css';

// Polices servies par le site lui-même (aucun appel à un serveur tiers pour le visiteur).
const heading = Figtree({ subsets: ['latin'], weight: ['600', '700', '800'], variable: '--font-heading', display: 'swap' });
const body = Noto_Sans({ subsets: ['latin'], weight: ['400', '600', '700'], variable: '--font-body', display: 'swap' });
const arabic = Noto_Sans_Arabic({
  subsets: ['arabic'],
  weight: ['400', '600', '700'],
  variable: '--font-arabic',
  display: 'swap',
});

type Props = { children: ReactNode; params: Promise<{ locale: string }> };

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  if (!isLocale(locale)) {
    return {};
  }
  const t = getDictionary(locale);

  return {
    title: { default: `${t.siteName} — ${t.heroTitle}`, template: `%s — ${t.siteName}` },
    description: t.metaDescription,
    alternates: { languages: Object.fromEntries(locales.map((code) => [code, `/${code}`])) },
  };
}

export const viewport: Viewport = { width: 'device-width', initialScale: 1, themeColor: '#083f3b' };

export default async function LocaleLayout({ children, params }: Props) {
  const { locale } = await params;
  if (!isLocale(locale)) {
    notFound();
  }
  const t = getDictionary(locale);
  const categories = (await fetchPublic<CareCategory[]>('/catalogue/categories', locale)) ?? [];

  // Coordonnées : affichées seulement une fois fixées dans l'environnement.
  const phone = process.env.NEXT_PUBLIC_CONTACT_PHONE?.trim();
  const whatsapp = process.env.NEXT_PUBLIC_WHATSAPP_NUMBER?.trim().replace(/\D/g, '');

  return (
    <html
      lang={locale}
      dir={direction(locale)}
      className={`${heading.variable} ${body.variable} ${arabic.variable}`}
    >
      <body>
        <a className="skip-link" href="#contenu">
          {t.skipToContent}
        </a>

        {/* Bandeau supérieur : où l'on intervient, comment joindre, la langue. */}
        <div className="top-bar">
          <div className="container">
            <p className="top-bar-note">{t.heroEyebrow}</p>
            {phone && (
              <a className="top-bar-link ltr" href={`tel:${phone}`}>
                <PhoneIcon />
                {phone}
              </a>
            )}
            <LanguageSwitch current={locale} label={t.languageLabel} />
          </div>
        </div>

        <header className="site-header">
          <div className="container">
            <Link className="brand" href={`/${locale}`}>
              <BrandMark />
              <span>{t.siteName}</span>
            </Link>
            <nav className="site-nav" aria-label={t.siteName}>
              <Link className="nav-link" href={`/${locale}/soins`}>
                {t.homeCatalogue}
              </Link>
              <Link className="nav-link" href={`/${locale}/tarifs`}>
                {t.navPrices}
              </Link>
              <Link className="button button-primary button-small" href={`/${locale}/soins`}>
                {t.headerCta}
              </Link>
            </nav>
          </div>
        </header>

        <main id="contenu">{children}</main>

        <footer className="site-footer">
          <div className="container footer-grid">
            <div className="stack" style={{ ['--gap' as string]: '0.75rem' }}>
              <p className="brand">
                <BrandMark size={28} />
                <span>{t.siteName}</span>
              </p>
              <p>{t.footerTagline}</p>
            </div>

            {categories.length > 0 && (
              <nav aria-labelledby="pied-soins">
                <h2 id="pied-soins">{t.footerCare}</h2>
                <ul>
                  {categories.map((category) => (
                    <li key={category.slug}>
                      <Link href={`/${locale}/soins#${category.slug}`}>{category.name}</Link>
                    </li>
                  ))}
                </ul>
              </nav>
            )}

            <nav aria-labelledby="pied-site">
              <h2 id="pied-site">{t.footerSite}</h2>
              <ul>
                <li>
                  <Link href={`/${locale}`}>{t.navHome}</Link>
                </li>
                <li>
                  <Link href={`/${locale}/soins`}>{t.allServices}</Link>
                </li>
                <li>
                  <Link href={`/${locale}/tarifs`}>{t.navPrices}</Link>
                </li>
              </ul>
            </nav>

            <div>
              <h2>{t.footerEmergency}</h2>
              <div className="notice notice-warning" role="note">
                <WarningIcon />
                <p>{t.emergencyNotice}</p>
              </div>
            </div>
          </div>
        </footer>

        {(phone || whatsapp) && (
          <div className="contact-bar">
            {whatsapp && (
              <a className="button button-primary" href={`https://wa.me/${whatsapp}`} rel="noopener noreferrer">
                <ChatIcon />
                {t.whatsapp}
              </a>
            )}
            {phone && (
              <a className="button button-secondary" style={{ background: 'var(--card)' }} href={`tel:${phone}`}>
                <PhoneIcon />
                {t.callUs}
              </a>
            )}
          </div>
        )}
      </body>
    </html>
  );
}
