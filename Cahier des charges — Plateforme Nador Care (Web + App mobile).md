# Cahier des charges — Plateforme Nador Care (Web + App mobile)

Nov 21, 2026 · @Artgon MEDIA

## 1. Contexte, objectifs et périmètre

Nador Care met en relation des patients de Nador et de sa région avec des professionnels de santé autorisés qui interviennent à domicile, via une application mobile, un site web et un back-office de coordination. Référence du document : CDC-2026-NDC-01, version 1.0.

**Objectifs**

- Permettre à un patient ou à un proche de réserver un soin à domicile en moins de 2 minutes.
- Donner aux professionnels un outil simple pour recevoir, planifier et tracer leurs interventions.
- Donner à la coordination une vue en temps réel des demandes, des affectations et des paiements.
- Servir la diaspora (MRE) qui réserve et paie à distance pour un parent resté à Nador.

**Périmètre**

| Composant | Support | Utilisateurs |
| --- | --- | --- |
| App patient | iOS, Android | Patients, proches |
| App professionnel | iOS, Android | Médecins, infirmiers, kinésithérapeutes, aides-soignants, autres |
| Back-office | Web | Coordinateurs, administrateurs, comptabilité |
| Site public | Web | Visiteurs, patients sans application |
| API | Serveur | Les quatre composants ci-dessus |

**Hors périmètre de la version 1** : téléconsultation vidéo, vente de médicaments, transport sanitaire, facturation directe aux mutuelles et à l'AMO.

**Zone de lancement** : ville de Nador, puis extension aux communes voisines par zones configurables dans le back-office.

## 2. Acteurs et rôles

La plateforme compte six rôles, chacun avec des droits distincts gérés par un système de permissions.

| Rôle | Accès | Actions principales |
| --- | --- | --- |
| Patient | App patient, site | Réserver, payer, suivre l'intervention, consulter son historique, évaluer |
| Proche (aidant, MRE) | App patient, site | Gérer un ou plusieurs profils de patients, réserver et payer pour eux |
| Professionnel de santé | App professionnel | Publier ses disponibilités, accepter une mission, se rendre sur place, rédiger le compte rendu |
| Coordinateur | Back-office | Valider les demandes, affecter un professionnel, gérer les urgences et les réclamations |
| Administrateur | Back-office | Gérer les comptes, le catalogue, les tarifs, les zones, les contenus et les statistiques |
| Comptable | Back-office | Suivre les encaissements, les reversements aux professionnels et les exports |

**Catégories de professionnels gérées** : médecin généraliste, médecin spécialiste, infirmier, kinésithérapeute, orthophoniste, psychomotricien, sage-femme, aide-soignant et auxiliaire de vie. La liste est paramétrable sans développement.

## 3. Cadre légal et conformité

La plateforme est conçue comme un outil de coordination : les actes de soins sont réalisés par des professionnels indépendants, chacun titulaire de sa propre autorisation d'exercice. Ce choix conditionne plusieurs fonctionnalités et doit être validé par un juriste avant le développement.

**Vérification des professionnels (obligatoire avant activation du compte)**

- Pièce d'identité, diplôme et autorisation d'exercice dans le secteur privé.
- Inscription à l'Ordre concerné lorsque la profession en a un.
- Attestation d'assurance responsabilité civile professionnelle, avec date d'expiration suivie par le système.
- Validation manuelle par un administrateur, avec historique des contrôles.

**Textes à respecter**

| Texte | Objet | Conséquence pour la plateforme |
| --- | --- | --- |
| Loi 131-13 | Exercice de la médecine | Le médecin intervient en son nom ; la plateforme ne facture pas d'acte médical à sa place sans cadre validé |
| Loi 43-13 | Professions infirmières | Même logique pour les soins infirmiers |
| Loi 45-13 | Rééducation et réadaptation | Même logique pour kinésithérapeutes, orthophonistes, psychomotriciens |
| Loi 09-08 | Protection des données personnelles | Les données de santé sont sensibles : démarche auprès de la CNDP avant la mise en production |

**Exigences issues de la loi 09-08**

