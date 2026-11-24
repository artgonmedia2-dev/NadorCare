# Fonctionnement cible : Nador Care, agence de soins à domicile

**Statut : validé par le client le 2026-11-23**, propositions par défaut de la section 5 comprises. L'avancement de chaque étape est noté en section 6. À sa rédaction, rien de ce document n'était développé. Il traduit les orientations données par le client le 2026-11-23 en fonctionnement concret, et montre ce que cela change dans le back-office, l'application professionnel et l'application patient. Aucune modification importante du code ne commence avant sa validation.

## 1. Le principe

Nador Care est une agence. Elle soigne à domicile avec sa propre équipe de médecins, d'infirmiers et d'aides-soignants. Elle n'est pas un intermédiaire entre des patients et des professionnels indépendants.

Trois rôles se partagent le travail :

- **le patient** (ou son proche) demande un soin ;
- **le coordinateur** valide la demande, choisit le soignant, tient le planning de l'équipe ;
- **le soignant** confirme, se déplace, réalise le soin et rédige le compte rendu.

L'application avait été conçue pour un autre modèle : des professionnels indépendants qui s'inscrivent eux-mêmes, se déclarent disponibles, reçoivent des propositions qu'ils acceptent ou refusent, et sont rémunérés par mission. Une bonne partie reste valable ; ce document dit laquelle.

## 2. Ce que le client a décidé

| Sujet | Décision |
| --- | --- |
| Comptes des soignants | L'agence crée et gère les comptes de son équipe depuis le back-office. Chaque soignant a un accès personnel à l'application. |
| Dossier de chaque soignant | L'agence le centralise : identité, diplômes, autorisations, assurance, coordonnées. Elle consulte, vérifie et suit la validité des documents. |
| Missions | Le coordinateur affecte directement. Le soignant est prévenu, puis confirme ou signale son indisponibilité avec un motif. En cas de refus, le coordinateur réaffecte. |
| Planning | L'agence le gère pour toute l'équipe : horaires, jours, zones, missions, vue d'ensemble. Le soignant communique ses disponibilités et indisponibilités ; le coordinateur valide. |
| Rémunération | Plus de commission ni de reversement automatique par mission. Les paiements des patients sont centralisés par l'agence, qui rémunère son équipe selon ses contrats. Le back-office garde un suivi des missions réalisées, des montants encaissés et des rémunérations dues. |
| Cadre légal | À faire vérifier au Maroc avant le lancement : autorisations, statut des soignants, assurances, responsabilité de l'agence, données de santé. Reçus, factures et conditions générales au nom de l'entité qui exploite le service. |

## 3. Le fonctionnement cible, pas à pas

### Faire entrer un soignant dans l'équipe

1. Le coordinateur (ou l'administrateur) crée la fiche du soignant au back-office : nom, téléphone, profession, numéros d'autorisation et d'Ordre.
2. Il y dépose les justificatifs, ou laisse le soignant les photographier depuis l'application.
3. Il invite le soignant : celui-ci reçoit un message avec le lien de l'application.
4. Le soignant ouvre l'application et se connecte. Il voit sa fiche, son planning et ses missions.
5. Le coordinateur valide le dossier quand il est complet. Avant cela, le soignant ne peut recevoir aucune mission.

Un soignant ne peut plus créer lui-même un compte professionnel : seule l'agence fait entrer quelqu'un dans l'équipe.

### Tenir le planning

1. Le coordinateur fixe pour chaque soignant ses jours, ses heures et ses zones d'intervention.
2. Le soignant propose depuis l'application ses disponibilités et signale ses indisponibilités (congé, empêchement).
3. Le coordinateur accepte ou refuse chaque proposition. Tant qu'elle n'est pas acceptée, le planning ne change pas.
4. Le back-office montre un planning global : qui travaille quand, où, et sur quelles missions.

### Traiter une demande de soin

1. Le patient réserve (application ou site). La demande naît « en attente ».
2. Le coordinateur la valide, comme aujourd'hui.
3. Il choisit un soignant. Le back-office lui propose ceux qui conviennent, classés par compétence, disponibilité, zone et distance, comme aujourd'hui.
4. Le soignant reçoit une notification avec les détails de la mission.
5. Il **confirme** la prise en charge, ou **signale son indisponibilité** avec un motif.
6. S'il se déclare indisponible, ou s'il ne répond pas dans le délai fixé, le coordinateur est alerté et réaffecte.
7. La suite ne change pas : départ, trajet suivi par le patient, arrivée, soin, compte rendu, clôture.

### Suivre l'activité et l'argent

1. Le patient paie l'agence (aujourd'hui en espèces au soignant, plus tard par carte).
2. Le back-office tient, pour chaque soignant, le relevé de ses missions réalisées et des montants qu'il a encaissés pour l'agence.
3. Il indique les rémunérations dues, selon une règle à préciser (voir la question 6 ci-dessous).
4. La paie elle-même se fait hors de l'application.

