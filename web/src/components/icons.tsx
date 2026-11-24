import type { ReactNode } from 'react';

/** Icônes en SVG, toutes au même format (24 × 24, trait de 2). Décoratives : le texte porte le sens. */
function Icon({ children, size = 24, className }: { children: ReactNode; size?: number; className?: string }) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {children}
    </svg>
  );
}

type Sized = { size?: number };

export function WarningIcon() {
  return (
    <Icon>
      <path d="M12 3 2 20h20L12 3z" />
      <path d="M12 10v4M12 17h.01" />
    </Icon>
  );
}

export function InfoIcon() {
  return (
    <Icon>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 11v5M12 8h.01" />
    </Icon>
  );
}

export function CheckIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <path d="m5 12 5 5 9-10" />
    </Icon>
  );
}

export function DocumentIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <path d="M7 3h7l4 4v14H7z" />
      <path d="M10 12h5M10 16h5" />
    </Icon>
  );
}

export function PhoneIcon() {
  return (
    <Icon size={20}>
      <path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z" />
    </Icon>
  );
}

export function ChatIcon() {
  return (
    <Icon size={20}>
      <path d="M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12z" />
    </Icon>
  );
}

/** Flèche « suivant » : la classe `icon-forward` la retourne quand la page se lit de droite à gauche. */
export function ArrowIcon({ size = 20 }: Sized) {
  return (
    <Icon size={size} className="icon-forward">
      <path d="M5 12h14M13 6l6 6-6 6" />
    </Icon>
  );
}

export function ShieldIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <path d="M12 3 4 6v6c0 5 3.4 8 8 9 4.6-1 8-4 8-9V6l-8-3z" />
      <path d="m9 12 2 2 4-4" />
    </Icon>
  );
}

export function LockIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <rect x="5" y="11" width="14" height="10" rx="2" />
      <path d="M8 11V8a4 4 0 0 1 8 0v3" />
    </Icon>
  );
}

export function CashIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <rect x="3" y="6" width="18" height="12" rx="2" />
      <circle cx="12" cy="12" r="2.5" />
      <path d="M7 9v.01M17 15v.01" />
    </Icon>
  );
}

export function ClockIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3 2" />
    </Icon>
  );
}

/** Trousse de soins : icône des soins et des catégories. */
export function CareIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <rect x="3" y="7" width="18" height="13" rx="2" />
      <path d="M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2M12 11v5M9.5 13.5h5" />
    </Icon>
  );
}

/**
 * Icône d'une catégorie de soins, d'après son identifiant (catalogue du client, 2026-11-23) :
 * la même idée que dans les applications, une icône par métier plutôt qu'une trousse partout.
 */
export function CategoryIcon({ slug, size }: Sized & { slug: string }) {
  switch (slug) {
    case 'medecine-a-domicile':
      // Stéthoscope.
      return (
        <Icon size={size}>
          <path d="M5 3H4a1 1 0 0 0-1 1v5a5 5 0 0 0 10 0V4a1 1 0 0 0-1-1h-1" />
          <path d="M8 14v1a5 5 0 0 0 10 0v-2" />
          <circle cx="18" cy="11" r="2" />
        </Icon>
      );
    case 'teleconsultation':
      return (
        <Icon size={size}>
          <rect x="2" y="6" width="14" height="12" rx="2" />
          <path d="m16 10 6-3v10l-6-3" />
        </Icon>
      );
    case 'soins-infirmiers':
      // Seringue.
      return (
        <Icon size={size}>
          <path d="m18 2 4 4M17 7l3-3M19 9 8.7 19.3a2.4 2.4 0 0 1-3.4 0l-.6-.6a2.4 2.4 0 0 1 0-3.4L15 5" />
          <path d="m9 11 4 4M5 19l-3 3M14 4l6 6" />
        </Icon>
      );
    case 'pansements-et-plaies':
      // Pansement.
      return (
        <Icon size={size}>
          <path d="M10.1 3.9 3.9 10.1a2.8 2.8 0 0 0 0 4l6 6a2.8 2.8 0 0 0 4 0l6.2-6.2a2.8 2.8 0 0 0 0-4l-6-6a2.8 2.8 0 0 0-4 0Z" />
          <path d="M10 12h.01M12 10h.01M12 14h.01M14 12h.01" />
        </Icon>
      );
    case 'sondes':
      // Goutte.
      return (
        <Icon size={size}>
          <path d="M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5S12.5 5.5 12 3c-.5 2.5-2 4.9-4 6.5S5 13 5 15a7 7 0 0 0 7 7Z" />
        </Icon>
      );
    case 'sage-femme':
      // Visage de nouveau-né.
      return (
        <Icon size={size}>
          <circle cx="12" cy="12" r="9" />
          <path d="M9 11h.01M15 11h.01M10 15.5c.6.4 1.2.5 2 .5s1.4-.1 2-.5M12 3c-1 1.5-1 3 .5 3.5" />
        </Icon>
      );
    case 'kinesitherapie':
      // Personne en mouvement.
      return (
        <Icon size={size}>
          <circle cx="12" cy="4.5" r="2" />
          <path d="M4 9.5 9 9l3 2 3-2 5 .5M12 11v4l-3 6M12 15l3 6" />
        </Icon>
      );
    case 'hygiene-et-confort':
      // Pommeau de douche.
      return (
        <Icon size={size}>
          <path d="m4 4 2.5 2.5M13.5 6.5a4.95 4.95 0 0 0-7 7M15 5 5 15" />
          <path d="M14 17v.01M10 16v.01M13 13v.01M16 10v.01M11 20v.01M17 14v.01M20 11v.01" />
        </Icon>
      );
    default:
      return <CareIcon size={size} />;
  }
}

export function PinIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
      <circle cx="12" cy="10" r="3" />
    </Icon>
  );
}

export function SearchIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <circle cx="11" cy="11" r="8" />
      <path d="m21 21-4.3-4.3" />
    </Icon>
  );
}

export function CalendarIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <rect x="3" y="4" width="18" height="17" rx="2" />
      <path d="M3 9h18M8 2v4M16 2v4" />
    </Icon>
  );
}

export function BoltIcon({ size }: Sized) {
  return (
    <Icon size={size}>
      <path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z" />
    </Icon>
  );
}

export function BrandMark({ size = 32 }: Sized) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" aria-hidden="true" focusable="false">
      {/* Symbole Nador Care (piste C « Maison-pouls ») : un toit au-dessus d'un tracé de pouls. Source : docs/marque. */}
      <rect width="32" height="32" rx="7.5" fill="var(--primary)" />
      <path d="M6.5 15 16 7.25 25.5 15" fill="none" stroke="#fff" strokeWidth="2.75" strokeLinecap="round" strokeLinejoin="round" />
      <path
        d="M6.5 21h4.75l1.85-3.25 2.4 7 2.4-11 1.85 7.25h5.75"
        fill="none"
        stroke="#fff"
        strokeWidth="2.75"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