- Consentement explicite du patient à la création du compte, daté et conservé.
- Droits d'accès, de rectification et de suppression accessibles depuis l'application.
- Accès au dossier limité au professionnel affecté à l'intervention, pour la durée nécessaire.
- Journal de tous les accès aux données de santé.
- Lieu d'hébergement à valider avec la CNDP, en privilégiant un hébergement au Maroc.

**Mentions à afficher** : conditions générales, politique de confidentialité, et un message clair indiquant que le service ne remplace pas les urgences vitales (renvoi vers le 141 et le 15).

## 4. Application mobile patient

Le parcours central tient en cinq écrans : choisir un service, indiquer le patient et l'adresse, choisir un créneau, payer ou confirmer, suivre l'intervention.

| Module | Fonctionnalités | Priorité |
| --- | --- | --- |
| Compte | Inscription par numéro de téléphone et code OTP, connexion biométrique, choix de la langue | MVP |
| Profils de patients | Plusieurs profils par compte (soi-même, parent, enfant), âge, adresse, informations utiles au soignant | MVP |
| Catalogue | Services par catégorie, description, durée, tarif indicatif, recherche | MVP |
| Réservation | Créneau immédiat ou planifié, adresse sur carte, dépôt d'une ordonnance en photo, note pour le soignant | MVP |
| Soins récurrents | Programmation d'une série (exemple : injection chaque jour pendant 10 jours) | MVP |
| Suivi | Statut en temps réel, position du professionnel sur la carte, heure d'arrivée estimée | MVP |
| Paiement | Espèces à domicile, carte bancaire en ligne, reçu en PDF | MVP |
| Notifications | Push, SMS et WhatsApp : confirmation, rappel, arrivée, compte rendu disponible | MVP |
| Historique | Interventions passées, comptes rendus, reçus, nouvelle réservation en un geste | MVP |
| Évaluation | Note et commentaire après chaque intervention, signalement d'un problème | MVP |
| Messagerie | Discussion avec la coordination, appel direct | MVP |
| Dossier de suivi | Constantes relevées dans le temps (tension, glycémie), documents partagés | V2 |
| Abonnements | Forfaits mensuels pour maladies chroniques et personnes âgées | V2 |
| Téléconsultation | Appel vidéo avec un médecin, sous réserve du cadre réglementaire | V2 |

**Règles de gestion**

- Annulation gratuite jusqu'à un délai paramétrable avant le créneau, frais au-delà.
- Une demande sans professionnel disponible passe à la coordination au bout d'un délai paramétrable.
- Un soin soumis à prescription ne peut être confirmé qu'avec une ordonnance déposée.

## 5. Application mobile professionnel

Le professionnel reçoit une mission, l'accepte, s'y rend, la réalise et la clôture avec un compte rendu, le tout utilisable d'une seule main et avec une connexion instable.

| Module | Fonctionnalités | Priorité |
| --- | --- | --- |
| Inscription | Formulaire, dépôt des justificatifs, statut de vérification | MVP |
| Disponibilités | Agenda hebdomadaire, zones couvertes, bascule en ligne / hors ligne | MVP |
| Missions | Réception en push, détails du soin, acceptation ou refus avec délai de réponse | MVP |
| Déplacement | Itinéraire vers le domicile, partage de position pendant le trajet uniquement | MVP |
| Intervention | Pointage d'arrivée et de fin, liste des actes réalisés, consommables utilisés | MVP |
| Compte rendu | Constantes, observations, photos, signature du patient à l'écran | MVP |
| Encaissement | Confirmation du paiement en espèces, solde dû à la plateforme | MVP |
| Revenus | Missions réalisées, montants, reversements reçus, export mensuel | MVP |
| Mode hors ligne | Saisie du compte rendu sans réseau, synchronisation au retour de la connexion | MVP |
| Transmission | Note de passage de relais vers le soignant suivant pour les soins en série | V2 |
| Alerte | Bouton d'alerte vers la coordination en cas d'incident au domicile | V2 |

**Règles de gestion**

- Un compte non vérifié ou dont l'assurance a expiré ne reçoit aucune mission.
- Le professionnel ne voit que les informations du patient nécessaires à la mission en cours.
- Un compte rendu validé n'est plus modifiable ; toute correction crée un avenant tracé.