## 4. Ce qui change, application par application

### Back-office

| Aujourd'hui | Cible | Nature du travail |
| --- | --- | --- |
| Liste et fiche des professionnels, en lecture ; validation et suspension | Création et modification d'un soignant par l'agence ; invitation | À créer |
| Contrôle des justificatifs déposés par le soignant (approuver, refuser) | L'agence dépose aussi les justificatifs ; alerte avant l'expiration d'un document | À étendre |
| Zones et agenda réglés par le soignant seul | Zones, jours et heures réglés par le coordinateur ; validation des disponibilités proposées | À créer |
| Pas de vue d'ensemble | Planning global de l'équipe | À créer |
| Affectation directe par le coordinateur, ou proposition à durée limitée | Affectation directe, suivie de la confirmation du soignant | À adapter |
| Rien sur les finances | Relevé par soignant : missions, encaissements, rémunérations dues | À créer |

### Application professionnel

| Aujourd'hui | Cible | Nature du travail |
| --- | --- | --- |
| Inscription libre : choix de la profession, dépôt du dossier, attente de validation | Plus d'inscription : le compte existe déjà quand le soignant se connecte | À retirer |
| Écran « Mon dossier » où le soignant dépose tout | Le soignant consulte son dossier et peut ajouter un document demandé | À adapter |
| Interrupteur « En ligne » | Supprimé : c'est le planning qui dit si le soignant travaille | À retirer |
| Propositions de mission, avec minuterie, à accepter ou refuser | Missions affectées, à confirmer ou à décliner avec un motif | À adapter |
| Zones et agenda modifiables librement | Planning en lecture ; proposition de disponibilités et d'indisponibilités | À adapter |
| Départ, trajet, arrivée, compte rendu, téléconsultation | Inchangé | À garder |

### Application patient et site

Le parcours du patient ne change pas : il réserve, suit sa demande, lit le compte rendu. Seuls les textes changent, pour parler de « notre équipe » et de « nos soignants ». Ceux du site sont déjà corrigés. Les textes légaux (consentement, conditions générales, reçu) seront rédigés au nom de l'agence après l'avis du juriste.

La page de recrutement prévue sur le site garde son sens : un candidat y postule, et c'est l'agence qui crée ensuite son compte s'il est retenu.

### Ce qui ne change pas

Catalogue et tarifs, réservation, validation par la coordination, suivi du trajet, compte rendu et son immutabilité, chiffrement et journal des accès aux données de santé, trois langues, téléconsultation (toujours suspendue).

## 5. Points précisés

Le client a accepté le 2026-11-23 les dix propositions par défaut ci-dessous : elles font règle.

