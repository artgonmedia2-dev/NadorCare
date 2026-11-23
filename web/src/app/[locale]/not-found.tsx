import Link from 'next/link';

import { defaultLocale } from '@/i18n/config';
import { getDictionary } from '@/i18n/dictionary';

/** Page introuvable. La langue de l'adresse n'est pas connue ici : on répond en français. */
export default function NotFound() {
  const t = getDictionary(defaultLocale);

  return (
    <section className="section">
      <div className="container narrow stack">
        <h1>{t.notFoundTitle}</h1>
        <p className="muted">{t.notFoundBody}</p>
        <p>
          <Link className="button button-primary" href={`/${defaultLocale}`}>
            {t.navHome}
          </Link>
        </p>
      </div>
    </section>
  );
}
