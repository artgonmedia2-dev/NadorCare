# Référencement et moteurs de réponse (GEO) — site public

Analyse du 2026-11-24, sur le code du site (`/web`, Next.js 16). Le site n'est pas encore en ligne
et n'a pas de nom de domaine : rien n'a pu être mesuré sur Google, ChatGPT ou Perplexity. Les notes
ci-dessous sont des estimations, pas des mesures ni des signaux internes de Google.

## Principe retenu

Google l'écrit dans son guide d'optimisation pour l'IA (Search Central,
`developers.google.com/search/docs/fundamentals/ai-optimization-guide`) : optimiser pour les réponses
générées (AI Overviews, AI Mode), c'est faire du référencement. Une page doit être indexée et
pouvoir être citée ; il n'existe pas d'« index IA » séparé. Le guide écarte explicitement le fichier
`llms.txt`, le découpage du texte « pour l'IA », la réécriture en tournures supposées plaire aux
modèles et la course aux mentions artificielles. Nos choix suivent ce principe.

Le site parle de santé (catégorie « YMYL » chez Google) : la question « qui soigne, et avec quelles
compétences » pèse plus qu'ailleurs.

## Note de préparation : environ 60/100 (estimée ~40 avant les changements du jour)

| Critère | Poids | Estimation | Commentaire |
| --- | --- | --- | --- |
| Passages citables | 25 | 17 | Définition claire de l'agence dès l'accueil ; FAQ en réponses autonomes ; chaque fiche a désormais un résumé en une phrase et trois questions tirées des données. Pas de donnée originale ni de date de mise à jour. |
| Structure | 20 | 16 | Titres H1 → H2 → H3 propres, questions en titres, listes, grille des tarifs. |
| Médias | 15 | 6 | Illustrations générées (sans personne réelle), aucune vraie photo ni vidéo. |
| Autorité et marque | 20 | 4 | Pas de responsable médical nommé, pas d'adresse, pas de date, aucune présence hors du site (pas encore en ligne). |
| Accès technique | 20 | 17 | Rendu côté serveur, robots.txt, plan du site, adresses canoniques, versions linguistiques, données structurées. Manque : domaine et mise en ligne. |

## Ce qui a été fait le 2026-11-24

1. **Adresses canoniques et versions linguistiques corrigées.** Le gabarit annonçait les versions de
   l'accueil (`/fr`, `/ar`, `/en`) pour toutes les pages : une fiche de soin déclarait l'accueil comme
   traduction. Chaque page porte maintenant sa propre adresse canonique et ses trois versions, plus
   `x-default` (français) — `web/src/lib/seo.ts`, `pageMetadata()`.
2. **`/robots.txt`** (`web/src/app/robots.ts`) : tout le site ouvert, sauf le relais `/api/`. Le
   parcours de réservation reste ouvert mais porte `noindex`, pour que les robots puissent lire
   cette consigne.
3. **`/sitemap.xml`** (`web/src/app/sitemap.ts`) : accueil, soins, tarifs et chaque fiche de soin à
   domicile, dans les trois langues, avec leurs traductions (72 adresses avec le catalogue du
   2026-11-23). Pas de date de modification : l'API n'en fournit pas, et une date inventée est
   justement ce que Google sanctionne.
