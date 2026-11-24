# Nador Care

Plateforme de coordination de soins à domicile à Nador (Maroc) : application patient, application professionnel, back-office web, site public, API commune.

## Source de vérité

`Cahier des charges — Plateforme Nador Care (Web + App mobile).md` (CDC-2026-NDC-01 v1.0), à la racine. Tout développement en découle. Si un point est ambigu ou absent : poser la question, ne pas supposer. Les questions ouvertes et les décisions prises sont dans `docs/03-questions-ouvertes.md`.

## État du projet

- Étape 1 (cadrage) : validée le 2026-11-21.
- Étape 2 (socle technique, lot 3) : livrée le 2026-11-21 (avancement en tête de `docs/02-decoupage-lots.md`). Reste du lot 3 reporté au lot 6 : écrans Filament de gestion des utilisateurs, des rôles et des journaux.
- Lot 4 : tâches 4.0 (socle Flutter), 4.1 (compte), 4.2 (profils de patients, adresses) 4.3 (catalogue, avec sa gestion dans le back-office) et 4.4 (réservation, dans un cadre provisoire : espèces, créneaux de journée) livrées le 2026-11-21. Première compilation Android le 2026-11-22 : l'application patient démarre sur un téléphone réel et joint l'API locale (demande de code vérifiée) ; l'application professionnel est compilée mais pas encore installée ni lancée. Le reste des parcours n'a pas encore été essayé sur appareil.
- Affectation (6.2 et partie serveur de 5.3) livrée le 2026-11-22 : back-office et API, pas encore d'écran dans l'application professionnel.
- Dossier des professionnels (parties serveur de 5.1 et 5.2, tâche 6.5) livré le 2026-11-22 : inscription, justificatifs, vérification, suspension, zones, agenda. Les écrans correspondants de l'application professionnel (5.1 à 5.3) sont livrés le même jour ; le déplacement, l'intervention et le compte rendu (5.4 à 5.6) aussi, avec le suivi et la lecture du compte rendu côté patient. Restent pour le professionnel : avenant dans l'application, suivi de position en arrière-plan, mode hors ligne (5.7), paiements (5.8).
- Téléconsultation : première version le 2026-11-23, serveur et applications, avec un appel simulé. Fermée aux patients, en attente du paiement par carte (4.8). Jamais essayée sur un appareil. **Développement suspendu** à la demande du client : prestataire vidéo, tarifs, cadre légal et ordonnance électronique (questions 31 à 34 de `docs/03-questions-ouvertes.md`) doivent être validés avant d'aller plus loin.
- Site public (lot 7) : première version le 2026-11-23 dans `/web` — accueil, liste et fiche des soins, réservation en ligne avec code par SMS, trois langues. Le reste du lot 7 n'est pas fait (voir `web/README.md`). Pas de tests automatisés ni d'intégration continue pour le site.
- Modèle « agence » : fonctionnement cible validé par le client le 2026-11-23 (`docs/04-fonctionnement-cible-agence.md`, six étapes). Étape 1 livrée le même jour : l'agence crée, modifie et invite ses soignants au back-office ; l'application professionnel ne s'ouvre qu'à un numéro enregistré par l'agence (`pro_account_unknown` sinon) et l'inscription libre a disparu (route `PUT /pro/profile` et écran de choix de la profession supprimés). Étape 2 (planning) livrée le même jour : zones et semaine type fixées par la coordination sur la fiche du soignant, demandes du soignant (autre semaine, indisponibilité) acceptées ou refusées au back-office, planning global de l'équipe (`/admin/planning`) ; les routes `PUT /pro/profile/zones` et `/availabilities` et l'écran des zones ont disparu. Étape 3 (affectation à confirmer) livrée le même jour : le coordinateur affecte, le soignant confirme ou signale son indisponibilité avec un motif (délai de 15 minutes pour un soin du jour, 2 heures sinon, réglable) ; le back-office signale les demandes à réaffecter ; les propositions à minuterie et l'interrupteur « En ligne » ont disparu. Étape 4 (dossier et validité des documents) livrée le même jour : l'agence dépose les justificatifs et envoie le dossier à la vérification depuis la fiche du soignant ; l'assurance personnelle est facultative et n'est plus une condition d'affectation ; l'assurance de l'agence s'enregistre dans `/admin/agency-insurance` ; le tableau de bord liste les justificatifs à renouveler. Étape 5 (suivi financier) livrée le même jour, au back-office seulement (`/admin/finance`) : par soignant et par mois, missions réalisées, espèces encaissées et remises, reste à remettre, rémunération due saisie à la main ; le comptable pointe les remises et saisit la rémunération, l'administrateur lit. Aucune de ces cinq étapes n'a été essayée sur un téléphone ni dans un navigateur. Étape restante : textes légaux, après l'avis du juriste.
- Refonte UX/UI (2026-11-24) : maquettes dans Figma (« Nador Care — Refonte UX/UI », fondations, composants, tableau de bord et planning du back-office) et dans `docs/maquettes/site-public.html` (site public ; la limite de l'offre Figma Starter a empêché de les faire dans Figma). Appliquée le même jour au back-office (habillage, tableau de bord de la coordination, planning) et au site (accueil, réservation rapide, créneaux par moment de la journée, récapitulatif modifiable). Les applications mobiles ont été alignées le même jour (couleurs, cartes, étiquettes, bandeau d'accueil du patient) et ont reçu les polices du site, embarquées dans `nc_design_system/fonts` (Figtree pour les titres et les boutons, Noto Sans pour le texte, Noto Sans Arabic en relais pour l'arabe). Le même jour, sur demande du client, les écrans mobiles ont été revus d'après une maquette Dribbble d'application de soins à domicile (« Mobile App for Home Healthcare ») : fond gris clair, cartes blanches ombrées sans bordure, boutons en pilule, accueils à onglets en bas (patient : Accueil, Soins, Rendez-vous, Compte ; soignant vérifié : Missions, Planning, Dossier, Compte). Pas encore réinstallées sur le téléphone.
- Suite des lots 4 à 7 : en attente des points à trancher (`docs/03-questions-ouvertes.md`, sections B et C).
- Dépôt : `https://github.com/artgonmedia2-dev/NadorCare.git`, branche `main`.

## Décisions structurantes

- **Modèle (2026-11-23) : Nador Care est une agence de soins à domicile qui soigne avec sa propre équipe** (médecins, infirmiers, aides-soignants). Ce n'est **pas un intermédiaire** : le cahier des charges dit « met en relation » et « professionnels indépendants », la décision prime. Dans tout texte destiné aux patients, écrire « notre équipe », « nos soignants », jamais « plateforme », « mise en relation » ni « professionnels partenaires ». Du modèle précédent, il ne reste que des traces inutilisées : `professionals.payout_details`, les tables `payouts` et `ledger_entries` (commission) ; ne pas les utiliser. La permission `payouts.manage` désigne désormais la tenue des comptes des soignants par le comptable. L'inscription libre des soignants, les propositions de mission à minuterie et l'interrupteur « en ligne » sont supprimés (la table `booking_offers` et la colonne `professionals.is_online` restent en base, plus rien ne les utilise). Le fonctionnement cible (comptes créés par l'agence, affectation par le coordinateur avec confirmation du soignant, planning centralisé, suivi financier sans commission) est décrit dans `docs/04-fonctionnement-cible-agence.md`, validé par le client le 2026-11-23 avec ses dix règles par défaut (section 5) : s'y tenir, et suivre l'ordre des étapes de sa section 6.
- Paiement carte : **Payzone** (le cahier des charges dit CMI, la décision du 2026-11-21 prime).
- Grille tarifaire (2026-11-23) : tarif de jour de la grille de référence du client + 150 DH par service ; soir (19 h à 8 h) : 50 DH de plus, par la majoration de nuit. Aucun prix en dur hors de `NadorCatalogueSeeder` et du back-office ; le site lit les prix et la majoration dans l'API (`/catalogue/services`, `/catalogue/surcharges`). Exception provisoire : la garde-malade (`web/src/content/home-guard.ts`), voir la question 26.
- Une réservation passe de `pending` à `confirmed` uniquement par un coordinateur ou un administrateur.
- Filament vit dans l'application Laravel et appelle les mêmes classes d'action que l'API, sans passer par HTTP.
- PHP 8.4 partout.
- Téléconsultation (2026-11-23) : un soin a un mode de réalisation, `home` ou `remote` (`services.delivery_mode`). Une téléconsultation n'a pas de trajet (`affectée` → `en cours` directement), se rejoint par un appel vidéo dans l'application, et son compte rendu se valide sans signature. Elle ne se règle que par carte : tant que le paiement par carte n'existe pas, elle reste **fermée** (réglage `teleconsultation.enabled` à 0, soins `remote` absents du catalogue) et ne doit pas être ouverte à de vrais patients. Le prestataire vidéo n'est pas choisi : seul le pilote factice existe, l'appel est simulé. L'adresse reste demandée : elle dit où envoyer des secours si l'appel révèle une urgence. Tarification : un soin par type de consultation (généraliste, puis un par spécialité), jamais un tarif par médecin ; tarif fixe quelle que soit l'heure, aucune majoration (soir, nuit, jour férié) ne s'applique à un soin `remote`. Première phase : médecin généraliste seulement, 20 minutes, 150 DH, soin créé désactivé.
- Médecine à domicile (2026-11-23) : consultation d'un médecin généraliste à 500 DH le jour, tarif fixé directement par le client (sans les 150 DH de la règle générale).

