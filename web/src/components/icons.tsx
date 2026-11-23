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

/** Marque provisoire, en attendant le logo : une maison et une croix de soin. */
export function BrandMark({ size = 32 }: Sized) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" aria-hidden="true" focusable="false">
      <rect width="32" height="32" rx="9" fill="var(--primary)" />
      <path d="M7 16 16 8l9 8v8a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1z" fill="none" stroke="#fff" strokeWidth="2" strokeLinejoin="round" />
      <path d="M16 15v6M13 18h6" stroke="#fff" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}
