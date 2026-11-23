import type { Locale } from '@/i18n/config';

const intlLocale: Record<Locale, string> = { fr: 'fr-MA', ar: 'ar-MA', en: 'en-GB' };

/** Montant en centimes de dirham vers « 80 DH ». Chiffres latins dans les trois langues. */
export function formatDirhams(centimes: number, locale: Locale, unit: string): string {
  const amount = new Intl.NumberFormat(intlLocale[locale], {
    maximumFractionDigits: centimes % 100 === 0 ? 0 : 2,
    numberingSystem: 'latn',
  }).format(centimes / 100);
  return `${amount} ${unit}`;
}

/** Date `AAAA-MM-JJ` en toutes lettres. La date est celle de Nador, sans conversion de fuseau. */
export function longDate(isoDate: string, locale: Locale): string {
  const [year, month, day] = isoDate.slice(0, 10).split('-').map(Number);
  const date = new Date(Date.UTC(year ?? 1970, (month ?? 1) - 1, day ?? 1));
  return new Intl.DateTimeFormat(intlLocale[locale], {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC',
    numberingSystem: 'latn',
  }).format(date);
}

/** Heure d'un créneau : celle que le serveur envoie, à l'heure de Nador. */
export function slotTime(iso: string): string {
  return iso.slice(11, 16);
}

/** Date du jour à Nador, au format `AAAA-MM-JJ`. */
export function todayInNador(offsetDays = 0): string {
  const now = new Date(Date.now() + offsetDays * 86_400_000);
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Africa/Casablanca' }).format(now);
}
