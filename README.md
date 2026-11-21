# Nador Care

Plateforme de coordination de soins à domicile à Nador : application patient, application professionnel, back-office, site public et API commune.

Le cahier des charges est à la racine du dépôt. Le cadrage (schéma, découpage en tâches, décisions) est dans [docs/](docs/).

## Contenu du dépôt

| Dossier | Contenu | État |
| --- | --- | --- |
| `api/` | API Laravel `/api/v1`, back-office Filament, files d'attente, temps réel | Socle technique en place |
| `mobile/` | Applications Flutter patient et professionnel ([mobile/README.md](mobile/README.md)) | Socle et écrans de compte en place |
| `web/` | Site public Next.js | À venir (lot 7) |
| `docs/` | Cadrage, schéma de base de données, `openapi.json` | À jour |
| `docker/` | Image PHP et initialisation de PostgreSQL | En place |

## Démarrer l'API en local

Prérequis : Docker Desktop, PHP 8.4 avec `pdo_pgsql`, Composer.

```powershell
# 1. Services : PostgreSQL + PostGIS, Redis, Horizon, Reverb, planificateur
docker compose up -d

# 2. API
cd api
composer install --ignore-platform-req=ext-pcntl --ignore-platform-req=ext-posix   # Windows uniquement
copy .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

Sous Windows, le serveur HTTP tourne en natif (`php artisan serve`) parce qu'un dossier monté dans Docker rend chaque requête très lente. Sous Linux ou macOS, `docker compose --profile full up -d` lance aussi l'API dans un conteneur.

| Adresse | Contenu |
| --- | --- |
| http://localhost:8000/api/v1/health | État de l'API |
| http://localhost:8000/docs/api | Documentation OpenAPI interactive |
| http://localhost:8000/admin | Back-office |
| http://localhost:8000/horizon | Files d'attente |

### Se connecter

- **Applications (OTP)** : `POST /api/v1/auth/otp/request` avec un numéro. Tant qu'aucune passerelle SMS n'est branchée, le code s'affiche dans `api/storage/logs/laravel.log` (ligne « SMS factice »). On peut aussi fixer `OTP_STATIC_CODE` dans `.env`, hors production.
- **Back-office** : `php artisan nadorcare:create-staff` crée un compte coordinateur, administrateur ou comptable. Le double facteur est demandé à la première connexion.

## Contrôles

```powershell
cd api
composer test      # tests (PostgreSQL de Docker requis)
composer lint      # formatage
composer analyse   # analyse statique
composer openapi   # régénère docs/openapi.json
```

L'intégration continue (GitHub Actions) rejoue ces quatre contrôles à chaque envoi.

## Services externes

SMS, WhatsApp, notifications push, paiement par carte (Payzone) et cartographie sont derrière des interfaces (`api/app/Contracts`). Seules des implémentations factices existent pour l'instant ; le pilote se choisit dans `.env` (`SMS_DRIVER`, `PAYMENT_DRIVER`…).
