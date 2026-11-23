import type { Metadata } from 'next';
import { notFound } from 'next/navigation';

import { InfoIcon } from '@/components/icons';
import { ServiceCard } from '@/components/ServiceCard';
import { isLocale } from '@/i18n/config';
import { getDictionary } from '@/i18n/dictionary';
import { fetchPublic } from '@/lib/server-api';
import type { CareCategory, CareService } from '@/lib/types';

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return isLocale(locale) ? { title: getDictionary(locale).homeCatalogue } : {};
}

/** Tous les soins, regroupés par catégorie. */
export default async function ServicesPage({ params }: Props) {
  const { locale } = await params;
  if (!isLocale(locale)) {
    notFound();
  }
  const t = getDictionary(locale);

  const [categories, services] = await Promise.all([
    fetchPublic<CareCategory[]>('/catalogue/categories', locale),
    fetchPublic<CareService[]>('/catalogue/services', locale),
  ]);

  const groups =
    categories === null || services === null
      ? null
      : categories
          .map((category) => ({
            category,
            items: services.filter((service) => service.category.slug === category.slug),
          }))
          .filter((group) => group.items.length > 0);

  return (
    <>
      <section className="page-head">
        <div className="container stack" style={{ ['--gap' as string]: '1rem' }}>
          <h1>{t.homeCatalogue}</h1>
          <p className="lead">{t.homePatientIntro}</p>
          {groups !== null && groups.length > 1 && (
            <nav className="chips" aria-label={t.categoriesNav}>
              {groups.map(({ category }) => (
                <a key={category.slug} className="chip" href={`#${category.slug}`}>
                  {category.name}
                </a>
              ))}
            </nav>
          )}
        </div>
      </section>

      <section className="section">
        <div className="container stack" style={{ ['--gap' as string]: '2.5rem' }}>
          {groups === null ? (
            <div className="notice notice-error" role="alert">
              <InfoIcon />
              <p>{t.apiDown}</p>
            </div>
          ) : groups.length === 0 ? (
            <p className="muted">{t.catalogueEmpty}</p>
          ) : (
            groups.map(({ category, items }) => (
              <section
                key={category.slug}
                id={category.slug}
                className="stack anchor-target"
                aria-labelledby={`categorie-${category.slug}`}
              >
                <h2 id={`categorie-${category.slug}`}>{category.name}</h2>
                <div className="grid">
                  {items.map((service) => (
                    <ServiceCard key={service.slug} service={service} locale={locale} t={t} />
                  ))}
                </div>
              </section>
            ))
          )}
        </div>
      </section>
    </>
  );
}
