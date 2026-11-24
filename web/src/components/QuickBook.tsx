'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

import type { Locale } from '@/i18n/config';
import type { Dictionary } from '@/i18n/dictionary';

export type QuickBookGroup = { category: string; services: { slug: string; name: string; price: string }[] };

/**
 * Choix du soin, dans l'accroche (seconde refonte du 2026-11-24) : un vrai champ et un bouton.
 * L'adresse et le créneau se choisissent dans le parcours de réservation ; ils ne sont plus
 * imités ici par des cases qui n'en sont pas. Sans choix, le bouton mène à la liste des soins.
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
      <div className="quickbook-field">
        <label htmlFor="quickbook-care">{t.quickCareLabel}</label>
        <select id="quickbook-care" value={slug} onChange={(event) => setSlug(event.target.value)}>
          <option value="">{t.quickCarePlaceholder}</option>
          {groups.map((group) => (
            <optgroup key={group.category} label={group.category}>
              {group.services.map((service) => (
                <option key={service.slug} value={service.slug}>
                  {service.name} — {service.price}
                </option>
              ))}
            </optgroup>
          ))}
        </select>
      </div>
      <button type="submit" className="button button-primary">
        {t.quickGo}
      </button>
    </form>
  );
}