4. **Données structurées** (schema.org, JSON-LD rendu côté serveur, `web/src/components/JsonLd.tsx`) :
   - toutes les pages : `MedicalBusiness` (zone desservie Nador, langues, paiement en espèces, en
     dirhams, téléphone s'il est renseigné) et `WebSite` ;
   - fiche d'un soin : `Service` avec son offre (tarif de jour, en MAD) et `BreadcrumbList` ;
   - tarifs : `OfferCatalog` de tous les soins à domicile avec leur prix.
   Seuls des faits établis : pas d'adresse postale, d'horaires ni de note tant qu'ils n'existent pas.
   Pas de balisage `FAQPage` : Google le réserve aux sites officiels et de santé publique.
5. **Passages citables sur chaque fiche** : un résumé en une phrase (« Injection … à domicile, à
   Nador et dans sa région. Durée : environ 20 minutes. Tarif de jour : 345 DH, déplacement à Nador
   compris, réglé en espèces au soignant. ») et trois questions visibles sans clic (prix, qui réalise
   le soin, ordonnance), toutes tirées du catalogue : rien n'est écrit en dur, rien n'est inventé.
6. **Descriptions et aperçus de partage** : description propre à la page des soins, Open Graph sur
   toutes les pages (titre, description, langue `fr_MA` / `ar_MA` / `en_US`, image).

## Accès des robots d'IA (état de `robots.txt`)

Recherche et citation (à ouvrir, c'est le cas) :

| Robot | Ce qu'il décide | État |
| --- | --- | --- |
| `Googlebot` | Google Search, AI Overviews, AI Mode | autorisé (règle générale) |
| `OAI-SearchBot` | Citations dans ChatGPT Search | autorisé (nommé) |
| `Claude-SearchBot` | Citations dans la recherche de Claude | autorisé (nommé) |
| `PerplexityBot` | Réponses de Perplexity | autorisé (nommé) |
| `Applebot` | Siri, Spotlight, Safari | autorisé (règle générale) |

Entraînement des modèles (sans effet sur la présence dans les moteurs) :

| Robot | Usage | État |
| --- | --- | --- |
| `GPTBot` | Entraînement OpenAI | autorisé (règle générale) |
| `ClaudeBot` | Entraînement Anthropic | autorisé (règle générale) |
| `Google-Extended` | Entraînement et ancrage de Gemini / Vertex (pas Google Search) | autorisé (règle générale) |
| `CCBot` | Common Crawl | autorisé (règle générale) |
| `Applebot-Extended` | Entraînement d'Apple Intelligence | autorisé (règle générale) |

**Décision à prendre par l'agence** : laisser ou non ses pages servir à l'entraînement des modèles.
Les pages publiques ne contiennent aucune donnée de patient. Bloquer ces robots ne retire le site
d'aucun moteur de recherche. Il suffira d'ajouter leurs noms avec `disallow: '/'` dans `robots.ts`.

## `llms.txt`

Absent, volontairement. Google indique qu'il n'en tient pas compte (ni aide ni pénalité) et aucun
grand moteur de réponse n'a confirmé l'utiliser. À reconsidérer seulement si cela change.

## Présence de la marque hors du site

Rien n'existe encore (site hors ligne). Les assistants citent surtout des sources tierces : annuaires,
réseaux, vidéos, forums. Pour une agence de soins à domicile locale, dans l'ordre :

1. **Fiche d'établissement Google** (Google Business Profile) : c'est elle qui répond à « soins à
   domicile Nador » sur la carte et dans les réponses locales. Elle demande une adresse ou une zone
   desservie et un téléphone.
2. **Pages Facebook et Instagram, WhatsApp Business** : très utilisés au Maroc, et sources de mentions.
3. **Courtes vidéos** (YouTube, Shorts) : « comment se passe une injection à domicile », par un
   soignant de l'équipe, avec son accord.
4. Une fois ces comptes ouverts : les ajouter en `sameAs` dans les données `MedicalBusiness`.

Pas de faux avis ni de mentions achetées : c'est contraire aux règles de Google et au sérieux d'un
service de santé.

## Les 5 changements les plus utiles maintenant

1. **Mettre en ligne avec un domaine**, renseigner `NEXT_PUBLIC_SITE_URL`, puis déclarer le site et
   son plan dans Google Search Console et Bing Webmaster Tools (Bing alimente Copilot et une partie de
   ChatGPT). Dans Search Console, laisser le réglage « Search generative AI » sur « inclure ».
2. **Page « Notre équipe » ou « À propos »** : le responsable médical nommé, les métiers de l'équipe,
   le contrôle des diplômes et des autorisations d'exercer, les assurances. C'est le « qui » de Google
   pour un site de santé. Il faut les informations du client.
3. **Coordonnées réelles** : téléphone et WhatsApp (`NEXT_PUBLIC_CONTACT_PHONE`,
   `NEXT_PUBLIC_WHATSAPP_NUMBER`), puis adresse ou zone desservie pour la fiche Google.
4. **Vraies photos** de l'équipe et du matériel, à la place des illustrations générées (avec
   l'accord des personnes photographiées).
5. **Pages légales** (étape 6, après le juriste) : mentions, confidentialité et données de santé
   (loi 09-08). Elles comptent dans l'évaluation de confiance d'un site de santé.

## Textes à enrichir, quand le client les fournit

- **Descriptions des soins** : plusieurs sont d'une ligne (« Injection réalisée à domicile par un
  infirmier »). Deux ou trois phrases de première main suffisent : déroulé, matériel apporté,
  préparation demandée au patient. C'est le contenu « non banal » que Google demande.
- **Zones desservies** : une liste réelle des quartiers et communes (Beni Ensar, Selouane, Zeghanghane…)
  si l'agence s'y déplace effectivement.
- **Dates** : afficher « Tarifs en vigueur depuis le … » quand le back-office saura le dire. Jamais de
  date de mise à jour automatique.

## Pour vérifier après la mise en ligne

- Test des résultats enrichis de Google et validateur schema.org, sur une fiche de soin et sur les tarifs.
- Search Console : couverture du plan du site, versions linguistiques, requêtes « soins à domicile Nador ».
- Demander à ChatGPT, Perplexity et Gemini « soins infirmiers à domicile à Nador » et noter si
  Nador Care est cité, une fois par mois.