| N° | Question | Règle retenue |
| --- | --- | --- |
| 1 | **Connexion du soignant.** Vous parlez de « ses propres identifiants ». Aujourd'hui tout le monde se connecte avec son numéro de téléphone et un code reçu par SMS, sans mot de passe. | Garder le téléphone et le code : seul un numéro enregistré par l'agence ouvre l'application professionnel. Pas de mot de passe à gérer ni à oublier. |
| 2 | **Invitation.** Par quel canal le soignant est-il invité ? | Un SMS avec le lien de l'application, envoyé depuis la fiche du soignant. |
| 3 | **Qui crée un soignant ?** Le coordinateur, ou seulement l'administrateur ? | Les deux créent et modifient ; seul l'administrateur valide le dossier et suspend un compte. |
| 4 | **Délai de confirmation.** Combien de temps le soignant a-t-il pour confirmer une mission avant que le coordinateur soit alerté ? | 15 minutes pour un soin du jour même, 2 heures sinon ; valeurs réglables au back-office. |
| 5 | **Motif d'indisponibilité.** Texte libre, ou liste de motifs ? | Une courte liste (déjà en intervention, maladie, empêchement personnel, autre) avec une précision libre. |
| 6 | **Rémunérations dues.** Selon quelle règle les calculer : montant fixe par mission, taux horaire, salaire mensuel ? | Ne rien calculer au début : le relevé montre les missions et les encaissements, et la rémunération due est saisie par le comptable. Une règle automatique viendra quand les contrats seront fixés. |
| 7 | **Disponibilités.** Une semaine type seulement, ou aussi des dates précises (congés, absences) ? | Les deux : une semaine type fixée par le coordinateur, et des indisponibilités datées proposées par le soignant. |
| 8 | **Assurance.** Le dossier d'un soignant exige aujourd'hui une assurance de responsabilité civile personnelle, avec sa date de fin. | La rendre facultative en attendant l'avis du juriste, et ajouter au back-office l'assurance de l'agence. |
| 9 | **Comptes déjà créés.** Les comptes d'essai créés par inscription libre (dont le vôtre) restent-ils ? | Ils restent, rattachés à l'agence comme les autres. |
| 10 | **Espèces encaissées.** Le soignant encaisse aujourd'hui les espèces chez le patient. Comment les remet-il à l'agence ? | Le relevé indique ce que chaque soignant doit remettre ; le comptable pointe la remise au back-office. |

## 6. Ordre de réalisation proposé

Chaque étape se livre et se teste seule. Les applications restent utilisables entre deux étapes.

