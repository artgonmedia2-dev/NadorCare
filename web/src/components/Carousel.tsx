'use client';

import { useRef, type ReactNode } from 'react';

import { ArrowIcon } from './icons';

/**
 * Bande de cartes qui défile à l'horizontale : au doigt sur téléphone, avec les deux boutons
 * ou le clavier sur ordinateur. Le défilement est natif (`scroll-snap`), sans bibliothèque.
 */
export function Carousel({
  children,
  label,
  previousLabel,
  nextLabel,
}: {
  children: ReactNode;
  /** Nom de la bande, pour les lecteurs d'écran. */
  label: string;
  previousLabel: string;
  nextLabel: string;
}) {
  const track = useRef<HTMLUListElement>(null);

  function move(forward: boolean) {
    const element = track.current;
    if (!element) {
      return;
    }
    // En arabe, « suivant » va vers la gauche : le sens de défilement s'inverse.
    const rtl = getComputedStyle(element).direction === 'rtl';
    const step = element.clientWidth * 0.85 * (forward ? 1 : -1) * (rtl ? -1 : 1);
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    element.scrollBy({ left: step, behavior: reduced ? 'auto' : 'smooth' });
  }

  return (
    <div className="carousel">
      <div className="carousel-controls">
        <button type="button" className="round-button" aria-label={previousLabel} onClick={() => move(false)}>
          <span className="icon-back">
            <ArrowIcon />
          </span>
        </button>
        <button type="button" className="round-button" aria-label={nextLabel} onClick={() => move(true)}>
          <ArrowIcon />
        </button>
      </div>
      <ul ref={track} className="carousel-track" aria-label={label} tabIndex={0}>
        {children}
      </ul>
    </div>
  );
}
