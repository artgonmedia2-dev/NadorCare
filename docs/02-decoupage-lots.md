# Découpage en tâches — lots 3 à 7 (MVP uniquement)

Statut : **proposition à valider**. Chaque tâche correspond à un ou plusieurs petits commits et se termine par ses tests. Les fonctionnalités marquées V2 dans le cahier des charges sont exclues.

## Avancement

Lot 3 livré le 2026-11-21 : tâches 3.1 à 3.14 faites, avec trois écarts par rapport au tableau ci-dessous.

- 3.3 : pas de Mailpit ni de MinIO dans Docker. La plateforme n'envoie pas d'e-mail au MVP, et les fichiers privés utilisent le disque local en développement (S3 en production, par `.env`). Sous Windows, le serveur HTTP tourne en natif, le conteneur `api` étant trop lent.
- 3.11 : le panneau, le contrôle d'accès et le double facteur obligatoire sont en place et testés. Les écrans de gestion des utilisateurs, des rôles et des journaux sont reportés à la tâche 6.11.
- 3.14 : le fichier d'intégration continue est écrit mais n'a pas encore tourné sur GitHub (rien n'est poussé).

Lot 4, tâches 4.0 et 4.1 livrées le 2026-11-21 (38 tests Flutter), avec ces écarts :

- 4.0 : Drift n'est pas encore installé. Il arrivera avec le mode hors ligne (tâche 5.7), seul endroit du MVP qui en a besoin.
- 4.0 : Flutter 3.47.2 (version installée sur la machine) et non 3.50.1, faute d'espace disque pour la mise à jour.
- 4.0 et 4.1 : aucune compilation Android ni iOS n'a été faite (pas d'émulateur, disque presque plein, pas de Mac). La configuration native est écrite mais n'a jamais tourné sur un appareil.
- 4.1 : les écrans sont communs aux deux applications. Le design est provisoire, en attendant les maquettes.
- 4.1 : le consentement affiche les trois accords, sans lien vers les textes légaux, qui n'existent pas encore (tâche 6.10).

Tâche 4.2 livrée le 2026-11-21 (113 tests côté API, 53 côté Flutter), avec ces limites :

- La position d'une adresse vient du GPS du téléphone. Le choix d'un point sur une carte attend la clé Google Maps (tâche 4.4). Sans lui, un proche à l'étranger ne peut pas enregistrer l'adresse de son parent : il faut être sur place.
- Le rôle « proche » n'est pas encore attribué (question 16 ouverte) ; il n'ouvre aucun droit de plus que « patient » pour l'instant.
- Retirer un profil le masque sans l'effacer, pour garder l'historique des soins. L'effacement définitif relève de la demande de suppression (tâche 4.13).
- Plafonds ajoutés contre les abus, modifiables par `.env` : 10 profils et 20 adresses par compte.
- Toujours aucun essai sur un appareil.

Tâche 4.3 livrée le 2026-11-21, avec la partie « services et catégories » de la tâche 6.7 (128 tests côté API, 62 côté Flutter) :

- Le catalogue se lit sans compte, pour l'application et pour le futur site public.
- Les services installés par `php artisan db:seed --class=DemoCatalogueSeeder` sont des exemples aux prix inventés. La vraie liste et la grille tarifaire se saisissent dans le back-office (`/admin/services`), réservé à l'administrateur.
- Un service ou une catégorie ne se supprime pas : on le masque, pour garder les réservations rattachées lisibles.
- Reste de la tâche 6.7 à faire : majorations (nuit, jour férié, distance) et jours fériés.
- La fiche d'un soin n'a pas encore de bouton de réservation (tâche 4.4).

Tâche 4.4 et début de 4.5 livrés le 2026-11-21 (162 tests côté API, 73 côté Flutter), dans un cadre provisoire accepté par le client faute de décisions :

- Paiement en espèces uniquement. Le paiement par carte répond « pas encore disponible ».
- Créneaux de journée, de 8 h à 20 h toutes les 30 minutes, avec une heure de délai et 30 jours d'avance au plus. Tout se règle dans le back-office (`/admin/settings`).
- Majorations de nuit et de jour férié, en pourcentage ou en montant fixe (`/admin/surcharges`, `/admin/holidays`). La majoration de distance n'est pas appliquée : le cahier des charges ne dit pas depuis quel point la mesurer.
- Frais d'annulation tardive à 0 % par défaut, réglables. Leur perception quand le paiement est en espèces reste à décider.
- L'ordonnance est exigée dès la demande pour un soin sur prescription.
- Le back-office a une file des demandes (`/admin/bookings`) où le coordinateur confirme ou annule. L'affectation d'un professionnel reste à faire (tâche 6.2).
- Les créneaux ne tiennent pas compte de la disponibilité des professionnels : la coordination valide puis affecte.
- Non fait dans 4.4 : choix de l'adresse sur une carte (clé Google Maps). Non fait dans 4.5 : passage automatique à la coordination après un délai, sans objet tant que toute demande est validée par un coordinateur.
- Toujours aucun essai sur un appareil ; l'appareil photo et la galerie (ordonnance) s'ajoutent aux éléments natifs jamais lancés.

