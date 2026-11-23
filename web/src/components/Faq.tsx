import type { Locale } from '@/i18n/config';
import { fill, isolateLtr, type Dictionary } from '@/i18n/dictionary';
import { formatDirhams } from '@/lib/format';
import type { Surcharge } from '@/lib/types';

/**
 * Questions fréquentes, en volets natifs (`details`) : ils s'ouvrent au clavier comme au doigt
 * et fonctionnent sans JavaScript.
 */
export function Faq({ t, locale, evening }: { t: Dictionary; locale: Locale; evening: Surcharge | null }) {
  const items: { question: string; answer: string }[] = [
    { question: t.faq1Q, answer: t.faq1A },
    { question: t.faq2Q, answer: t.faq2A },
    { question: t.faq3Q, answer: t.faq3A },
    { question: t.faq4Q, answer: t.faq4A },
  ];

  // La réponse sur le tarif du soir vient de la majoration réellement active.
  if (evening?.starts_at && evening.ends_at) {
    items.push({
      question: t.faq5Q,
      answer: fill(t.eveningNote, {
        start: isolateLtr(evening.starts_at),
        end: isolateLtr(evening.ends_at),
        amount: isolateLtr(
          evening.mode === 'percent' ? `${evening.value} %` : formatDirhams(evening.value, locale, t.currencyUnit),
        ),
      }),
    });
  }

  return (
    <div className="faq">
      {items.map((item) => (
        <details key={item.question}>
          <summary>{item.question}</summary>
          <p>{item.answer}</p>
        </details>
      ))}
    </div>
  );
}
