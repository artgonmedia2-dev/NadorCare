# Site public Nador Care

Site Next.js (lot 7 du découpage) : présentation de l'offre et réservation en ligne, en français, arabe (droite à gauche) et anglais.

## État

Livré le 2026-11-23, à titre de première version :

- socle (7.0, en partie) : Next.js 16, TypeScript, trois langues par préfixe d'adresse (`/fr`, `/ar`, `/en`) ;
- accueil, liste des soins, fiche d'un soin, page des tarifs avec recherche, filtre par catégorie et tarif de jour ou du soir, garde-malade, questions fréquentes (une partie de 7.1) ;
- réservation en ligne avec code par SMS (7.2), même parcours que l'application patient.

Pas encore faits : zones couvertes, tarifs, FAQ, à propos, contact, recrutement, blog, pages légales, référencement (données structurées, plan du site), suivi et annulation d'une réservation depuis le site, types générés depuis `docs/openapi.json`, tests automatisés, intégration continue.

## Lancer

L'API doit tourner (`php artisan serve` dans `/api`).

```powershell
pnpm install
Copy-Item .env.example .env.local
pnpm dev          # http://localhost:3000
pnpm build; pnpm start
pnpm typecheck
pnpm texts        # après toute modification d'un texte (voir plus bas)
```

En développement, le code de connexion est dans `api\storage\logs\laravel.log`, ligne « [SMS factice] ».

## Organisation

- `src/app/[locale]` : les pages. Le catalogue est lu côté serveur, pour le référencement.
- `src/app/api` : relais vers l'API Laravel. Le navigateur ne parle jamais à l'API directement.
- `src/components/BookingWizard.tsx` : le parcours de réservation.
- `src/i18n` : langues et textes.

## Règles

- **Jeton** : il vit dans un cookie `httpOnly` posé par `/api/auth/otp/verify`. Il n'est jamais envoyé à la page ni rangé dans le stockage du navigateur.
- **Relais** : `/api/account/...` n'ouvre que les ressources de la liste `ALLOWED`. Toute nouvelle ressource s'y ajoute explicitement. Les appels portent l'en-tête `x-nadorcare-site`, qu'un site tiers ne peut pas ajouter.
- **Textes** : aucun texte en dur. Les textes communs avec l'application viennent des fichiers ARB de `mobile/packages/nc_l10n` (liste `sharedKeys` de `scripts/sync-texts.mjs`) ; ceux du site sont dans `src/i18n/web-texts.json`, dans les trois langues. `pnpm texts` régénère `src/i18n/generated`, qui est commité.
- **Design** : style « Accessible & Ethical » (contraste élevé, texte de 17 px, cibles tactiles de 44 px et plus, focus visible). Couleurs et rayons en variables dans `src/app/globals.css`, sur le vert sarcelle de l'application. Polices Figtree (titres), Noto Sans (texte) et Noto Sans Arabic, téléchargées à la compilation par `next/font` puis servies par le site. La marque dans l'en-tête est provisoire, en attendant le logo.
- **Mise en page de l'accueil** (src/app/home.css) : inspirée, pour sa structure seulement, d'un site de maison de soins indiqué par le client le 2026-11-23 — bandeau supérieur, accroche avec carte flottante, bande d'atouts, bloc « à propos » avec photo, carrousel de soins avec prix, chiffres, questions avec photo, pied de page sombre à colonnes. Ni ses textes ni ses images ne sont repris.
- **Pas de témoignage ni de chiffre inventé** : la section « Pourquoi choisir Nador Care » ne cite que des engagements réels du service.
- **Photos** : `public/images`, en WebP à 640 et 1200 px, affichées par `components/Picture.tsx`. Ce sont des illustrations générées avec Higgsfield (modèle `z_image`) le 2026-11-23, sans personne réelle ; à remplacer par de vraies photos quand il y en aura.
- **Prix** : lus dans l'API, jamais recopiés. La majoration du soir vient de `/catalogue/surcharges`. Seule exception, provisoire : la garde-malade, dans `src/content/home-guard.ts` (question 26 de `docs/03-questions-ouvertes.md`).
- **Sens de lecture** : marges et alignements en propriétés logiques (`margin-inline`, `inset-inline-start`). Numéros, codes, heures et montants portent la classe `ltr`.
- **Heures** : celles de Nador, telles que le serveur les envoie, sans conversion vers le fuseau du visiteur.
- **Coordonnées** : le bouton WhatsApp et le numéro d'appel s'affichent quand `NEXT_PUBLIC_WHATSAPP_NUMBER` et `NEXT_PUBLIC_CONTACT_PHONE` sont renseignés.
- **Position d'une adresse** : l'API l'exige ; le site la demande au navigateur (HTTPS obligatoire hors `localhost`).
