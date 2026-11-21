# Schéma de base de données — proposition (cadrage)

Statut : **proposition à valider**. Dérivé de la section 9 du cahier des charges (CDC-2026-NDC-01 v1.0), complété par ce que les sections 3 à 7 et 10 imposent. Les tables ou colonnes qui ne figurent pas mot pour mot dans la section 9 sont justifiées par un renvoi (ex. « §5 »).

## Conventions

| Sujet | Règle |
| --- | --- |
| Clés primaires | ULID (`char(26)`) sur toutes les tables métier : non devinables, et générables côté mobile pour la synchronisation hors ligne |
| Dates | `timestamptz` en UTC ; affichage en `Africa/Casablanca` |
| Montants | Entiers en centimes de dirham (`amount` = 15000 pour 150,00 MAD), devise `MAD` |
| Textes traduisibles | `jsonb` `{"fr": "...", "ar": "...", "en": "..."}` (ajout de l'amazigh sans migration) |
| Géographie | PostGIS `geography(Point, 4326)` et `geography(MultiPolygon, 4326)`, index GiST |
| 🔒 | Champ chiffré au niveau applicatif (cast `encrypted` de Laravel, clé dans `.env`) |
| Suppression | `deleted_at` (suppression logique) sur les comptes, profils et contenus ; les données de santé suivent la procédure de suppression loi 09-08 |
| Statuts | Colonnes `varchar` adossées à des enums PHP (pas d'enum PostgreSQL, pour évoluer sans migration lourde) |

## 1. Identité et accès

**users** — Utilisateur (§9)
`id`, `phone` (E.164, unique), `phone_verified_at`, `name`, `email` (nullable), `locale` (fr/ar/en), `status` (active, suspended, deleted), `password` (nullable, back-office uniquement, haché), `two_factor_secret` 🔒, `two_factor_recovery_codes` 🔒, `two_factor_confirmed_at`, `last_login_at`, horodatage, `deleted_at`

**roles, permissions, model_has_roles, model_has_permissions, role_has_permissions** — tables de `spatie/laravel-permission`. Six rôles : `patient`, `proche`, `professionnel`, `coordinateur`, `administrateur`, `comptable` (§2). Un utilisateur peut cumuler patient et proche.

**otp_codes** — codes OTP (§4, §10)
`id`, `phone`, `code_hash`, `purpose` (login, phone_change), `attempts`, `expires_at`, `consumed_at`, `ip`, `created_at`

**personal_access_tokens** — jetons Sanctum, avec `expires_at`.

**devices** — appareils pour le push (§8 FCM)
`id`, `user_id`, `app` (patient, pro), `platform` (ios, android), `fcm_token`, `locale`, `last_seen_at`

**consents** — consentements datés et conservés (§3)
`id`, `user_id`, `patient_profile_id` (nullable), `type` (cgu, privacy, health_data), `document_version`, `accepted_at`, `ip`, `user_agent`, `revoked_at`

**data_requests** — droits d'accès, de rectification et de suppression (§3)
`id`, `user_id`, `type` (access, rectification, deletion), `status` (open, in_progress, done, rejected), `details`, `handled_by`, `handled_at`

## 2. Patients et adresses

**patient_profiles** — Profil patient (§9)
`id`, `user_id` (titulaire du compte), `relationship` (self, parent, child, spouse, other), `first_name`, `last_name`, `birth_date`, `sex`, `phone` (nullable), `care_notes` 🔒 (informations utiles au soin), `default_address_id`, horodatage, `deleted_at`

**addresses** — Adresse (§9)
`id`, `user_id`, `patient_profile_id` (nullable), `label`, `line`, `city`, `location` (Point), `access_notes` (repères d'accès), `zone_id` (nullable, calculé par `ST_Covers` à l'enregistrement), horodatage

**zones** — Zone (§9)
`id`, `name` (jsonb), `slug`, `boundary` (MultiPolygon), `is_active`, `sort`, horodatage

## 3. Catalogue et tarifs

**professional_categories** — catégories paramétrables (§2)
`id`, `code`, `name` (jsonb), `has_order` (inscription à un Ordre exigée), `required_document_types` (jsonb), `is_active`

**specialties** — `id`, `professional_category_id`, `name` (jsonb), `is_active`

**service_categories** — `id`, `name` (jsonb), `slug`, `icon`, `sort`, `is_active`

**services** — Service (§9)
`id`, `service_category_id`, `professional_category_id` (catégorie exigée), `specialty_id` (nullable), `name` (jsonb), `slug`, `description` (jsonb), `duration_minutes`, `base_price`, `requires_prescription`, `allows_series`, `is_active`, `sort`

**surcharges** — majorations nuit, jour férié, distance (§6)
`id`, `type` (night, holiday, distance), `name` (jsonb), `mode` (percent, fixed), `value`, `config` (jsonb : plage horaire de nuit, seuil et prix au km), `is_active`

**holidays** — `id`, `date`, `name` (jsonb) (saisis par l'administrateur, les fêtes religieuses étant mobiles)

**settings** — paramètres de gestion (§4, §5)
`key`, `value` (jsonb). Exemples : délai d'annulation gratuite, frais d'annulation, délai avant escalade à la coordination, délai de réponse du professionnel, taux de commission.

## 4. Professionnels

**professionals** — Professionnel (§9)
`id`, `user_id` (unique), `professional_category_id`, `verification_status` (draft, submitted, under_review, verified, rejected, suspended), `verified_at`, `verified_by`, `suspension_reason`, `license_number`, `order_number`, `is_online`, `last_location` (Point), `last_location_at`, `rating_avg`, `rating_count`, `payout_details` 🔒, horodatage

**professional_specialty**, **professional_zone** — tables pivot (spécialités, zones couvertes)

**availabilities** — agenda hebdomadaire (§5)
`id`, `professional_id`, `weekday` (0–6), `start_time`, `end_time`

**professional_documents** — Justificatif (§9)
`id`, `professional_id`, `type` (identity, diploma, practice_authorization, order_registration, rc_insurance), `file_id`, `expires_at`, `status` (pending, approved, rejected, expired), `reviewed_by`, `reviewed_at`, `rejection_reason`

**document_reviews** — historique des contrôles (§3)
`id`, `professional_document_id`, `reviewer_id`, `decision`, `comment`, `created_at`

Règle (§5) : un professionnel reçoit des missions seulement si `verification_status = verified` et si son assurance RC est approuvée et non expirée. Une tâche planifiée quotidienne fait expirer les justificatifs et alerte la coordination.

## 5. Fichiers

**files** — tous les fichiers (ordonnances, justificatifs, photos, signatures, reçus)
`id`, `disk`, `path`, `category` (prescription, professional_document, report_photo, signature, receipt, banner…), `mime`, `size`, `sha256`, `is_encrypted`, `key_version`, `owner_type` + `owner_id` (polymorphe), `uploaded_by`, horodatage

Les fichiers de santé sont chiffrés par l'application avant l'envoi vers le stockage S3, jamais exposés par URL publique, et servis par l'API après contrôle des droits et écriture dans le journal d'accès.

## 6. Réservations

**booking_series** — Série (§9)
`id`, `user_id`, `patient_profile_id`, `service_id`, `address_id`, `frequency` (daily, every_n_days, weekly), `interval`, `weekdays` (jsonb), `time_of_day`, `starts_on`, `ends_on`, `occurrences`, `preferred_professional_id` (nullable), `status` (active, cancelled, completed)

**bookings** — Réservation (§9)
`id`, `reference` (lisible, ex. `NC-2026-000123`), `user_id` (demandeur), `patient_profile_id`, `address_id`, `address_snapshot` (jsonb), `service_id`, `professional_id` (nullable), `series_id` (nullable), `series_index`, `channel` (app, web, phone, whatsapp), `created_by` (coordinateur en saisie téléphonique), `type` (immediate, scheduled), `scheduled_at`, `scheduled_end_at`, `status`, `base_price`, `surcharges_total`, `total_price`, `price_snapshot` (jsonb), `payment_method` (cash, card), `patient_note` 🔒, `prescription_file_id` (nullable), `escalated_at`, `cancelled_by`, `cancellation_reason`, `cancellation_fee`, horodatage

**booking_surcharges** — `booking_id`, `surcharge_id`, `label`, `amount`

**booking_status_history** — chaque changement horodaté et attribué (§9)
`id`, `booking_id`, `from_status`, `to_status`, `actor_id`, `actor_role`, `reason`, `meta` (jsonb), `created_at`

**booking_offers** — propositions de mission et délai de réponse (§5, §6)
`id`, `booking_id`, `professional_id`, `status` (pending, accepted, declined, expired, cancelled), `source` (auto, coordinator), `offered_by`, `score`, `distance_m`, `sent_at`, `expires_at`, `responded_at`, `decline_reason`. Index unique partiel : une seule offre acceptée par réservation.

### Statuts d'une réservation

| Code | Libellé CDC | Sens proposé |
| --- | --- | --- |
| `pending` | En attente | Demande créée, en attente de validation par un coordinateur |
| `confirmed` | Confirmée | Demande validée, recherche d'un professionnel en cours |
| `assigned` | Affectée | Un professionnel a accepté, ou le coordinateur l'a désigné |
| `en_route` | En route | Le professionnel est parti ; partage de position actif |
| `in_progress` | En cours | Arrivée pointée au domicile |
| `completed` | Terminée | Fin pointée et compte rendu validé |
| `cancelled` | Annulée | Annulée par le patient, le proche ou la coordination |
| `disputed` | En litige | Réclamation ouverte sur la réservation |

Transitions autorisées :

```
pending      → confirmed | cancelled
confirmed    → assigned | cancelled
assigned     → en_route | confirmed (désistement, réaffectation) | cancelled
en_route     → in_progress | confirmed (réaffectation) | cancelled (avec frais)
in_progress  → completed | disputed
completed    → disputed
cancelled    → disputed (frais contestés)
disputed     → completed | cancelled
```

Toute transition passe par une machine à états unique côté API, qui vérifie le rôle de l'auteur, écrit dans `booking_status_history` et émet l'événement temps réel. Aucune écriture directe de `status` ailleurs.

Décision du 2026-11-21 : la transition `pending → confirmed` est réservée au coordinateur et à l'administrateur. Le système ne confirme jamais seul.

## 7. Interventions et comptes rendus

**interventions** — Intervention (§9), une par réservation réalisée
`id`, `booking_id` (unique), `professional_id`, `arrived_at`, `arrival_location` (Point), `ended_at`, `end_location` (Point), `status` (in_progress, report_pending, validated), horodatage

**acts** — référentiel d'actes : `id`, `name` (jsonb), `is_active` ; pivot **service_act**
**intervention_acts** — `intervention_id`, `act_id` (nullable), `label`, `quantity`

**consumables** — référentiel : `id`, `name` (jsonb), `unit`, `is_active`
**intervention_consumables** — `intervention_id`, `consumable_id` (nullable), `label`, `quantity`

**intervention_reports** — compte rendu et avenants (§5)
`id`, `intervention_id`, `version` (1 = original, 2+ = avenant), `parent_report_id` (nullable), `vitals` 🔒 (jsonb : tension, pouls, température, glycémie, saturation), `observations` 🔒, `signature_file_id`, `signed_by_name`, `signed_at`, `author_id`, `amendment_reason` (nullable), `content_hash`, `client_created_at` (saisie hors ligne), `validated_at`, `created_at`

Les photos du compte rendu sont des lignes de `files`. Un compte rendu validé est immuable : un déclencheur PostgreSQL refuse toute modification, et une correction crée une nouvelle version.

**location_pings** — position pendant le trajet uniquement (§5)
`id`, `booking_id`, `professional_id`, `location` (Point), `accuracy_m`, `recorded_at`. Acceptés seulement quand la réservation est `en_route` ; purgés après un délai paramétrable.

## 8. Paiements et reversements

**payments** — Paiement (§9)
`id`, `booking_id`, `method` (cash, card), `provider` (cash, fake, puis le fournisseur retenu), `status` (pending, authorized, paid, failed, cancelled, refunded, partially_refunded), `amount`, `currency`, `provider_reference`, `provider_payload` 🔒 (jsonb), `idempotency_key` (unique), `collected_by` (professionnel, pour les espèces), `paid_at`, `receipt_number`, `receipt_file_id`, horodatage

**refunds** — `id`, `payment_id`, `amount`, `reason`, `status`, `provider_reference`, `created_by`, horodatage

**payment_events** — notifications du fournisseur de paiement
`id`, `provider`, `event_id` (unique, pour l'idempotence), `payload` 🔒, `processed_at`, `created_at`

**ledger_entries** — grand livre par professionnel (§5 « solde dû à la plateforme »)
`id`, `professional_id`, `booking_id`, `payment_id`, `type` (earning, commission, cash_collected, cancellation_fee, payout, adjustment), `amount` (signé), `payout_id` (nullable), `created_at`. En insertion seule ; le solde est la somme des lignes.

**payouts** — Reversement (§9)
`id`, `professional_id`, `period_start`, `period_end`, `gross_amount`, `commission_amount`, `net_amount`, `status` (draft, validated, paid, cancelled), `method`, `reference`, `validated_by`, `paid_at`, horodatage

Le grand livre est volontairement neutre : il fonctionne que la plateforme prélève une commission, une marge ou un abonnement. Les règles d'écriture dépendent des questions 2 et 4.

## 9. Évaluations, réclamations, messagerie

**reviews** — Évaluation (§9)
`id`, `intervention_id` (unique), `author_id`, `professional_id`, `rating` (1–5), `comment`, `is_published`, `moderated_by`, horodatage

**complaints** — signalements et réclamations (§4, §6)
`id`, `booking_id` (nullable), `user_id`, `type`, `description` 🔒, `status` (open, in_progress, resolved, rejected), `assigned_to`, `resolution`, horodatage

**conversations** — `id`, `user_id`, `booking_id` (nullable), `status` (open, closed), `assigned_to`, `last_message_at`
**messages** — `id`, `conversation_id`, `sender_id`, `body` 🔒, `file_id` (nullable), `read_at`, `created_at`

## 10. Notifications et contenus

**notification_templates** — modèles éditables (§6)
`id`, `key`, `channel` (push, sms, whatsapp), `body` (jsonb par langue), `is_active`

**notification_logs** — `id`, `user_id`, `booking_id` (nullable), `channel`, `template_key`, `recipient`, `status` (queued, sent, delivered, failed), `provider_message_id`, `error`, `sent_at`

**pages**, **faqs**, **banners**, **posts** — contenus du site et de l'application (§6, §7), champs traduisibles en jsonb, `is_published`, `published_at`

**professional_applications** — candidatures du site (§7) : `id`, `name`, `phone`, `professional_category_id`, `city`, `message`, `file_id`, `status`, horodatage

**contact_messages** — `id`, `name`, `phone`, `email`, `message`, `handled_at`, `created_at`

## 11. Traçabilité

**access_logs** — Journal d'accès (§9, §3)
`id`, `actor_id`, `actor_role`, `action` (view, download, create, update, export), `subject_type`, `subject_id`, `patient_profile_id`, `booking_id` (mission qui justifie l'accès), `ip`, `user_agent`, `route`, `created_at`. En insertion seule : un déclencheur refuse `UPDATE` et `DELETE`.

**audit_logs** — journal des actions sensibles du back-office (§6)
`id`, `actor_id`, `event`, `auditable_type`, `auditable_id`, `old_values`, `new_values` (champs sensibles masqués), `ip`, `created_at`

**idempotency_keys** — rejeu sûr des requêtes (synchronisation hors ligne, paiement)
`key`, `user_id`, `request_hash`, `response` (jsonb), `created_at`

Tables techniques Laravel : `jobs`, `job_batches`, `failed_jobs`, `notifications`.

## Cloisonnement par mission

Un professionnel lit le profil patient, l'adresse, l'ordonnance, la note du patient et `care_notes` seulement s'il est le professionnel affecté d'une réservation au statut `assigned`, `en_route` ou `in_progress` (plus une fenêtre paramétrable après `completed` pour finir le compte rendu). La règle vit dans les policies Laravel, pas dans les contrôleurs, et chaque lecture écrit une ligne dans `access_logs`. Avant l'acceptation, l'offre de mission ne montre que le service, le créneau, la zone et la distance.

## Hors schéma (V2, non créé)

Dossier de suivi des constantes dans le temps, abonnements, téléconsultation, note de transmission entre soignants, bouton d'alerte, codes promotionnels, comptes entreprises.