## Stack (section 8 du cahier des charges)

| Couche | Technologie | Version stable relevée le 2026-11-21 |
| --- | --- | --- |
| API | Laravel, REST + JSON, Sanctum, `/api/v1` | Laravel 13.x (PHP ≥ 8.3) |
| Back-office | Filament | 5.x |
| Rôles | spatie/laravel-permission | 8.x |
| Files, temps réel | Horizon, Reverb | 5.x, 1.x |
| Données | PostgreSQL + PostGIS, Redis | à fixer avec l'image Docker |
| Mobile | Flutter, Riverpod, Drift | Flutter 3.50.x, Riverpod 3.x, Drift 2.x |
| Site public | Next.js | 16.x, React 19 |

Revérifier la documentation officielle au moment de chaque installation, et figer les versions exactes dans les fichiers de verrouillage.

## Structure du monorepo (cible)

```
/api      Laravel : API /api/v1, back-office Filament, files, temps réel
/mobile   Flutter : apps/patient, apps/pro, packages/ partagés
/web      Next.js : site public
/docs     Cadrage, schéma, OpenAPI exporté, architecture, exploitation
/docker   Images et configuration des services
/.github  Intégration continue
```

Organisation de `/api/app` :

- `Actions/<Domaine>` : une classe par cas d'usage (`Auth\LoginWithOtp`, `Bookings\TransitionBooking`, `Health\ReadPatientRecord`). Les contrôleurs d'API et les écrans Filament appellent ces mêmes classes ; aucune règle métier dans un contrôleur ou une ressource Filament.
- `Contracts` : interfaces des services externes. `Services/<Service>` : leurs implémentations (factices pour l'instant) et les services internes (`Auth\OtpService`, `Files\EncryptedFileStore`, `Health\AccessLogger`). Le lien se fait dans `Providers/ExternalServicesProvider`.
- `Enums` : rôles, permissions, statuts. `Policies` : droits d'accès, dont le cloisonnement par mission.
- `Http/Controllers/Api/V1`, `Http/Requests/Api/V1`, `Http/Resources/Api/V1` : couche HTTP de la version 1.
- `lang/{fr,ar,en}/api.php` : tous les textes renvoyés par l'API. `lang/{fr,ar,en}/admin.php` : tous les libellés du back-office.
- Habillage du back-office : `public/css/nadorcare-admin.css`, branché par un render hook (`resources/views/filament/head.blade.php`), sans compilation (pas de Vite dans `/api`). La nuance `primary` est fixée à la main dans `AdminPanelProvider` : les nuances 500 et 600 doivent garder un contraste d'au moins 4,5:1 avec le texte blanc, sinon Filament passe les boutons en clair. Tableau de bord : `Filament/Pages/Dashboard` et ses widgets ; les actions d'une demande sont dans `BookingResource::recordActions()`, partagées par la liste et le tableau de bord. Dans le back-office, écrire « soignant », pas « professionnel ».
- `Filament/Resources/<Pluriel>` : écrans du back-office (structure générée par `make:filament-resource`). Chaque ressource limite son accès par `canAccess()` et une permission. Les champs traduisibles passent par `Filament\Support\TranslatableFields`.
- Les textes stockés en `{fr, ar, en}` se lisent avec `Support\Translated::pick()`. Ne pas comparer ces tableaux avec `assertSame` : PostgreSQL ne garde pas l'ordre des clés d'un `jsonb`.
- Une liste Filament charge souvent une relation avec quelques colonnes seulement (`service:id,name`) : une action métier ne doit pas compter sur une relation déjà chargée, elle relit ce dont elle a besoin (défaut rencontré le 2026-11-22 dans l'affectation).
- De même, ne pas décider à partir d'une relation gardée en mémoire sur l'utilisateur (`$user->professional`) : relire l'état en base (`$user->professional()->first()`), car il change par le back-office.
- Dans un test qui mélange API et back-office, `Sanctum::actingAs()` change le garde par défaut : se connecter ensuite au back-office avec `actingAs($staff, 'web')`.
- Horodater avec l'horloge de l'application (`now()` passé en paramètre), pas avec le `now()` de PostgreSQL : les tests figent l'horloge de l'application (défaut rencontré le 2026-11-22 sur la position du professionnel).
- Un test qui envoie un fichier par un formulaire Filament se joue à l'heure réelle (`travelBack()`) : avec l'horloge figée dans le futur, le nettoyage des envois temporaires de Livewire supprime le fichier tout juste déposé et la validation répond « type de fichier refusé » (défaut rencontré le 2026-11-23).
- Dans les tests, la langue par défaut est le français (`Accept-Language: fr`, posé par `Tests\TestCase`).

Points d'entrée obligatoires :

- lire les données de santé d'un patient : `ReadPatientRecord` (vérifie le droit, journalise) ;
- lire ou écrire un fichier privé : `EncryptedFileStore` ;
- changer le statut d'une réservation : `TransitionBooking` ; créer une réservation : `CreateBooking` ; l'annuler : `CancelBooking` (calcule les frais) ;
- savoir qui peut prendre une réservation : `Services\Assignment\ProfessionalMatcher` (seule source des conditions d'éligibilité) ; affecter : `Actions\Assignment\AssignProfessional` (seule la coordination affecte ; fixe l'heure limite de confirmation), réponse du soignant : `RespondToAssignment` (confirmer, ou signaler son indisponibilité avec un `DeclineReason`), retrait par la coordination : `UnassignProfessional` ; demandes à réaffecter : `Booking::needsReassignment()` ;
- faire entrer un soignant dans l'équipe, modifier sa fiche, l'inviter : `Actions\Professionals\ManageTeam` (seul moyen de créer une fiche ; permission `professionals.manage`, coordinateur et administrateur) ;
- planning d'un soignant : `Actions\Professionals\ManagePlanning` (la coordination fixe zones et semaine type ; le soignant propose une semaine ou signale une indisponibilité ; la coordination accepte ou refuse) ; planning global : `Services\Planning\TeamWeek` (aucune donnée de patient). Ne pas appeler `UpdateProfessionalSchedule` directement pour les zones ou l'agenda ;
- dossier d'un professionnel : `Actions\Professionals\ManageProfessionalFile` (justificatifs et envoi, côté professionnel ; `acceptedTypes()` dit ce qui peut être déposé, l'assurance personnelle étant facultative), `ManageTeam::depositDocument` et `submitFile` (dépôt et envoi par l'agence ; approuvé d'emblée si c'est un administrateur qui dépose), justificatifs à renouveler : `ProfessionalDocument::constrainToNeedsRenewal()`, assurance de l'agence : `Actions\Agency\ManageAgencyInsurance`, `ReviewProfessional` (décisions de l'administrateur) ;
- argent d'un soignant : lire avec `Services\Finance\CaregiverLedger` (relevé du mois, solde d'espèces ; aucune donnée de patient), écrire avec `Actions\Finance\ManageCaregiverAccount` (remise d'espèces, rémunération due) ; aucun calcul automatique de rémunération ni de commission ;
- tracer une action sensible du back-office : `Services\Audit\AuditLogger` ;
- prévenir un professionnel : `Services\Notifications\MissionNotifier` (jamais de donnée du patient dans une notification) ;
- lire un paramètre de gestion : `Services\Settings\Settings` (valeurs par défaut dans `Settings::DEFAULTS`) ;
- déroulement d'une mission : `Actions\Interventions\RunIntervention` (départ, position, arrivée) ; compte rendu : `Actions\Interventions\WriteReport` (brouillon, photos, signature, clôture, avenant) ;
- téléconsultation : `Actions\Teleconsultation\JoinTeleconsultation` (seule porte d'entrée de la salle vidéo : vérifie le compte, le statut et l'heure) ; démarrage par le professionnel : `RunIntervention::startRemote` ; prestataire vidéo : `Contracts\VideoGateway` (ne lui transmettre aucune donnée du patient) ; côté mobile, l'écran d'appel commun est `TeleconsultationScreen` (`nc_account`) ;
- savoir quels soins montrer aux patients : `Service::offered()` (ou `Service::constrainToOffered()` dans une sous-requête), jamais un simple `is_active` ;
- calculer un prix : `Services\Bookings\PriceCalculator` ; savoir si un créneau est réservable : `Services\Bookings\BookingSchedule` ;
- renvoyer une erreur métier : `ApiException('code')`, avec le texte dans `lang/*/api.php`.

Organisation de `/mobile` (espace de travail pub, voir `mobile/README.md`) :

- `apps/patient`, `apps/pro` : un `main.dart` et les écrans propres à chaque application. Tout le reste est partagé.
- `packages/nc_core` (modèles, `ApiFailure`, `AppConfig`), `nc_api_client` (Dio, épinglage), `nc_l10n` (ARB fr/ar/en), `nc_design_system` (thème et composants provisoires), `nc_account` (connexion OTP, consentement, réglages, biométrie, enveloppe `NadorCareApp` et routes communes).
- Le paquet `offline` (Drift, file de synchronisation) reste à créer avec la tâche 5.7.

Règles mobiles :

- aucun texte en dur : `context.l10n.cle`, clés dans `nc_l10n/lib/src/arb`, puis `flutter gen-l10n` (les fichiers générés sont commités et vérifiés par la CI) ;
- les écrans n'utilisent que les composants de `nc_design_system` (`NcPage`, `NcPrimaryButton`, `NcNotice`, `NcSurface`, `NcHeroCard`…) et des marges directionnelles, pour l'arabe ; les couleurs sont celles de `NcColors` (les mêmes que le site et le back-office), lues par le thème : pas de `Color(0x…)` dans un écran. Tons d'étiquette comme au back-office : `brand` (affectée, confirmée), `info` (en route), `progress` (en attente, à confirmer), `success`, `danger`, `neutral` ;
- un champ de saisie a son libellé au-dessus de lui, par `NcLabeledField` : jamais de `labelText` dans le champ, ni de libellé placé après ;
- un écran de modification qui peut être quitté sans enregistrer est enveloppé dans `UnsavedChangesGuard` (`nc_account`) et confirme l'enregistrement réussi par un message bref (`changesSaved`) ; fait pour les zones et l'agenda, à étendre aux formulaires de patient et d'adresse ;
- dans un choix à une seule possibilité (un seul patient, une seule adresse desservie), la valeur est déjà choisie : l'utilisateur n'a qu'à continuer ;
- le jeton vit dans le stockage sécurisé (`SecureSessionStorage`), jamais dans les préférences ;
- les erreurs d'API arrivent en `ApiFailure` ; le message du serveur est déjà traduit, `failureMessage()` le choisit ;
- les numéros de téléphone et les codes s'affichent toujours de gauche à droite ; un numéro inséré dans une phrase passe par `isolateLtr()` (ne jamais écrire le caractère U+2066 dans le code, l'analyseur le refuse) ;
- les heures de soin sont celles de Nador : l'application affiche `scheduled_date` et `scheduled_time` tels que le serveur les envoie, sans conversion vers le fuseau du téléphone ;
- montants, dates et distances passent par les formateurs de `nc_l10n` (`formatDirhams`, `longDate`, `apiDate`, `formatDistance`) ;
- un champ de saisie dans une fenêtre de dialogue vit dans un `StatefulWidget` qui possède son contrôleur : le détruire dès la fermeture casse l'animation de sortie (défaut rencontré le 2026-11-22) ;
- tant que les notifications ne sont pas branchées, l'accueil du professionnel se rafraîchit seul toutes les 15 secondes, et la fiche de réservation du patient toutes les 20 secondes quand un soignant est attendu ;
- la position du professionnel ne part que pendant un trajet : `JourneyTracker` (application professionnel) se règle sur la liste des missions, seule source du démarrage et de l'arrêt ;
- les constantes d'un compte rendu ont leurs bornes dans `Vital` (`nc_core`), à garder identiques à `InterventionReport::VITALS` côté serveur ;
- accueils à onglets : `NcTabScaffold` ne construit que l'onglet affiché ; un écran qui sert aussi d'onglet prend `embedded: true` (pas de bouton de retour : `BookingsScreen`, `FileScreen`). Composants d'accueil dans `nc_home.dart` (`NcHomeHeader`, `NcActionTile`, `NcTileGrid`, `NcFeedRow`, `NcStatTile`). L'accueil patient lit les catégories par `homeCategoriesProvider`, pas `careCategoriesProvider` : il reste ouvert sous le catalogue, et partager la lecture empêcherait le catalogue de se recharger à son ouverture ;
- écrans intérieurs (`nc_detail.dart`) : une fiche (soin, réservation, mission, compte rendu) commence par `NcDetailHeader` passé à `NcPage.header`, et regroupe ses informations en `NcSection` ; suivi d'une réservation par `NcTimeline` (libellés `timeline*`, distincts des libellés d'état pour ne pas les répéter sur la fiche) ; créneaux en `NcChipGrid` groupés matin, après-midi et soir (le soir commence à 19 h, comme la majoration), jours en `NcDayStrip` ; réussite par `NcSuccessPanel` ; choix entre deux vues par `NcSegmented` (réservations à venir ou passées). Une constante du compte rendu a son icône (`vitalIcon`, `nc_account`), un justificatif aussi (`documentTypeIcon`, application professionnel). Une tuile posée dans une carte blanche prend `flat: true`. Un bouton secondaire en teal clair (heures de la semaine proposée) fixe ses couleurs par `FilledButton.styleFrom` : le thème donne le teal plein à tous les `FilledButton`, `tonal` compris ;
- un libellé de tuile doit tenir sur la largeur d'une colonne sans couper un mot : au-delà d'un mot long, préférer une ligne (`NcFeedRow`) à une tuile ;
- dans un test d'écran, agrandir la surface (`tester.view.physicalSize`) : les listes ne construisent que ce qui est visible.

## Règles non négociables

1. **Données de santé (loi 09-08).** Champs sensibles chiffrés (cast `encrypted`), fichiers chiffrés avant stockage, accès cloisonné par mission (policy), chaque accès écrit dans `access_logs`. Jamais de donnée de santé dans les journaux applicatifs, les messages d'erreur, les notifications push ou Sentry.
2. **Aucun secret dans le code.** Tout passe par `.env` ; `.env.example` mis à jour dans le même commit que toute nouvelle variable.
3. **Services externes derrière des interfaces** (SMS, WhatsApp, paiement carte, push, cartographie, stockage), avec une implémentation factice pour le développement et les tests. Le pilote se choisit par `.env`. Les contrats ne sont pas signés.
4. **Trois langues dès le départ** : français, arabe (RTL), anglais. Aucun texte en dur dans un écran, un e-mail, un SMS ou une réponse d'API.
5. **Tests automatisés** sur les parcours critiques : authentification, réservation, affectation, paiement, compte rendu.
6. **Commits petits et descriptifs**, une fonctionnalité à la fois.
7. **Aucune fonctionnalité V2** : dossier de suivi, abonnements, note de transmission, bouton d'alerte, codes promotionnels, comptes entreprises, mode sombre. La téléconsultation n'en fait plus partie : le client l'a fait entrer dans la première version le 2026-11-23.
8. **Fin de tâche** : résumer ce qui a été fait, comment le tester, ce qui vient ensuite.

## Conventions

- Code, noms de tables, de colonnes et de routes en anglais ; documentation et messages de commit en français.
- Clés primaires ULID ; montants en centimes de dirham (entiers) ; dates en UTC (`timestamptz`), affichage `Africa/Casablanca`.
- Textes traduisibles en `jsonb` `{fr, ar, en}`.
- Statuts : enums PHP adossées à des colonnes `varchar`.
- Le statut d'une réservation ne change que par la machine à états, qui écrit `booking_status_history`.
- Statuts de réservation : `pending`, `confirmed`, `assigned`, `en_route`, `in_progress`, `completed`, `cancelled`, `disputed`.
- Rôles : `patient`, `proche`, `professionnel`, `coordinateur`, `administrateur`, `comptable`.
- API : réponses JSON, format d'erreur unique, pagination par curseur, langue par l'en-tête `Accept-Language`, en-tête `Idempotency-Key` sur les créations rejouables (paiement, synchronisation hors ligne).
- Un compte rendu validé est immuable ; une correction crée un avenant.
- Schéma de référence : `docs/01-schema-base-de-donnees.md`. Découpage des lots : `docs/02-decoupage-lots.md`.

## Commandes utiles

Sur cette machine, remplacer `php` par `C:\php84\php.exe` et `composer` par `C:\php84\php.exe C:\composer\composer.phar`.

```powershell
# Services Docker : PostgreSQL + PostGIS (5432), Redis (6380), Horizon, Reverb (8080), planificateur
docker compose up -d
docker compose ps
docker compose logs horizon --tail 20

# API (dans /api) — le serveur HTTP tourne en natif sous Windows
php artisan serve                      # http://localhost:8000
php artisan migrate:fresh --seed
php artisan db:seed --class=NadorCatalogueSeeder  # catalogue et grille du client (2026-11-23) ; retire les services de démonstration
php artisan db:seed --class=DemoCatalogueSeeder   # catalogue de démonstration (prix inventés, jamais en production)
php artisan db:seed --class=DemoProfessionalsSeeder   # cinq professionnels fictifs, pour essayer l'affectation
php artisan nadorcare:create-staff     # compte du back-office
php artisan nadorcare:files-key        # clé de chiffrement des fichiers
composer test                          # tests, base nadorcare_test dans Docker
composer lint                          # Pint (composer format pour corriger)
composer analyse                       # Larastan niveau 5
composer openapi                       # régénère docs/openapi.json (vérifié par la CI)
composer require <paquet> --ignore-platform-req=ext-pcntl --ignore-platform-req=ext-posix

# Mobile (dans /mobile)
flutter pub get
flutter analyze                               # tout l'espace de travail
cd packages\nc_account; flutter test          # idem dans packages\nc_api_client, apps\patient et apps\pro
cd packages\nc_l10n; flutter gen-l10n         # après toute modification d'un fichier .arb
cd apps\patient; flutter run                  # ou apps\pro ; API vue par l'émulateur sur 10.0.2.2:8000

# Sur un téléphone branché en USB (adb dans %LOCALAPPDATA%\Android\Sdk\platform-tools)
flutter build apk --debug --target-platform android-arm64 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb reverse tcp:8000 tcp:8000                 # à refaire après chaque débranchement
# Le code de connexion est dans api\storage\logs\laravel.log, ligne « [SMS factice] »

# Site (dans /web) — l'API doit tourner ; règles du site dans web/README.md
pnpm install
pnpm dev                                      # http://localhost:3000
pnpm build; pnpm start
pnpm typecheck
pnpm texts                                    # après toute modification d'un texte du site ou d'un fichier .arb repris par le site
```

## Particularités de cette machine (Windows 11)

- Ce projet utilise **PHP 8.4 dans `C:\php84`** (avec `pdo_pgsql`). Le `php` du PATH est PHP 8.3 (`C:\php83`), gardé pour les autres projets : appeler `C:\php84\php.exe` explicitement, et Composer par `C:\php84\php.exe C:\composer\composer.phar`.
- Pas d'extension `redis`, `pcntl` ni `posix` sous Windows : Horizon ne tourne que dans Docker, et le PHP local parle à Redis avec `predis` sur le port 6380.
- Le conteneur `api` (profil `full`) est très lent sous Windows à cause du dossier monté (5 à 38 s par requête, mesuré le 2026-11-21) : servir l'API avec `php artisan serve`.
- Docker n'est pas dans le PATH des sessions ouvertes avant son installation : `C:\Program Files\Docker\Docker\resources\bin\docker.exe`. Docker Desktop ne démarre pas tout seul avec Windows.
- `Set-Content -Encoding utf8` de PowerShell 5.1 ajoute un BOM qui casse les fichiers PHP : utiliser l'outil d'édition.
- Les tests ont besoin du conteneur PostgreSQL (déclencheurs et PostGIS) : pas de SQLite.
- Pas de PostgreSQL natif ; le Redis installé est une version 3.0 pour Windows, trop ancienne : utiliser ceux de Docker.
- Disque C: petit (environ 11 Go libres le 2026-11-21 après nettoyage des caches) : vérifier l'espace avant toute installation ou tout téléchargement d'image. Une première compilation Android demande environ 4 Go libres (Gradle 9.3.1, caches, sortie de 200 Mo par application) ; le disque s'est rempli le 2026-11-22. Supprimés ce jour-là avec l'accord du propriétaire : NDK 29, émulateur Android, Gradle 8.14 et 9.0. Il n'y a donc plus d'émulateur : les essais se font sur téléphone.
- Sur cette machine, une requête d'API prend 0,2 à 3 s (démarrage de Laravel environ 1 s, hachage 0,4 s), et plusieurs secondes après une longue inactivité : c'est le poste de développement, pas un défaut de l'application.
- Flutter dans `C:\flutter` (3.47.2), FVM disponible, SDK Android et JDK 17 présents. Pas de compilation iOS possible sur cette machine.
- Dans les heredocs Bash, les antislashs sont avalés : écrire les fichiers PHP avec l'outil d'écriture, pas par heredoc.
