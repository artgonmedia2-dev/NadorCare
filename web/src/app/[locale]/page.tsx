import Link from 'next/link';
import { notFound } from 'next/navigation';

import { Carousel } from '@/components/Carousel';
import { Faq } from '@/components/Faq';
import {
  ArrowIcon,
  CareIcon,
  CashIcon,
  CheckIcon,
  ClockIcon,
  InfoIcon,
  LockIcon,
  ShieldIcon,
} from '@/components/icons';
import { categoryPictures, Picture } from '@/components/Picture';
import { isLocale } from '@/i18n/config';
import { fill, getDictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import { fetchPublic } from '@/lib/server-api';
import type { CareCategory, CareService, Surcharge } from '@/lib/types';

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

  // Aperçu : le premier soin de chaque catégorie, dans l'ordre des catégories.
  const featured = (categories ?? []).flatMap((category) =>
    (services ?? []).filter((service) => service.category.slug === category.slug).slice(0, 1),
  );

  return (
    <>
      <section className="hero">
        <div className="container hero-grid">
          <div className="stack" style={{ ['--gap' as string]: '1.25rem' }}>
            <h1>{t.heroTitle}</h1>
            <p className="lead">{t.heroBody}</p>
            <p className="hero-actions">
              <Link className="button button-primary button-large" href={`/${locale}/soins`}>
                {t.heroCta}
                <ArrowIcon />
              </Link>
              <Link className="button button-secondary button-large" href={`/${locale}/tarifs`}>
                {t.seeAllPrices}
              </Link>
            </p>
          </div>

          <div className="hero-visual">
            <div className="hero-media">
              <Picture name="hero" sizes="(min-width: 900px) 520px, 100vw" priority />
            </div>
            {/* Carte posée sur la photo : l'engagement qui rassure avant de réserver. */}
            <div className="hero-float">
              <span className="icon-tile">
                <ShieldIcon />
              </span>
              <p>
                <strong>{t.trust1Title}</strong>
                <span>{t.trust1Body}</span>
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Bande d'atouts à cheval sur l'accroche. */}
      <section className="feature-strip" aria-label={t.trustTitle}>
        <div className="container">
          <ul>
            <li>
              <span className="icon-tile">
                <ShieldIcon />
              </span>
              <p>
                <strong>{t.trust1Title}</strong>
              </p>
            </li>
            <li>
              <span className="icon-tile">
                <LockIcon />
              </span>
              <p>
                <strong>{t.trust2Title}</strong>
              </p>
            </li>
            <li>
              <span className="icon-tile">
                <CashIcon />
              </span>
              <p>
                <strong>{t.trust3Title}</strong>
              </p>
            </li>
          </ul>
        </div>
      </section>

      <section className="section" aria-labelledby="titre-apropos">
        <div className="container about-grid">
          <div className="about-media">
            <Picture name="kinesitherapie" sizes="(min-width: 900px) 520px, 100vw" />
          </div>
          <div className="stack" style={{ ['--gap' as string]: '1rem' }}>
            <p className="eyebrow">{t.aboutEyebrow}</p>
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
            <p>
              <Link className="button button-primary" href={`/${locale}/soins`}>
                {t.allServices}
                <ArrowIcon />
              </Link>
            </p>
          </div>
        </div>
      </section>

      <section className="section section-tinted" aria-labelledby="titre-soins">
        <div className="container stack" style={{ ['--gap' as string]: '1.5rem' }}>
          <div className="section-head">
            <div>
              <p className="eyebrow">{t.featuredEyebrow}</p>
              <h2 id="titre-soins">{t.featuredTitle}</h2>
            </div>
            <Link className="text-link" href={`/${locale}/tarifs`}>
              {t.seeAllPrices}
              <ArrowIcon size={18} />
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
                        <CareIcon size={40} />
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

      {/* Chiffres réels, lus dans le catalogue : aucun n'est inventé. */}
      {categories !== null && services !== null && services.length > 0 && (
        <section className="stats-band" aria-labelledby="titre-chiffres">
          <div className="container">
            <h2 id="titre-chiffres">{t.statsTitle}</h2>
            <dl>
              <div>
                <dd>{services.length}</dd>
                <dt>{t.statServices}</dt>
              </div>
              <div>
                <dd>{categories.length}</dd>
                <dt>{t.statCategories}</dt>
              </div>
              <div>
                <dd>3</dd>
                <dt>{t.statLanguages}</dt>
              </div>
            </dl>
          </div>
        </section>
      )}

      <section className="section" aria-labelledby="titre-etapes">
        <div className="container stack" style={{ ['--gap' as string]: '1.5rem' }}>
          <div>
            <p className="eyebrow">{t.howEyebrow}</p>
            <h2 id="titre-etapes">{t.howTitle}</h2>
          </div>
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
          <div className="faq-media">
            <Picture name="hygiene-et-confort" sizes="(min-width: 900px) 440px, 100vw" />
          </div>
          <div className="stack" style={{ ['--gap' as string]: '1.25rem' }}>
            <div>
              <p className="eyebrow">{t.faqEyebrow}</p>
              <h2 id="titre-faq">{t.faqTitle}</h2>
            </div>
            <Faq t={t} locale={locale} evening={evening} />
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <div className="cta-band">
            <div className="stack" style={{ ['--gap' as string]: '0.5rem' }}>
              <h2>{t.ctaTitle}</h2>
              <p>{t.ctaBody}</p>
            </div>
            <div className="hero-actions">
              <Link className="button button-inverse button-large" href={`/${locale}/soins`}>
                {t.heroCta}
                <ArrowIcon />
              </Link>
              <Link className="button button-ghost button-large" href={`/${locale}/tarifs`}>
                {t.seeAllPrices}
              </Link>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
