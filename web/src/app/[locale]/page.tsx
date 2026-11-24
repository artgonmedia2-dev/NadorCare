import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';

import { Carousel } from '@/components/Carousel';
import { Faq } from '@/components/Faq';
import { QuickBook, type QuickBookGroup } from '@/components/QuickBook';
import { CategoryIcon, CheckIcon, ClockIcon, InfoIcon } from '@/components/icons';
import { categoryPictures, Picture } from '@/components/Picture';
import { isLocale } from '@/i18n/config';
import { fill, getDictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import { pageMetadata } from '@/lib/seo';
import { fetchPublic } from '@/lib/server-api';
import type { CareCategory, CareService, Surcharge } from '@/lib/types';

export async function generateMetadata({ params }: { params: Promise<{ locale: string }> }): Promise<Metadata> {
  const { locale } = await params;
  return isLocale(locale) ? pageMetadata(locale, '') : {};
}

export default async function HomePage({ params }: { params: Promise<{ locale: string }> }) {
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

  // Réservation rapide : tous les soins, rangés par catégorie, avec leur prix de départ.
  const quickGroups: QuickBookGroup[] = (categories ?? [])
    .map((category) => ({
      category: category.name,
      services: (services ?? [])
        .filter((service) => service.category.slug === category.slug)
        .map((service) => ({
          slug: service.slug,
          name: service.name,
          price: formatDirhams(service.price.amount, locale, t.currencyUnit),
        })),
    }))
    .filter((group) => group.services.length > 0);

  // Aperçu : le premier soin de chaque catégorie, dans l'ordre des catégories.
  const featured = (categories ?? []).flatMap((category) =>
    (services ?? []).filter((service) => service.category.slug === category.slug).slice(0, 1),
  );

  return (
    <>
      <section className="hero" aria-labelledby="titre-accroche">
        <div className="container hero-grid">
          <div className="stack" style={{ ['--gap' as string]: '1.5rem' }}>
            <h1 id="titre-accroche">{t.heroTitle}</h1>
            <p className="lead">{t.heroBody}</p>
            {quickGroups.length > 0 ? (
              <QuickBook locale={locale} t={t} groups={quickGroups} />
            ) : (
              <p>
                <Link className="button button-primary button-large" href={`/${locale}/soins`}>
                  {t.heroCta}
                </Link>
              </p>
            )}
            <p>
              <Link className="text-link quickbook-more" href={`/${locale}/tarifs`}>
                {t.seeAllPrices}
              </Link>
            </p>
            <ul className="hero-proofs">
              {[t.heroProof1, t.heroProof2, t.heroProof3].map((proof) => (
                <li key={proof}>
                  <CheckIcon size={18} />
                  {proof}
                </li>
              ))}
            </ul>
          </div>

          <div className="hero-media">
            <Picture name="hero" sizes="(min-width: 900px) 480px, 100vw" priority />
          </div>
        </div>

        {/* Le tracé de pouls du logo, sur la lisière de l'accroche : le seul ornement de la page. */}
        <svg className="hero-pulse" viewBox="0 0 1440 120" preserveAspectRatio="none" aria-hidden="true" focusable="false">
          <path
            d="M0 60 H930 L975 60 L998 28 L1030 104 L1066 6 L1092 60 H1440"
            pathLength={1}
            fill="none"
            stroke="currentColor"
            strokeWidth="3"
            strokeLinecap="round"
            strokeLinejoin="round"
            vectorEffect="non-scaling-stroke"
          />
        </svg>
      </section>

      <section className="section" aria-labelledby="titre-apropos">
        <div className="container about-grid">
          <div className="about-media">
            <Picture name="kinesitherapie" sizes="(min-width: 900px) 520px, 100vw" />
          </div>
          <div className="stack" style={{ ['--gap' as string]: '1rem' }}>
            <h2 id="titre-apropos">{t.aboutTitle}</h2>
            <p className="lead">{t.aboutBody}</p>
            <ul className="check-list">
              {[t.trust1Title, t.trust2Title, t.trust3Title, t.aboutPoint4].map((point) => (
                <li key={point}>
                  <span className="check-mark">
                    <CheckIcon size={16} />
                  </span>
                  {point}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      <section className="section section-tinted" aria-labelledby="titre-soins">
        <div className="container stack" style={{ ['--gap' as string]: '1.5rem' }}>
          <div className="section-head">
            <h2 id="titre-soins">{t.featuredTitle}</h2>
            <Link className="text-link" href={`/${locale}/soins`}>
              {t.allServices}
            </Link>
          </div>

          {categories === null || services === null ? (
            <div className="notice notice-error" role="alert">
              <InfoIcon />
              <p>{t.apiDown}</p>
            </div>
          ) : featured.length === 0 ? (
            <p className="muted">{t.catalogueEmpty}</p>
          ) : (
            <Carousel label={t.featuredTitle} previousLabel={t.carouselPrevious} nextLabel={t.carouselNext}>
              {featured.map((service) => (
                <li key={service.slug}>
                  <Link className="offer-card" href={`/${locale}/soins/${service.slug}`}>
                    {categoryPictures.has(service.category.slug) ? (
                      <Picture name={service.category.slug} sizes="320px" />
                    ) : (
                      <span className="category-fallback">
                        <CategoryIcon slug={service.category.slug} size={56} />
                      </span>
                    )}
                    <span className="offer-body">
                      <span className="offer-category">{service.category.name}</span>
                      <span className="offer-name">{service.name}</span>
                      <span className="offer-foot">
                        <span className="offer-duration">
                          <ClockIcon size={18} />
                          <span className="ltr">{fill(t.serviceDuration, { minutes: service.duration_minutes })}</span>
                        </span>
                        <span className="offer-price ltr">
                          {formatDirhams(service.price.amount, locale, t.currencyUnit)}
                        </span>
                      </span>
                    </span>
                  </Link>
                </li>
              ))}
            </Carousel>
          )}
        </div>
      </section>

      <section className="section section-tinted" aria-labelledby="titre-etapes">
        <div className="container stack" style={{ ['--gap' as string]: '1.5rem' }}>
          <h2 id="titre-etapes">{t.howTitle}</h2>
          <ol className="steps">
            <li>
              <h3>{t.how1Title}</h3>
              <p className="muted">{t.how1Body}</p>
            </li>
            <li>
              <h3>{t.how2Title}</h3>
              <p className="muted">{t.how2Body}</p>
            </li>
            <li>
              <h3>{t.how3Title}</h3>
              <p className="muted">{t.how3Body}</p>
            </li>
          </ol>
        </div>
      </section>

      <section className="section section-tinted" aria-labelledby="titre-faq">
        <div className="container faq-grid">
          <h2 id="titre-faq">{t.faqTitle}</h2>
          <Faq t={t} locale={locale} evening={evening} />
        </div>
      </section>

      <section className="container closing" aria-labelledby="titre-fin">
        <div className="stack" style={{ ['--gap' as string]: '0.35rem' }}>
          <h2 id="titre-fin">{t.ctaTitle}</h2>
          <p>{t.ctaBody}</p>
        </div>
        <Link className="button button-primary button-large" href={`/${locale}/soins`}>
          {t.heroCta}
        </Link>
      </section>
    </>
  );
}