Affectation livrée le 2026-11-22 (tâche 6.2, et partie serveur de 5.3) — 191 tests côté API :

- Le coordinateur choisit parmi les professionnels éligibles, classés par zone couverte, disponibilité, distance et note. Deux modes : affectation directe, ou proposition avec délai de réponse (120 secondes par défaut, réglable).
- Conditions obligatoires, même pour une affectation directe : compte actif et vérifié, assurance responsabilité civile approuvée et valable le jour du soin, profession exigée par le service, aucune autre mission au même moment.
- Côté professionnel (API seulement) : propositions en attente, acceptation, refus, mes missions, détail d'une mission, désistement avant le départ, enregistrement de l'appareil pour les notifications.
- Avant d'accepter, le professionnel ne voit que le soin, le créneau, la zone et la distance.
- Non fait : écrans de l'application professionnel (5.3), affectation automatique (6.3), inscription et vérification des professionnels (5.1, 6.5). En attendant, `php artisan db:seed --class=DemoProfessionalsSeeder` installe cinq professionnels fictifs.
- Question 20 toujours ouverte : une seule proposition à la fois (choix fait ici), ou diffusion à plusieurs professionnels en même temps.
- Les notifications partent par le service factice : aucun téléphone ne reçoit rien tant que Firebase n'est pas branché.

## Lot 3 — Socle technique

| N° | Tâche | Résultat vérifiable |
| --- | --- | --- |
| 3.1 | Dépôt et outillage : `git init`, arborescence du monorepo, `.editorconfig`, `.gitignore`, Pint, Larastan | `composer lint` et `composer analyse` passent |
| 3.2 | Projet Laravel dans `/api`, configuration par `.env`, `.env.example` complet, langues fr/ar/en | `php artisan about` |
| 3.3 | Docker Compose : PHP, PostgreSQL + PostGIS, Redis, Horizon, Reverb, Mailpit, MinIO (S3 local) | `docker compose up` puis `/up` répond 200 |
| 3.4 | Squelette `/api/v1` : format d'erreur unique, limitation de débit, en-tête de langue, point de santé | Tests de contrat sur les erreurs |
| 3.5 | Migrations du schéma validé + PostGIS + seeders (rôles, catégories, zone de démonstration Nador) | `migrate:fresh --seed` |
| 3.6 | Interfaces des services externes et implémentations factices : SMS, WhatsApp, paiement, push, cartographie, stockage | Choix du pilote par `.env`, tests avec les factices |
| 3.7 | Authentification téléphone + OTP : demande, vérification, jetons Sanctum avec expiration, déconnexion, `/me`, anti-abus | Tests : code faux, expiré, rejoué, trop de tentatives |
| 3.8 | Rôles et permissions : six rôles, matrice de permissions, policies de base | Tests d'accès par rôle |
| 3.9 | Données de santé : champs chiffrés, service de fichiers chiffrés, journal d'accès en insertion seule, policy de cloisonnement par mission | Tests : accès hors mission refusé, chaque lecture journalisée |
| 3.10 | Machine à états des réservations + historique des statuts | Tests de toutes les transitions autorisées et interdites |
| 3.11 | Panneau Filament : connexion, double facteur obligatoire, expiration de session, gestion des utilisateurs et des rôles, lecture des journaux | Tests de connexion et de 2FA |
| 3.12 | Horizon, Reverb, planificateur, canaux privés authentifiés | Un événement de test arrive sur un canal privé |
| 3.13 | Documentation OpenAPI générée depuis le code, export `openapi.json` | `/docs/api` consultable, fichier versionné dans `/docs` |
| 3.14 | Intégration continue GitHub Actions : lint, analyse statique, tests avec PostgreSQL + PostGIS et Redis | Pipeline vert sur une pull request |

## Lot 4 — Application patient

Chaque tâche couvre les points d'API et les écrans.