## 6. Back-office web

Le back-office est le poste de pilotage : il permet à la coordination de traiter chaque demande en quelques clics et à la direction de suivre l'activité.

| Module | Fonctionnalités | Priorité |
| --- | --- | --- |
| Tableau de bord | Demandes du jour, interventions en cours sur carte, alertes, indicateurs clés | MVP |
| Demandes | File d'attente, affectation manuelle ou automatique, réaffectation, annulation | MVP |
| Saisie téléphonique | Création d'une réservation pour un patient qui appelle ou écrit sur WhatsApp | MVP |
| Professionnels | Dossiers, vérification des justificatifs, suspension, alertes d'expiration | MVP |
| Patients | Comptes, profils, historique, réclamations | MVP |
| Catalogue et tarifs | Services, catégories, durées, prix, majorations (nuit, jour férié, distance) | MVP |
| Zones | Découpage géographique sur carte, activation par zone | MVP |
| Finances | Encaissements, commission, reversements aux professionnels, exports comptables | MVP |
| Contenus | Pages du site, FAQ, bannières de l'application, modèles de notification | MVP |
| Rôles et journal | Permissions par rôle, journal des actions sensibles | MVP |
| Statistiques | Volume par service, délai moyen d'affectation, taux d'annulation, satisfaction | MVP |
| Codes promotionnels | Remises, parrainage, offres pour entreprises | V2 |
| Comptes entreprises | Conventions avec mutuelles, cliniques et employeurs | V2 |

**Affectation automatique** : le système propose les professionnels selon la spécialité requise, la zone, la disponibilité, la distance et la note moyenne. Le coordinateur peut toujours forcer un choix.

## 7. Site web public

Le site présente l'offre, capte les demandes venues de Google et permet de réserver sans installer l'application.

- Accueil, pages par service, zones couvertes, tarifs, FAQ, à propos, contact.
- Réservation en ligne avec le même parcours que l'application.
- Page de recrutement des professionnels avec formulaire de candidature.
- Bouton WhatsApp et numéro d'appel visibles sur toutes les pages.
- Blog santé pour le référencement naturel.
- Trois langues : français, arabe (affichage de droite à gauche), anglais.
- Référencement local : données structurées, fiche d'établissement Google, pages par service et par ville.
- Liens vers l'App Store et Google Play.

## 8. Stack technique et architecture

La stack retenue est Flutter pour les deux applications mobiles et Laravel pour l'API et le back-office : un seul code pour iOS et Android, une seule API pour tous les clients, et des technologies déjà maîtrisées par l'équipe.

| Couche | Technologie | Rôle et raison du choix |
| --- | --- | --- |
| Apps mobiles | Flutter (Dart) | Un code unique iOS et Android, bon support de l'arabe et du hors ligne |
| État et stockage local | Riverpod, Drift (SQLite) | Gestion d'état testable, file de synchronisation hors ligne |
| API | Laravel (PHP), REST + JSON, Sanctum | Authentification par jetons, validation, files d'attente, écosystème mature |
| Back-office | Filament (sur Laravel) | Interfaces d'administration rapides à produire, permissions par rôle |
| Site public | Next.js (React) | Rendu côté serveur pour le référencement, trois langues |
| Base de données | PostgreSQL + PostGIS | Requêtes géographiques (zones, distance au professionnel) |
| Cache et files | Redis, Laravel Horizon | Notifications, affectation automatique, tâches planifiées |
| Temps réel | Laravel Reverb (WebSocket) | Statuts d'intervention et position en direct |
| Fichiers | Stockage objet compatible S3, chiffré | Ordonnances, justificatifs, photos, reçus |
| Push | Firebase Cloud Messaging | Notifications iOS et Android |
| SMS et WhatsApp | Passerelle SMS locale, WhatsApp Business Platform | Codes OTP, rappels, confirmations |
| Paiement | CMI (cartes marocaines et internationales) | Paiement en ligne, y compris depuis l'étranger |
| Cartographie | Google Maps Platform | Adresses, itinéraires, heure d'arrivée estimée |
| Supervision | Sentry, journaux centralisés, sonde de disponibilité | Détection des erreurs et des pannes |
| Déploiement | Docker, GitHub Actions | Environnements test, préproduction, production |

