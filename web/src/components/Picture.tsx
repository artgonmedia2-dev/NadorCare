/**
 * Photo du site, en deux tailles WebP (640 et 1200 px) dans `public/images`.
 *
 * Les photos sont des illustrations générées, sans personne réelle. Elles sont décoratives :
 * le texte voisin porte l'information, d'où le texte alternatif vide.
 */
export function Picture({
  name,
  sizes,
  priority = false,
  className,
}: {
  name: string;
  /** Largeur occupée selon l'écran, pour que le navigateur choisisse la bonne taille. */
  sizes: string;
  /** Vrai pour l'image visible dès l'ouverture de la page. */
  priority?: boolean;
  className?: string;
}) {
  return (
    <img
      className={className}
      src={`/images/${name}-1200.webp`}
      srcSet={`/images/${name}-640.webp 640w, /images/${name}-1200.webp 1200w`}
      sizes={sizes}
      // Dimensions déclarées : la place est réservée, la page ne saute pas au chargement.
      width={1200}
      height={900}
      alt=""
      loading={priority ? 'eager' : 'lazy'}
      fetchPriority={priority ? 'high' : 'auto'}
      decoding="async"
    />
  );
}

/** Catégories de soins qui ont une photo. */
export const categoryPictures = new Set([
  'soins-infirmiers',
  'pansements-et-plaies',
  'sondes',
  'sage-femme',
  'kinesitherapie',
  'hygiene-et-confort',
]);
