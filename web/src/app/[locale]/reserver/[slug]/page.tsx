import type { Metadata } from 'next';
import { notFound, redirect } from 'next/navigation';

import { BookingWizard } from '@/components/BookingWizard';
import { CategoryIcon } from '@/components/icons';
import { isLocale } from '@/i18n/config';
import { fill, getDictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import { fetchPublic } from '@/lib/server-api';
import type { CareService, Surcharge } from '@/lib/types';

type Props = { params: Promise<{ locale: string; slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  // Le parcours de réservation n'a pas à être référencé.
  return isLocale(locale) ? { title: getDictionary(locale).bookService, robots: { index: false } } : {};
}

/** Réservation d'un soin : connexion par code, puis le même parcours que l'application. */
export default async function BookingPage({ params }: Props) {
  const { locale, slug } = await params;
  if (!isLocale(locale)) {
    notFound();
  }
  const t = getDictionary(locale);
  const [service, surcharges] = await Promise.all([
    fetchPublic<CareService>(`/catalogue/services/${encodeURIComponent(slug)}`, locale),
    fetchPublic<Surcharge[]>('/catalogue/surcharges', locale),
  ]);
  // Majoration du soir, annoncée sur les créneaux concernés.
  const evening = surcharges?.find((surcharge) => surcharge.type === 'night') ?? null;
  if (!service) {
    notFound();
  }
  // Une téléconsultation ne se réserve pas sur le site : retour à sa fiche, qui l'explique.
  if (service.delivery_mode === 'remote') {
    redirect(`/${locale}/soins/${service.slug}`);
  }

  return (
    <section className="section">
      <div className="container booking-grid">
        <div className="card wizard-card">
          <BookingWizard locale={locale} t={t} service={service} evening={evening} />
        </div>

        {/* Rappel du soin choisi, visible pendant tout le parcours. */}
        <aside className="card order-card" aria-labelledby="titre-commande">
          <p id="titre-commande" className="eyebrow">
            {t.orderTitle}
          </p>
          <div className="order-service">
            <span className="icon-tile">
              <CategoryIcon slug={service.category.slug} />
            </span>
            <p className="order-name">{service.name}</p>
          </div>
          <dl className="facts">
            <dt>{t.serviceDurationLabel}</dt>
            <dd className="ltr">{fill(t.serviceDuration, { minutes: service.duration_minutes })}</dd>
            <dt>{t.servicePriceLabel}</dt>
            <dd className="ltr">{formatDirhams(service.price.amount, locale, t.currencyUnit)}</dd>
          </dl>
          <p className="muted small">{t.servicePriceNote}</p>
        </aside>
      </div>
    </section>
  );
}
