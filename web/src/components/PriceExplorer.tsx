'use client';

import Link from 'next/link';
import { useId, useMemo, useState } from 'react';

import type { Locale } from '@/i18n/config';
import { fill, isolateLtr, type Dictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import type { CareCategory, CareService, Surcharge } from '@/lib/types';

import { ClockIcon, DocumentIcon, InfoIcon } from './icons';

/** Ignore la casse et les accents, pour que « kine » trouve « Kinésithérapie ». */
function normalize(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();
}

type Props = {
  locale: Locale;
  t: Dictionary;
  categories: CareCategory[];
  services: CareService[];
  /** Majoration du soir, si elle est active. */
  evening: Surcharge | null;
};

/** Grille des tarifs : recherche, filtre par catégorie, tarif de jour ou du soir. */
export function PriceExplorer({ locale, t, categories, services, evening }: Props) {
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState<string | null>(null);
  const [isEvening, setIsEvening] = useState(false);
  const searchId = useId();

  const visible = useMemo(() => {
    const needle = normalize(query.trim());
    // Les soins d'une même catégorie restent ensemble, dans l'ordre des catégories.
    const rank = new Map(categories.map((item, index) => [item.slug, index]));
    return services
      .filter(
        (service) =>
          (category === null || service.category.slug === category) &&
          (needle.length < 2 ||
            normalize(`${service.name} ${service.description ?? ''} ${service.category.name}`).includes(needle)),
      )
      .sort((a, b) => (rank.get(a.category.slug) ?? 99) - (rank.get(b.category.slug) ?? 99));
  }, [services, categories, query, category]);

  const priceOf = (service: CareService): number => {
    // Une téléconsultation a un tarif fixe : aucune majoration ne s'y applique (règle de l'API).
    if (!isEvening || !evening || service.delivery_mode === 'remote') {
      return service.price.amount;
    }
    return (
      service.price.amount +
      (evening.mode === 'percent' ? Math.round((service.price.amount * evening.value) / 100) : evening.value)
    );
  };

  const money = (centimes: number) => formatDirhams(centimes, locale, t.currencyUnit);

  return (
    <div className="stack" style={{ ['--gap' as string]: '1.25rem' }}>
      <div className="explorer-controls">
        <div className="field explorer-search">
          <label htmlFor={searchId}>{t.priceSearchLabel}</label>
          <input
            id={searchId}
            type="search"
            inputMode="search"
            placeholder={t.priceSearchHint}
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>

        {evening && (
          <fieldset className="segmented">
            <legend className="legend">{t.priceTimeLabel}</legend>
            <div className="segmented-options">
              <label>
                <input type="radio" name="moment" checked={!isEvening} onChange={() => setIsEvening(false)} />
                <span>{t.priceDay}</span>
              </label>
              <label>
                <input type="radio" name="moment" checked={isEvening} onChange={() => setIsEvening(true)} />
                <span>{t.priceEvening}</span>
              </label>
            </div>
          </fieldset>
        )}
      </div>

      <div className="chips" role="group" aria-label={t.categoriesNav}>
        <button type="button" className="chip" aria-pressed={category === null} onClick={() => setCategory(null)}>
          {t.allCategories}
        </button>
        {categories.map((item) => (
          <button
            key={item.slug}
            type="button"
            className="chip"
            aria-pressed={category === item.slug}
            onClick={() => setCategory(item.slug)}
          >
            {item.name}
          </button>
        ))}
      </div>

      {evening && evening.starts_at && evening.ends_at && (
        <div className="notice" role="note">
          <InfoIcon />
          <p>
            {fill(t.eveningNote, {
              start: isolateLtr(evening.starts_at),
              end: isolateLtr(evening.ends_at),
              amount: isolateLtr(evening.mode === 'percent' ? `${evening.value} %` : money(evening.value)),
            })}
          </p>
        </div>
      )}

      {/* Annoncé aux lecteurs d'écran à chaque changement de filtre. */}
      <p className="muted small" role="status" aria-live="polite">
        {fill(t.resultsCount, { count: visible.length })}
      </p>

      {visible.length === 0 ? (
        <p className="empty">{fill(t.catalogueNoResult, { query: query.trim() })}</p>
      ) : (
        <ul className="price-list">
          {visible.map((service) => (
            <li key={service.slug} className="price-row">
              <div className="price-row-main">
                <Link className="price-row-name" href={`/${locale}/soins/${service.slug}`}>
                  {service.name}
                </Link>
                <p className="price-row-meta">
                  <span>{service.category.name}</span>
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
                </p>
              </div>
              <p className="price-row-amount ltr">{money(priceOf(service))}</p>
              <Link className="button button-text" href={`/${locale}/reserver/${service.slug}`}>
                {t.bookShort}
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