1. **Équipe gérée par l'agence** : création et invitation d'un soignant au back-office, fin de l'inscription libre. C'est la base de tout le reste. **Livrée le 2026-11-23** (serveur, back-office et application ; pas encore essayée sur un téléphone). Reste dans cette étape : le dépôt des justificatifs par l'agence, traité à l'étape 4.
2. **Planning** : jours, heures et zones fixés par le coordinateur, propositions de disponibilités du soignant, planning global. **Livrée le 2026-11-23** (serveur, back-office et application ; pas encore essayée sur un téléphone). Le coordinateur fixe zones et semaine type depuis la fiche du soignant (action « Planning »). Le soignant lit son planning, propose une autre semaine ou signale une indisponibilité (journées entières, 60 jours au plus, cinq demandes en attente au plus) ; la coordination accepte ou refuse dans « Demandes de planning ». Une indisponibilité acceptée signale le soignant indisponible lors de l'affectation, sans interdire au coordinateur de le choisir. Le « Planning de l'équipe » montre la semaine : heures, indisponibilités, missions. Non fait : le soignant n'est pas prévenu de la réponse par une notification (il la lit dans l'application), et le planning global ne se filtre pas encore par profession ou par zone.
3. **Affectation et confirmation** : la proposition à minuterie devient une affectation à confirmer ; retrait de l'interrupteur « En ligne ». **Livrée le 2026-11-23** (serveur, back-office et application ; pas encore essayée sur un téléphone). À l'affectation, le soignant reçoit la mission « à confirmer », avec une heure limite : 15 minutes pour un soin du jour même, 2 heures sinon (deux réglages du back-office). Il confirme, ou signale son indisponibilité avec un motif (déjà en intervention, maladie, empêchement personnel, autre avec précision) : la demande revient alors à la coordination. Partir vers le patient vaut confirmation. Sans réponse à l'heure limite, la mission reste affectée et le back-office la signale « sans réponse » ; le filtre « À réaffecter » et le compteur du menu regroupent ces demandes et celles rendues par un soignant. Non fait : aucune alerte ne sort du back-office (pas de SMS ni de notification au coordinateur), et la demande n'est pas retirée automatiquement au soignant qui ne répond pas.
4. **Dossier et validité des documents** : dépôt par l'agence, alerte avant expiration. **Livrée le 2026-11-23** (serveur, back-office et application ; pas encore essayée sur un téléphone ni dans un navigateur). Sur la fiche d'un soignant, le coordinateur ou l'administrateur dépose un justificatif (PDF ou photo, avec sa date de fin de validité s'il en a une) et envoie le dossier à la vérification. Déposé par l'administrateur, le justificatif est approuvé d'emblée ; déposé par le coordinateur, il attend le contrôle de l'administrateur. L'assurance responsabilité civile personnelle est facultative : elle n'est plus exigée pour valider un dossier ni pour affecter une mission, et reste déposable. L'assurance de l'agence (assureur, numéro de contrat, échéance, attestation) s'enregistre dans « Assurance de l'agence » ; le menu alerte quand aucun contrat n'est valable au-delà de 30 jours. Le tableau de bord et un filtre de la liste des soignants montrent les justificatifs périmés ou expirant sous 30 jours. Non fait : aucune alerte ne sort du back-office (ni e-mail ni SMS), et un justificatif périmé ne suspend rien tout seul — c'est à l'agence d'agir.
5. **Suivi financier** : relevé par soignant, encaissements, rémunérations dues. **Livrée le 2026-11-23**, au back-office seulement (pas encore essayée dans un navigateur). L'écran « Finances » montre, pour chaque soignant et pour le mois choisi : le nombre et la valeur des missions réalisées, les espèces encaissées, les espèces restées dues par des patients, les espèces remises à l'agence, le reste à remettre (toutes périodes confondues) et la rémunération due. Le comptable pointe chaque remise d'espèces (jamais plus que ce que le soignant détient, jamais à une date à venir) et saisit la rémunération due pour le mois, en un montant global qu'il peut corriger. Un relevé détaille les missions du mois sans aucune donnée de patient. L'administrateur lit tout sans rien saisir ; le coordinateur n'y a pas accès. Non fait : pas d'export (PDF, tableur), pas de vue pour le soignant dans son application, pas de suivi des paiements par carte (ils n'existent pas encore), et les espèces qu'un patient n'a pas réglées sont seulement affichées, sans relance.
6. **Textes légaux** : après l'avis du juriste.

Le suivi financier dépend aussi des questions déjà ouvertes sur le paiement par carte (`docs/03-questions-ouvertes.md`, points 4 et 14).

## 7. Points de vigilance

- **Affectation d'office et refus.** Si un soignant peut décliner, une demande urgente peut rester sans personne. Le délai de confirmation et l'alerte au coordinateur sont ce qui évite cela : ils méritent d'être réglés avec soin.
- **Planning validé par le coordinateur.** Chaque proposition du soignant demande une action du coordinateur. Avec une petite équipe, c'est léger ; il faudra surveiller la charge si l'équipe grandit.
- **Données de santé.** Le cloisonnement actuel reste la règle : un soignant ne voit que les patients de ses propres missions, même s'il fait partie de l'équipe. Le coordinateur, lui, voit les demandes ; ce qu'il peut lire du dossier médical est à confirmer avec le juriste.
- **Cadre légal.** Tant que l'avis du juriste n'est pas rendu, rien ne doit être présenté aux patients comme définitif sur les assurances, les reçus et les conditions générales.
