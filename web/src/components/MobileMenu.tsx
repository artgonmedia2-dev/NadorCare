'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';

import type { Locale } from '@/i18n/config';

import { ArrowIcon, PhoneIcon } from './icons';
import { LanguageSwitch } from './LanguageSwitch';

type Props = {
  locale: Locale;
  links: { href: string; label: string }[];
  /** Numéro affiché et composé ; absent tant qu'il n'est pas fixé dans l'environnement. */
  phone?: string;
  texts: { open: string; close: string; nav: string; language: string };
};

/**
 * Menu du téléphone (en dessous de 900 px) : un bouton dans l'en-tête ouvre, sous lui, un panneau
 * avec les liens, le téléphone et la langue. Il se ferme avec Échap, en touchant le fond ou en
 * changeant de page ; la page ne défile pas tant qu'il est ouvert.
 */
export function MobileMenu({ locale, links, phone, texts }: Props) {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();
  const toggle = useRef<HTMLButtonElement>(null);
  const firstLink = useRef<HTMLAnchorElement>(null);

  // Une nouvelle page referme le menu.
  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  useEffect(() => {
    document.documentElement.classList.toggle('menu-open', open);
    if (!open) {
      return;
    }
    firstLink.current?.focus();

    function onKey(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setOpen(false);
        toggle.current?.focus();
      }
    }
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.documentElement.classList.remove('menu-open');
    };
  }, [open]);

  return (
    <>
      <button
        ref={toggle}
        type="button"
        className="menu-toggle"
        aria-expanded={open}
        aria-controls="menu-mobile"
        aria-label={open ? texts.close : texts.open}
        onClick={() => setOpen((value) => !value)}
      >
        <span className="menu-toggle-lines" aria-hidden="true">
          <span />
          <span />
          <span />
        </span>
      </button>

      <div className="menu-backdrop" hidden={!open} onClick={() => setOpen(false)} aria-hidden="true" />

      <div id="menu-mobile" className="mobile-menu" hidden={!open}>
        <nav aria-label={texts.nav}>
          <ul>
            {links.map((link, index) => (
              <li key={link.href}>
                <Link ref={index === 0 ? firstLink : undefined} className="mobile-menu-link" href={link.href}>
                  {link.label}
                  <ArrowIcon size={20} />
                </Link>
              </li>
            ))}
            {phone && (
              <li>
                <a className="mobile-menu-link ltr" href={`tel:${phone}`}>
                  {phone}
                  <PhoneIcon />
                </a>
              </li>
            )}
          </ul>
        </nav>
        <LanguageSwitch current={locale} label={texts.language} />
      </div>
    </>
  );
}
