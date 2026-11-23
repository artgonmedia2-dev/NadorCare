import Link from 'next/link';

import type { Locale } from '@/i18n/config';
import { fill, type Dictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import type { CareService } from '@/lib/types';

import { ArrowIcon, CareIcon, ClockIcon, DocumentIcon } from './icons';

/** Carte d'un soin : nom, durée, tarif indicatif, ordonnance si elle est exigée. */
export function ServiceCard({ service, locale, t }: { service: CareService; locale: Locale; t: Dictionary }) {
  return (
    <Link className="card card-link service-card" href={`/${locale}/soins/${service.slug}`}>
      <span className="icon-tile">
        <CareIcon />
      </span>
      <span className="service-body">
        <h3>{service.name}</h3>
        <span className="service-meta">
          <ClockIcon size={18} />
          <span className="ltr">{fill(t.serviceDuration, { minutes: service.duration_minutes })}</span>
        </span>
        {service.requires_prescription && (
          <span className="badge">
            <DocumentIcon size={18} />
            {t.servicePrescriptionRequired}
          </span>
        )}
      </span>
      <span className="service-price">
        <span className="ltr">{formatDirhams(service.price.amount, locale, t.currencyUnit)}</span>
        <ArrowIcon />
      </span>
    </Link>
  );
}
