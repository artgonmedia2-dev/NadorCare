# Questions ouvertes et décisions

Quand une question est tranchée, noter la décision et sa date ici, puis reporter la règle dans `CLAUDE.md`.

## Décisions prises

| N° | Décision | Date |
| --- | --- | --- |
| 8 | Paiement carte : **Payzone** (et non CMI comme écrit dans le cahier des charges) | 2026-11-21 |
| 9 | Le passage de « en attente » à « confirmée » est **toujours fait par un coordinateur** (ou un administrateur), jamais par le système | 2026-11-21 |
| 10 | Caches Gradle, Pub et npm vidés ; Docker Desktop installé pour le développement local | 2026-11-21 |
| 11 | Dépôt : `https://github.com/artgonmedia2-dev/NadorCare.git` | 2026-11-21 |
| 12 | Filament vit dans l'application Laravel et partage les classes métier de l'API, sans passer par HTTP | 2026-11-21 |
| 13 | **PHP 8.4** partout (Docker, intégration continue, local dans `C:\php84`) | 2026-11-21 |

## A. Bloquaient l'étape 2 (socle technique) — toutes tranchées, voir ci-dessus

| N° | Question | Pourquoi c'est bloquant |
| --- | --- | --- |
| 8 | **Paiement carte : Payzone ou CMI ?** La consigne de développement dit Payzone, le cahier des charges (§8, §12) dit CMI. | Nom du pilote, variables `.env`, documentation. L'interface reste la même. |
| 9 | **Sens de « en attente » et de « confirmée ».** Proposition : en attente = demande à valider (ordonnance, paiement carte, coordination) ; confirmée = validée, recherche d'un professionnel. Qui confirme : le système seul quand rien n'est à contrôler, ou toujours un coordinateur (§2 « valider les demandes ») ? | Machine à états et migrations. |
| 10 | **Environnement local.** Le disque C: n'a plus que 2 Go libres, Docker est absent, PostgreSQL aussi. Puis-je libérer de l'espace (caches Gradle, Pub, npm, SDK Flutter 3.44.9 inutilisé), et installez-vous Docker Desktop ? | Rien ne peut être installé en l'état. |
| 11 | **Dépôt Git.** Dépôt GitHub du client ou d'Artgon MEDIA ? Nom du dépôt ? Privé ? | Intégration continue GitHub Actions, propriété du code (§13). |
| 12 | **Back-office et « API unique porte d'entrée » (§8).** Filament lit la base par Eloquent, pas par l'API REST. Proposition : Filament vit dans la même application Laravel et appelle les mêmes classes métier que l'API, sans passer par HTTP. Acceptable ? | Architecture du lot 3 et du lot 6. |
| 13 | **PHP 8.3 ou 8.4.** La machine a PHP 8.3, suffisant pour Laravel 13. Rester en 8.3 partout, ou passer en 8.4 (dans Docker et en local) ? | Image Docker, version des outils de test. |

## B. Points à trancher de la section 13 (bloquent les lots 4 à 7)

| N° | Point du cahier des charges | Ce que la réponse change dans le code | Lot bloqué |
| --- | --- | --- | --- |
| 1 | Modèle juridique : coordination avec professionnels indépendants, ou autre structure | Qui émet le reçu et à quel nom, textes légaux, contenu du consentement | 4.8, 4.13 |
| 2 | Modèle économique : commission, abonnement des professionnels, ou marge | Règles d'écriture du grand livre, calcul des reversements | 5.8, 5.9, 6.9 |
| 3 | Liste des services au lancement et grille tarifaire | Données initiales du catalogue, majorations | 4.3, 6.7 |
| 4 | Qui encaisse le paiement en ligne, comment le professionnel est rémunéré | Flux carte, remboursements, périodicité des reversements | 4.8, 6.9 |
| 5 | Horaires : journée ou 24 h/24 | Créneaux proposés, majoration de nuit, astreinte de coordination | 4.4, 6.3 |
| 6 | Lieu d'hébergement, après échange avec la CNDP | Fournisseur S3, cible de déploiement, sauvegardes | Mise en production |
| 7 | Prestataire de réalisation et budget | Aucun effet sur le code | — |

## C. Précisions fonctionnelles (bloquent une tâche précise)

| N° | Question | Tâche |
| --- | --- | --- |
| 14 | Carte bancaire : débit à la réservation, empreinte puis débit à la fin, ou paiement après le soin ? | 4.8 |
| 15 | Frais d'annulation : montant fixe ou pourcentage ? Comment sont-ils perçus quand le paiement prévu était en espèces ? | 4.5 |
| 16 | Rôle « proche » : choisi à l'inscription, ou attribué automatiquement dès qu'un compte gère le profil d'un tiers ? | 4.2 |
| 17 | Consommables : simple traçabilité, ou facturés au patient en plus du tarif ? | 5.5 |
| 18 | Agenda du professionnel : hebdomadaire seulement (comme écrit), ou aussi des exceptions datées (congés, indisponibilité ponctuelle) ? | 5.2 |
| 19 | Série de soins : même professionnel sur toute la série si possible ? Paiement par séance ou pour la série entière ? | 4.6 |
| 20 | Affectation automatique : diffusion à plusieurs professionnels en même temps (premier qui accepte), ou proposition l'un après l'autre ? | 6.3 |
| 21 | Messagerie : uniquement patient ↔ coordination comme écrit, ou aussi professionnel ↔ coordination ? | 4.12 |

## D. Dépendances externes

| N° | Question |
| --- | --- |
| 22 | Maquettes Figma et design system (lot 2) : existent-ils ? Sinon je pars sur un design system provisoire, à remplacer. |
| 23 | Compilation iOS : impossible sous Windows. Un Mac est-il disponible, ou passe-t-on par un service de build macOS ? |
| 24 | Comptes à créer par le client : Firebase (push), Google Maps Platform, comptes développeur Apple et Google, passerelle SMS, WhatsApp Business. En attendant, tout reste en implémentation factice. |