**Principes d'architecture**

- L'API est l'unique porte d'entrée : les applications, le site et le back-office passent tous par elle.
- Une seule base de code Flutter produit deux applications (patient, professionnel) qui partagent leurs composants.
- Les traitements lents (notifications, PDF, affectation) passent par des files d'attente.
- L'API est versionnée (`/api/v1`) pour faire évoluer les applications sans casser les anciennes versions.
- Les services externes (SMS, paiement, cartes) sont isolés derrière des interfaces pour pouvoir changer de fournisseur.

## 9. Modèle de données principal

Le modèle s'organise autour de la réservation, qui relie un patient, un service, un professionnel et un paiement.

| Entité | Contenu principal | Liens |
| --- | --- | --- |
| Utilisateur | Téléphone, nom, langue, rôle, statut | Possède des profils de patients ou un profil professionnel |
| Profil patient | Nom, date de naissance, sexe, informations utiles au soin | Appartient à un utilisateur, a des adresses |
| Adresse | Libellé, coordonnées GPS, repères d'accès | Rattachée à une zone |
| Professionnel | Catégorie, spécialités, statut de vérification, note moyenne | Couvre des zones, a des disponibilités et des justificatifs |
| Justificatif | Type, fichier, date d'expiration, statut de contrôle | Appartient à un professionnel |
| Service | Nom, catégorie, durée, prix, prescription requise ou non | Exige une catégorie de professionnel |
| Zone | Nom, polygone géographique, active ou non | Contient des adresses |
| Réservation | Créneau, statut, prix, ordonnance, note du patient | Relie patient, adresse, service, professionnel |
| Série | Fréquence, date de début, date de fin | Regroupe plusieurs réservations |
| Intervention | Heures d'arrivée et de fin, actes, constantes, compte rendu, signature | Une par réservation réalisée |
| Paiement | Montant, mode, statut, référence de transaction | Lié à une réservation |
| Reversement | Période, montant, commission, statut | Lié à un professionnel |
| Évaluation | Note, commentaire | Liée à une intervention |
| Journal d'accès | Qui, quoi, quand, depuis où | Trace les accès aux données de santé |

**Statuts d'une réservation** : en attente, confirmée, affectée, en route, en cours, terminée, annulée, en litige. Chaque changement de statut est horodaté et attribué à son auteur.

## 10. Exigences non fonctionnelles

Les données de santé imposent un niveau de sécurité supérieur à celui d'une application de services classique.

| Domaine | Exigence |
| --- | --- |
| Sécurité des échanges | HTTPS partout, TLS 1.2 minimum, épinglage de certificat dans les applications |
| Sécurité des données | Chiffrement des champs de santé et des fichiers au repos, mots de passe hachés, clés hors du code |
| Authentification | OTP par SMS, double facteur obligatoire au back-office, expiration des sessions |
| Contrôle d'accès | Permissions par rôle, cloisonnement des dossiers par mission, journal des accès |
| Protection applicative | Limitation de débit, protection contre les 10 risques OWASP, test d'intrusion avant lancement |
| Disponibilité | 99,5 % par mois, supervision continue |
| Sauvegardes | Quotidiennes, chiffrées, conservées 30 jours, restauration testée chaque trimestre |
| Performance API | 95 % des réponses en moins de 500 ms |
| Performance mobile | Ouverture en moins de 3 secondes, utilisable sur réseau 3G |
| Compatibilité | Android 8 et plus, iOS 15 et plus, navigateurs récents |
| Langues | Français, arabe (droite à gauche), anglais ; textes externalisés pour ajouter l'amazigh |
| Accessibilité | Grandes polices, contrastes élevés, parcours adapté aux personnes âgées |
| Montée en charge | 10 000 utilisateurs et 500 interventions par jour sans changement d'architecture |
| Qualité du code | Tests automatisés sur les parcours critiques, revue de code, documentation de l'API (OpenAPI) |

