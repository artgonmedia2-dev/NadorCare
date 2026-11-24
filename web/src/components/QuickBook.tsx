'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

import { ArrowIcon, CalendarIcon, PinIcon, SearchIcon } from '@/components/icons';
import type { Locale } from '@/i18n/config';
import type { Dictionary } from '@/i18n/dictionary';

export type QuickBookGroup = { category: string; services: { slug: string; name: string; price: string }[] };

/**
 * Barre de réservation rapide de l'accueil (refonte du 2026-11-24) : on choisit le soin, et l'on
 * arrive directement au parcours de réservation. L'adresse et le créneau se choisissent ensuite :
 * ils sont rappelés ici à titre d'information, sans faux champ.
 */
export function QuickBook({ locale, t, groups }: { locale: Locale; t: Dictionary; groups: QuickBookGroup[] }) {
  const router = useRouter();
  const [slug, setSlug] = useState('');

  return (
    <form
      className="quickbook"
      aria-label={t.quickTitle}
      onSubmit={(event) => {
        event.preventDefault();
        router.push(slug ? `/${locale}/reserver/${slug}` : `/${locale}/soins`);
      }}
    >
      <label className="quickbook-field quickbook-care" htmlFor="quickbook-care">
        <SearchIcon size={22} />
        <span className="quickbook-text">
          <span className="quickbook-label">{t.quickCareLabel}</span>
          <select id="quickbook-care" value={slug} onChange={(event) => setSlug(event.target.value)}>
            <option value="">{t.quickCarePlaceholder}</option>
            {groups.map((group) => (
              <optgroup key={group.category} label={group.category}>
                {group.services.map((service) => (
                  <option key={service.slug} value={service.slug}>
                    {service.name} · {service.price}
                  </option>
                ))}
              </optgroup>
            ))}
          </select>
        </span>
      </label>
      <div className="quickbook-field">
        <PinIcon size={22} />
        <span className="quickbook-text">
          <span className="quickbook-label">{t.quickAreaLabel}</span>
          <span>{t.quickAreaValue}</span>
        </span>
      </div>
      <div className="quickbook-field">
        <CalendarIcon size={22} />
        <span className="quickbook-text">
          <span className="quickbook-label">{t.quickWhenLabel}</span>
          <span>{t.quickWhenValue}</span>
        </span>
      </div>
      <button type="submit" className="button button-primary button-large">
        {t.quickGo}
        <ArrowIcon />
      </button>
    </form>
  );
}
