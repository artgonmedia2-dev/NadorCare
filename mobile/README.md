# Applications mobiles Nador Care

Un seul espace de travail Flutter produit deux applications qui partagent leurs paquets.

| Dossier | Rôle |
| --- | --- |
| `apps/patient` | Application patient (`ma.nadorcare.patient`) |
| `apps/pro` | Application professionnel (`ma.nadorcare.pro`) |
| `packages/nc_core` | Modèles, erreurs, configuration |
| `packages/nc_api_client` | Client de l'API `/api/v1`, épinglage de certificat |
| `packages/nc_l10n` | Textes en français, arabe et anglais |
| `packages/nc_design_system` | Thème et composants (provisoires, en attendant les maquettes) |
| `packages/nc_account` | Connexion OTP, consentement, langue, taille du texte, biométrie, réglages, enveloppe d'application |

## Commandes

```powershell
cd mobile
flutter pub get
flutter analyze

# Tests
cd packages\nc_api_client; flutter test
cd ..\nc_account;          flutter test
cd ..\..\apps\patient;     flutter test

# Lancer une application (l'API locale doit tourner, voir le README à la racine)
cd apps\patient
flutter run                                                      # émulateur Android : API sur 10.0.2.2:8000
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1   # téléphone sur le même Wi-Fi
```

Pour un téléphone réel, servir l'API avec `php artisan serve --host=0.0.0.0`.

## Ajouter un texte

Aucun texte ne s'écrit dans un écran. Ajouter la clé dans `packages/nc_l10n/lib/src/arb/app_fr.arb`, la traduire dans `app_ar.arb` et `app_en.arb`, puis :

```powershell
cd packages\nc_l10n
flutter gen-l10n
```

Dans un écran : `context.l10n.maCle`.

## Configuration à la compilation

| Variable `--dart-define` | Rôle | Par défaut |
| --- | --- | --- |
| `API_BASE_URL` | Adresse de l'API | `http://10.0.2.2:8000/api/v1` |
| `API_CERT_SHA256` | Empreintes SHA-256 des certificats acceptés, séparées par des virgules. Active l'épinglage. | vide (développement) |

Le HTTP en clair n'est autorisé que dans la version de développement Android. La version publiée exige HTTPS.
