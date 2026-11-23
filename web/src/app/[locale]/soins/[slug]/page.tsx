import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';

import { ArrowIcon, CareIcon, CashIcon, ClockIcon, InfoIcon, WarningIcon } from '@/components/icons';
import { isLocale } from '@/i18n/config';
import { fill, getDictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import { fetchPublic } from '@/lib/server-api';
import type { CareService } from '@/lib/types';

type Props = { params: Promise<{ locale: string; slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale, slug } = await params;
  if (!isLocale(locale)) {
    return {};
  }
  const service = await fetchPublic<CareService>(`/catalogue/services/${encodeURIComponent(slug)}`, locale);
  return service ? { title: service.name, description: service.description ?? undefined } : {};
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

  return (
    <section className="section">
      <div className="container detail-grid">
        <div className="stack" style={{ ['--gap' as string]: '1.25rem' }}>
          <nav className="breadcrumb" aria-label={t.breadcrumbLabel}>
            <Link href={`/${locale}/soins`}>{t.homeCatalogue}</Link>
            <span aria-hidden="true">/</span>
            <Link href={`/${locale}/soins#${service.category.slug}`}>{service.category.name}</Link>
          </nav>

          <div className="detail-title">
            <span className="icon-tile icon-tile-large">
              <CareIcon size={32} />
            </span>
            <h1>{service.name}</h1>
          </div>

          {service.description && <p className="lead">{service.description}</p>}

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
            <dd className="ltr price">{formatDirhams(service.price.amount, locale, t.currencyUnit)}</dd>
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
              <ArrowIcon />
            </Link>
          )}
        </aside>
      </div>
    </section>
  );
}
