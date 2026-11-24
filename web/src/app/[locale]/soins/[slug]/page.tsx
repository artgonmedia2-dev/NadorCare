import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';

import { CashIcon, CategoryIcon, ClockIcon, InfoIcon, WarningIcon } from '@/components/icons';
import { JsonLd } from '@/components/JsonLd';
import { isLocale } from '@/i18n/config';
import { fill, getDictionary, isolateLtr } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import { absoluteUrl, dirhams, organizationId, pageMetadata } from '@/lib/seo';
import { fetchPublic } from '@/lib/server-api';
import type { CareService } from '@/lib/types';

type Props = { params: Promise<{ locale: string; slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale, slug } = await params;
  if (!isLocale(locale)) {
    return {};
  }
  const service = await fetchPublic<CareService>(`/catalogue/services/${encodeURIComponent(slug)}`, locale);
  if (!service) {
    return {};
  }
  const t = getDictionary(locale);
  // Sans description dans le catalogue, le résumé tiré des données en tient lieu.
  const description =
    service.description ??
    fill(t.serviceSummary, {
      service: service.name,
      minutes: service.duration_minutes,
      price: formatDirhams(service.price.amount, locale, t.currencyUnit),
    });
  return pageMetadata(locale, `/soins/${service.slug}`, { title: service.name, description });
}

/** Fiche d'un soin : description et règles à gauche, carte de réservation à droite. */
export default async function ServicePage({ params }: Props) {
  const { locale, slug } = await params;
  if (!isLocale(locale)) {
    notFound();
  }
  const t = getDictionary(locale);
  const service = await fetchPublic<CareService>(`/catalogue/services/${encodeURIComponent(slug)}`, locale);
  if (!service) {
    notFound();
  }

  const price = formatDirhams(service.price.amount, locale, t.currencyUnit);
  const pageUrl = absoluteUrl(`/${locale}/soins/${service.slug}`);
  const isHome = service.delivery_mode === 'home';

  // Questions tirées des données du soin : chaque réponse se lit seule et ne dit que ce qui est vrai.
  const questions: { question: string; answer: string }[] = [
    { question: t.serviceFaqPriceQ, answer: fill(t.serviceFaqPriceA, { price: isolateLtr(price) }) },
    ...(service.professional_category
      ? [{ question: t.serviceFaqWhoQ, answer: fill(t.serviceFaqWhoA, { profession: service.professional_category }) }]
      : []),
    {
      question: t.faq2Q,
      answer: service.requires_prescription ? t.servicePrescriptionYes : t.servicePrescriptionNo,
    },
  ];

  const structured = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'Service',
        '@id': `${pageUrl}#soin`,
        name: service.name,
        ...(service.description ? { description: service.description } : {}),
        serviceType: service.category.name,
        url: pageUrl,
        provider: { '@id': organizationId() },
        areaServed: { '@type': 'City', name: 'Nador' },
        offers: {
          '@type': 'Offer',
          price: dirhams(service.price.amount),
          priceCurrency: 'MAD',
          description: t.servicePriceNote,
          ...(isHome ? { url: absoluteUrl(`/${locale}/reserver/${service.slug}`) } : {}),
        },
      },
      {
        '@type': 'BreadcrumbList',
        itemListElement: [
          { '@type': 'ListItem', position: 1, name: t.homeCatalogue, item: absoluteUrl(`/${locale}/soins`) },
          {
            '@type': 'ListItem',
            position: 2,
            name: service.category.name,
            item: absoluteUrl(`/${locale}/soins#${service.category.slug}`),
          },
          { '@type': 'ListItem', position: 3, name: service.name, item: pageUrl },
        ],
      },
    ],
  };

  return (
    <section className="section">
      <JsonLd data={structured} />
      <div className="container detail-grid">
        <div className="stack" style={{ ['--gap' as string]: '1.25rem' }}>
          <nav className="breadcrumb" aria-label={t.breadcrumbLabel}>
            <Link href={`/${locale}/soins`}>{t.homeCatalogue}</Link>
            <span aria-hidden="true">/</span>
            <Link href={`/${locale}/soins#${service.category.slug}`}>{service.category.name}</Link>
          </nav>

          <div className="detail-title">
            <span className="icon-tile icon-tile-large">
              <CategoryIcon slug={service.category.slug} size={32} />
            </span>
            <h1>{service.name}</h1>
          </div>

          {service.description && <p className="lead">{service.description}</p>}

          {/* L'essentiel en une phrase : un résumé qui se cite seul, en tête de page. */}
          {isHome && (
            <p className="service-summary">
              {fill(t.serviceSummary, {
                service: service.name,
                minutes: service.duration_minutes,
                price: isolateLtr(price),
              })}
            </p>
          )}

          {service.professional_category && (
            <p>{fill(t.serviceProvidedBy, { profession: service.professional_category })}</p>
          )}

          {service.requires_prescription && (
            <div className="notice notice-warning" role="note">
              <WarningIcon />
              <p>
                {t.servicePrescriptionRequired}. {t.servicePrescriptionHelp}
              </p>
            </div>
          )}
        </div>

        <aside className="card booking-card stack">
          <dl className="facts">
            <dt>
              <ClockIcon size={20} />
              {t.serviceDurationLabel}
            </dt>
            <dd className="ltr">{fill(t.serviceDuration, { minutes: service.duration_minutes })}</dd>
            <dt>
              <CashIcon size={20} />
              {t.servicePriceLabel}
            </dt>
            <dd className="ltr price">{price}</dd>
          </dl>
          <p className="muted small">{t.servicePriceNote}</p>
          {service.delivery_mode === 'remote' ? (
            // Une téléconsultation passe par l'appel vidéo de l'application : pas de réservation sur le site.
            <div className="notice" role="note">
              <InfoIcon />
              <p>
                {t.teleconsultationServiceNote} {t.remoteInApp}
              </p>
            </div>
          ) : (
            <Link className="button button-primary button-block button-large" href={`/${locale}/reserver/${service.slug}`}>
              {t.bookService}
            </Link>
          )}
        </aside>
      </div>

      {/* Téléphone : le prix et l'action restent à portée de pouce, en bas de l'écran. */}
      {isHome && (
        <div className="mobile-book-bar">
          <p>
            <span className="muted small">{t.servicePriceLabel}</span>
            <strong className="ltr">{price}</strong>
          </p>
          <Link className="button button-primary" href={`/${locale}/reserver/${service.slug}`}>
            {t.bookService}
          </Link>
        </div>
      )}

      {/* Questions ouvertes à la lecture, sans volet à déplier : le texte est dans la page. */}
      <div className="container service-faq stack" style={{ ['--gap' as string]: '1rem' }}>
        <h2>{t.serviceFaqTitle}</h2>
        <div className="service-faq-list">
          {questions.map((item) => (
            <div key={item.question} className="service-faq-item">
              <h3>{item.question}</h3>
              <p>{item.answer}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
