import type { Metadata } from 'next';
import { notFound } from 'next/navigation';

import { Faq } from '@/components/Faq';
import { InfoIcon } from '@/components/icons';
import { PriceExplorer } from '@/components/PriceExplorer';
import { guardRates, guardShifts } from '@/content/home-guard';
import { isLocale } from '@/i18n/config';
import { getDictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import { fetchPublic } from '@/lib/server-api';
import type { CareCategory, CareService, Surcharge } from '@/lib/types';

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  if (!isLocale(locale)) {
    return {};
  }
  const t = getDictionary(locale);
  return { title: t.pricesTitle, description: t.pricesIntro };
}

/** Tarifs : grille des soins à explorer, garde-malade, questions fréquentes. */
export default async function PricesPage({ params }: Props) {
  const { locale } = await params;
  if (!isLocale(locale)) {
    notFound();
  }
  const t = getDictionary(locale);

  const [categories, services, surcharges] = await Promise.all([
    fetchPublic<CareCategory[]>('/catalogue/categories', locale),
    fetchPublic<CareService[]>('/catalogue/services', locale),
    fetchPublic<Surcharge[]>('/catalogue/surcharges', locale),
  ]);
  const evening = surcharges?.find((surcharge) => surcharge.type === 'night') ?? null;

  return (
    <>
      <section className="page-head">
        <div className="container stack" style={{ ['--gap' as string]: '1rem' }}>
          <h1>{t.pricesTitle}</h1>
          <p className="lead">{t.pricesIntro}</p>
        </div>
      </section>

      <section className="section">
        <div className="container">
          {categories === null || services === null ? (
            <div className="notice notice-error" role="alert">
              <InfoIcon />
              <p>{t.apiDown}</p>
            </div>
          ) : (
            <PriceExplorer locale={locale} t={t} categories={categories} services={services} evening={evening} />
          )}
        </div>
      </section>

      <section className="section section-tinted" aria-labelledby="titre-garde">
        <div className="container stack" style={{ ['--gap' as string]: '1.25rem' }}>
          <h2 id="titre-garde">{t.guardTitle}</h2>
          <p className="lead">{t.guardIntro}</p>

          {/* Un tableau sur grand écran ; sur téléphone, chaque profil devient une carte. */}
          <div className="table-card">
            <table className="rate-table">
              <thead>
                <tr>
                  <th scope="col">{t.guardProfile}</th>
                  {guardShifts.map((shift) => (
                    <th key={shift} scope="col">
                      {t[shift]}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {guardRates.map(({ role, prices }) => (
                  <tr key={role}>
                    <th scope="row">{t[role]}</th>
                    {prices.map((price, index) => {
                      const shift = guardShifts[index];
                      return (
                        <td key={shift} data-label={shift ? t[shift] : undefined}>
                          {price === null ? (
                            <span className="muted" aria-hidden="true">
                              —
                            </span>
                          ) : (
                            <span className="ltr">{formatDirhams(price, locale, t.currencyUnit)}</span>
                          )}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section className="section" aria-labelledby="titre-faq">
        <div className="container narrow-wide stack" style={{ ['--gap' as string]: '1.25rem' }}>
          <h2 id="titre-faq">{t.faqTitle}</h2>
          <Faq t={t} locale={locale} evening={evening} />
        </div>
      </section>
    </>
  );
}