| N° | Tâche |
| --- | --- |
| 4.0 | Socle Flutter : espace de travail `/mobile`, deux applications, paquets partagés (client API, design system, traductions, cœur), Riverpod, Drift, fr/ar/en avec RTL, taille de police réglable, épinglage de certificat |
| 4.1 | Compte : inscription et connexion par OTP, consentement daté, connexion biométrique, choix de la langue |
| 4.2 | Profils de patients et adresses (carte, repères d'accès, rattachement à une zone) |
| 4.3 | Catalogue : catégories, fiche service, tarif indicatif, recherche |
| 4.4 | Réservation en cinq écrans : service, patient et adresse, créneau immédiat ou planifié, paiement ou confirmation ; ordonnance en photo, note ; moteur de prix avec majorations |
| 4.5 | Règles de gestion : ordonnance obligatoire selon le service, escalade à la coordination après délai, annulation gratuite puis avec frais |
| 4.6 | Soins récurrents : création d'une série et génération des réservations |
| 4.7 | Suivi en temps réel : statut, position sur carte, heure d'arrivée estimée |
| 4.8 | Paiement : espèces, carte en ligne (fournisseur factice), reçu PDF |
| 4.9 | Notifications push, SMS et WhatsApp : confirmation, rappel, arrivée, compte rendu disponible |
| 4.10 | Historique : interventions, comptes rendus, reçus, nouvelle réservation en un geste |
| 4.11 | Évaluation et signalement d'un problème |
| 4.12 | Messagerie avec la coordination et appel direct |
| 4.13 | Droits loi 09-08 : accès, rectification, suppression depuis l'application ; mentions légales et message « urgences : 141 et 15 » |

## Lot 5 — Application professionnel

| N° | Tâche |
| --- | --- |
| 5.1 | Inscription, dépôt des justificatifs, statut de vérification |
| 5.2 | Disponibilités : agenda hebdomadaire, zones couvertes, bascule en ligne / hors ligne |
| 5.3 | Missions : réception en push, détail limité avant acceptation, acceptation ou refus avec délai de réponse |
| 5.4 | Déplacement : itinéraire, partage de position pendant le trajet uniquement |
| 5.5 | Intervention : pointage d'arrivée et de fin, actes réalisés, consommables |
| 5.6 | Compte rendu : constantes, observations, photos, signature à l'écran ; verrouillage après validation, avenant tracé |
| 5.7 | Mode hors ligne : saisie locale Drift, file de synchronisation, rejeu idempotent |
| 5.8 | Encaissement : confirmation des espèces, solde dû à la plateforme |
| 5.9 | Revenus : missions, montants, reversements, export mensuel |

## Lot 6 — Back-office

| N° | Tâche |
| --- | --- |
| 6.1 | Tableau de bord : demandes du jour, interventions en cours sur carte, alertes, indicateurs |
| 6.2 | Demandes : file d'attente, affectation manuelle, réaffectation, annulation |
| 6.3 | Affectation automatique : classement par spécialité, zone, disponibilité, distance, note ; choix forcé par le coordinateur |
| 6.4 | Saisie téléphonique : réservation créée pour un patient qui appelle ou écrit sur WhatsApp |
| 6.5 | Professionnels : dossiers, vérification des justificatifs, suspension, alertes d'expiration |
| 6.6 | Patients : comptes, profils, historique, réclamations, messagerie côté coordination |
| 6.7 | Catalogue et tarifs : services, catégories, durées, prix, majorations, jours fériés |
| 6.8 | Zones : dessin sur carte, activation |
| 6.9 | Finances : encaissements, commission, reversements, exports comptables |
| 6.10 | Contenus : pages, FAQ, bannières, modèles de notification |
| 6.11 | Rôles et journal : permissions par rôle, journal des actions sensibles, journal d'accès |
| 6.12 | Statistiques : volume par service, délai moyen d'affectation, taux d'annulation, satisfaction |

## Lot 7 — Site public

| N° | Tâche |
| --- | --- |
| 7.0 | Socle Next.js dans `/web` : trois langues, RTL, client API typé depuis OpenAPI |
| 7.1 | Pages : accueil, services, zones couvertes, tarifs, FAQ, à propos, contact ; bouton WhatsApp et numéro d'appel partout ; liens vers les stores |
| 7.2 | Réservation en ligne, même parcours que l'application, avec OTP |
| 7.3 | Recrutement des professionnels : page et formulaire de candidature |
| 7.4 | Blog santé |
| 7.5 | Référencement : données structurées, plan du site, `hreflang`, pages par service et par ville |
| 7.6 | Pages légales : conditions générales, confidentialité, message sur les urgences vitales |

## Ordre conseillé

Le lot 3 d'abord. Ensuite le parcours critique de bout en bout, en avançant les trois lots de front : réservation (4.1 à 4.5), affectation (6.2, 6.3, 5.3), intervention et compte rendu (5.4 à 5.7), paiement (4.8, 5.8, 6.9). Le reste des lots 4 à 6 suit, puis le lot 7.