## 11. Design UX/UI

L'interface doit inspirer confiance et rester utilisable par une personne âgée ou peu à l'aise avec le numérique.

- Identité visuelle Nador Care à créer : logo, palette, typographies latine et arabe, icônes.
- Design system commun aux applications, au site et au back-office, livré sous Figma.
- Parcours de réservation en cinq étapes au maximum, avec un seul choix par écran.
- Textes courts, boutons larges, taille de police réglable.
- Maquettes complètes en français et en arabe, avec mise en page inversée pour l'arabe.
- Mode clair en version 1, mode sombre en version 2.
- Prototype cliquable testé avec au moins cinq patients et trois professionnels avant le développement.

## 12. Lots et planning

La version 1 (MVP) est estimée à environ 20 semaines, de la conception à la publication sur les stores. Les durées sont des estimations à confirmer après validation du périmètre.

| Lot | Contenu | Durée estimée |
| --- | --- | --- |
| 1. Cadrage | Ateliers, validation juridique du modèle, spécifications détaillées | 2 semaines |
| 2. Design | Identité visuelle, design system, maquettes, prototype testé | 4 semaines |
| 3. Socle technique | API, authentification, base de données, environnements, intégration continue | 3 semaines |
| 4. App patient | Compte, catalogue, réservation, suivi, paiement, historique | 5 semaines |
| 5. App professionnel | Inscription, missions, intervention, compte rendu, revenus | 4 semaines |
| 6. Back-office | Demandes, affectation, professionnels, tarifs, finances, statistiques | 4 semaines |
| 7. Site public | Pages, réservation en ligne, trois langues, référencement | 2 semaines |
| 8. Recette et lancement | Tests, test d'intrusion, corrections, publication, formation | 3 semaines |

Les lots 4 à 7 se chevauchent, ce qui explique un total inférieur à la somme des durées. Les lots 2 et 3 démarrent en parallèle.

**Version 2 (après 3 mois d'exploitation)** : dossier de suivi, abonnements, comptes entreprises, codes promotionnels, téléconsultation si le cadre le permet, extension à d'autres villes.

**Dépendances externes à lancer dès le cadrage** : contrat CMI, comptes développeur Apple et Google, vérification WhatsApp Business, démarche CNDP. Leurs délais ne dépendent pas de l'équipe de développement.

## 13. Livrables, recette, maintenance et points à trancher

**Livrables**

- Code source complet et dépôts Git, propriété du client.
- Applications publiées sur l'App Store et Google Play, sous le compte du client.
- Back-office et site en production, avec noms de domaine et certificats.
- Maquettes Figma et design system.
- Documentation : API (OpenAPI), architecture, guide d'exploitation, guides utilisateurs.
- Formation des coordinateurs et des administrateurs.

**Recette**

- Cahier de tests couvrant chaque fonctionnalité MVP, validé par le client.
- Phase pilote de 2 à 4 semaines avec un groupe restreint de professionnels et de patients.
- Classement des anomalies : bloquante, majeure, mineure. Aucune anomalie bloquante ou majeure à la mise en production.

**Maintenance**

- Garantie de 3 mois après la mise en production : correction gratuite des anomalies.
- Contrat de maintenance ensuite : corrections, mises à jour de sécurité, compatibilité avec les nouvelles versions d'iOS et d'Android, supervision.
- Délai de prise en charge d'une anomalie bloquante : 4 heures ouvrées.

**Coûts récurrents à prévoir** : hébergement, SMS et WhatsApp, cartographie, commissions de paiement, comptes développeur Apple et Google.

**Points à trancher avant le démarrage**

- [ ] Modèle juridique : plateforme de coordination avec professionnels indépendants, ou autre structure
- [ ] Modèle économique : commission par intervention, abonnement des professionnels, ou marge sur le tarif
- [ ] Liste des services au lancement et grille tarifaire
- [ ] Qui encaisse le paiement en ligne et comment le professionnel est rémunéré
- [ ] Horaires de service : journée seulement ou 24 h/24
- [ ] Lieu d'hébergement des données, après échange avec la CNDP
- [ ] Prestataire de réalisation et budget
