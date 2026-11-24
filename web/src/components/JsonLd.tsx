/**
 * Données structurées schema.org, rendues côté serveur dans le HTML : lisibles par les moteurs
 * qui n'exécutent pas JavaScript. Les `<` sont échappés pour qu'un texte ne puisse pas fermer
 * la balise.
 */
export function JsonLd({ data }: { data: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, '\\u003c') }}
    />
  );
}
