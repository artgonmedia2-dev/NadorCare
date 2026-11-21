# Nador Care

Plateforme de coordination de soins à domicile à Nador (Maroc) : application patient, application professionnel, back-office web, site public, API commune.

## Source de vérité

`Cahier des charges — Plateforme Nador Care (Web + App mobile).md` (CDC-2026-NDC-01 v1.0), à la racine. Tout développement en découle. Si un point est ambigu ou absent : poser la question, ne pas supposer. Les questions ouvertes et les décisions prises sont dans `docs/03-questions-ouvertes.md`.

## État du projet

- Étape 1 (cadrage) : validée le 2026-11-21.
- Étape 2 (socle technique, lot 3) : livrée le 2026-11-21 (avancement en tête de `docs/02-decoupage-lots.md`). Reste du lot 3 reporté au lot 6 : écrans Filament de gestion des utilisateurs, des rôles et des journaux.
- Lot 4 : tâches 4.0 (socle Flutter), 4.1 (compte) et 4.2 (profils de patients, adresses) livrées le 2026-11-21. Jamais compilé ni lancé sur un appareil : à faire avant d'aller plus loin côté mobile.
- Suite des lots 4 à 7 : en attente des points à trancher (`docs/03-questions-ouvertes.md`, sections B et C).
- Dépôt : `https://github.com/artgonmedia2-dev/NadorCare.git`, branche `main`.

## Décisions structurantes

- Paiement carte : **Payzone** (le cahier des charges dit CMI, la décision du 2026-11-21 prime).
- Une réservation passe de `pending` à `confirmed` uniquement par un coordinateur ou un administrateur.
- Filament vit dans l'application Laravel et appelle les mêmes classes d'action que l'API, sans passer par HTTP.
- PHP 8.4 partout.

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
- `lang/{fr,ar,en}/api.php` : tous les textes renvoyés par l'API.

Points d'entrée obligatoires :

- lire les données de santé d'un patient : `ReadPatientRecord` (vérifie le droit, journalise) ;
- lire ou écrire un fichier privé : `EncryptedFileStore` ;
- changer le statut d'une réservation : `TransitionBooking` ;
- renvoyer une erreur métier : `ApiException('code')`, avec le texte dans `lang/*/api.php`.

Organisation de `/mobile` (espace de travail pub, voir `mobile/README.md`) :

- `apps/patient`, `apps/pro` : un `main.dart` et les écrans propres à chaque application. Tout le reste est partagé.
- `packages/nc_core` (modèles, `ApiFailure`, `AppConfig`), `nc_api_client` (Dio, épinglage), `nc_l10n` (ARB fr/ar/en), `nc_design_system` (thème et composants provisoires), `nc_account` (connexion OTP, consentement, réglages, biométrie, enveloppe `NadorCareApp` et routes communes).
- Le paquet `offline` (Drift, file de synchronisation) reste à créer avec la tâche 5.7.

Règles mobiles :

- aucun texte en dur : `context.l10n.cle`, clés dans `nc_l10n/lib/src/arb`, puis `flutter gen-l10n` (les fichiers générés sont commités et vérifiés par la CI) ;
- les écrans n'utilisent que les composants de `nc_design_system` (`NcPage`, `NcPrimaryButton`, `NcNotice`) et des marges directionnelles, pour l'arabe ;
- le jeton vit dans le stockage sécurisé (`SecureSessionStorage`), jamais dans les préférences ;
- les erreurs d'API arrivent en `ApiFailure` ; le message du serveur est déjà traduit, `failureMessage()` le choisit ;
- les numéros de téléphone et les codes s'affichent toujours de gauche à droite.

## Règles non négociables

1. **Données de santé (loi 09-08).** Champs sensibles chiffrés (cast `encrypted`), fichiers chiffrés avant stockage, accès cloisonné par mission (policy), chaque accès écrit dans `access_logs`. Jamais de donnée de santé dans les journaux applicatifs, les messages d'erreur, les notifications push ou Sentry.
2. **Aucun secret dans le code.** Tout passe par `.env` ; `.env.example` mis à jour dans le même commit que toute nouvelle variable.
3. **Services externes derrière des interfaces** (SMS, WhatsApp, paiement carte, push, cartographie, stockage), avec une implémentation factice pour le développement et les tests. Le pilote se choisit par `.env`. Les contrats ne sont pas signés.
4. **Trois langues dès le départ** : français, arabe (RTL), anglais. Aucun texte en dur dans un écran, un e-mail, un SMS ou une réponse d'API.
5. **Tests automatisés** sur les parcours critiques : authentification, réservation, affectation, paiement, compte rendu.
6. **Commits petits et descriptifs**, une fonctionnalité à la fois.
7. **Aucune fonctionnalité V2** : dossier de suivi, abonnements, téléconsultation, note de transmission, bouton d'alerte, codes promotionnels, comptes entreprises, mode sombre.
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
cd packages\nc_account; flutter test          # idem dans packages\nc_api_client et apps\patient
cd packages\nc_l10n; flutter gen-l10n         # après toute modification d'un fichier .arb
cd apps\patient; flutter run                  # ou apps\pro ; API vue par l'émulateur sur 10.0.2.2:8000

# Site (dans /web) : commandes cibles, le projet n'existe pas encore
pnpm install
pnpm dev
pnpm build
```

## Particularités de cette machine (Windows 11)

- Ce projet utilise **PHP 8.4 dans `C:\php84`** (avec `pdo_pgsql`). Le `php` du PATH est PHP 8.3 (`C:\php83`), gardé pour les autres projets : appeler `C:\php84\php.exe` explicitement, et Composer par `C:\php84\php.exe C:\composer\composer.phar`.
- Pas d'extension `redis`, `pcntl` ni `posix` sous Windows : Horizon ne tourne que dans Docker, et le PHP local parle à Redis avec `predis` sur le port 6380.
- Le conteneur `api` (profil `full`) est très lent sous Windows à cause du dossier monté (5 à 38 s par requête, mesuré le 2026-11-21) : servir l'API avec `php artisan serve`.
- Docker n'est pas dans le PATH des sessions ouvertes avant son installation : `C:\Program Files\Docker\Docker\resources\bin\docker.exe`. Docker Desktop ne démarre pas tout seul avec Windows.
- `Set-Content -Encoding utf8` de PowerShell 5.1 ajoute un BOM qui casse les fichiers PHP : utiliser l'outil d'édition.
- Les tests ont besoin du conteneur PostgreSQL (déclencheurs et PostGIS) : pas de SQLite.
- Pas de PostgreSQL natif ; le Redis installé est une version 3.0 pour Windows, trop ancienne : utiliser ceux de Docker.
- Disque C: petit (environ 11 Go libres le 2026-11-21 après nettoyage des caches) : vérifier l'espace avant toute installation ou tout téléchargement d'image.
- Flutter dans `C:\flutter` (3.47.2), FVM disponible, SDK Android et JDK 17 présents. Pas de compilation iOS possible sur cette machine.
- Dans les heredocs Bash, les antislashs sont avalés : écrire les fichiers PHP avec l'outil d'écriture, pas par heredoc.
