import Link from 'next/link';

import type { Locale } from '@/i18n/config';
import { fill, type Dictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import type { CareService } from '@/lib/types';

import { ArrowIcon, ClockIcon, DocumentIcon } from './icons';

/**
 * Ligne d'un soin dans la liste des soins : nom, durée, ordonnance si elle est exigée, tarif.
 * Toute la ligne mène à la fiche du soin ; la flèche suit le sens de lecture.
 */
export function ServiceRow({ service, locale, t }: { service: CareService; locale: Locale; t: Dictionary }) {
  return (
    <li>
      <Link className="service-row" href={`/${locale}/soins/${service.slug}`}>
        <span className="price-row-main">
          <span className="price-row-name">{service.name}</span>
          <span className="price-row-meta">
            <span className="price-row-duration">
              <ClockIcon size={16} />
              <span className="ltr">{fill(t.serviceDuration, { minutes: service.duration_minutes })}</span>
            </span>
            {service.requires_prescription && (
              <span className="badge">
                <DocumentIcon size={16} />
                {t.servicePrescriptionRequired}
              </span>
            )}
          </span>
        </span>
        <span className="service-row-price">
          <span className="ltr">{formatDirhams(service.price.amount, locale, t.currencyUnit)}</span>
          <ArrowIcon size={18} />
        </span>
      </Link>
    </li>
  );
}
