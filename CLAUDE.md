# Nador Care

Plateforme de coordination de soins à domicile à Nador (Maroc) : application patient, application professionnel, back-office web, site public, API commune.

## Source de vérité

`Cahier des charges — Plateforme Nador Care (Web + App mobile).md` (CDC-2026-NDC-01 v1.0), à la racine. Tout développement en découle. Si un point est ambigu ou absent : poser la question, ne pas supposer. Les questions ouvertes et les décisions prises sont dans `docs/03-questions-ouvertes.md`.

## État du projet

- Étape 1 (cadrage) : validée le 2026-11-21.
- Étape 2 (socle technique, lot 3) : en cours. Avancement tâche par tâche dans `docs/02-decoupage-lots.md`.
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

`/api/app` s'organise par domaine métier (Auth, Patients, Catalogue, Professionals, Bookings, Interventions, Payments, Notifications, Content, Audit). Les contrôleurs d'API et les ressources Filament appellent les mêmes classes d'action ; aucune règle métier dans un contrôleur ou une ressource Filament.

`/mobile/packages` : `core` (modèles, erreurs), `api_client`, `design_system`, `l10n`, `offline` (Drift, file de synchronisation).

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

## Commandes utiles (cible, à confirmer à l'étape 2)

```powershell
# Services
docker compose up -d
docker compose exec api php artisan migrate:fresh --seed

# API (dans /api)
composer test          # tests
composer lint          # Pint
composer analyse       # Larastan
php artisan horizon
php artisan reverb:start

# Mobile (dans /mobile)
flutter pub get
flutter analyze
flutter test
flutter run -t apps/patient/lib/main.dart
flutter run -t apps/pro/lib/main.dart

# Site (dans /web)
pnpm install
pnpm dev
pnpm build
```

## Particularités de cette machine (Windows 11)

- Ce projet utilise **PHP 8.4 dans `C:\php84`** (avec `pdo_pgsql`). Le `php` du PATH est PHP 8.3 (`C:\php83`), gardé pour les autres projets : appeler `C:\php84\php.exe` explicitement, et Composer par `C:\php84\php.exe C:\composer\composer.phar`.
- Pas d'extension `redis`, `pcntl` ni `posix` sous Windows : Horizon ne tourne que dans Docker.
- Pas de PostgreSQL natif ; le Redis installé est une version 3.0 pour Windows, trop ancienne : utiliser ceux de Docker.
- Disque C: petit (environ 11 Go libres le 2026-11-21 après nettoyage des caches) : vérifier l'espace avant toute installation ou tout téléchargement d'image.
- Flutter dans `C:\flutter` (3.47.2), FVM disponible, SDK Android et JDK 17 présents. Pas de compilation iOS possible sur cette machine.
- Dans les heredocs Bash, les antislashs sont avalés : écrire les fichiers PHP avec l'outil d'écriture, pas par heredoc.
