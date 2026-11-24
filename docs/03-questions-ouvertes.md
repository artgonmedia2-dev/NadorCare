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
| 1 | **Modèle : une agence de soins à domicile, avec sa propre équipe** (médecins, infirmiers, aides-soignants). Nador Care **n'est pas un intermédiaire** entre des patients et des professionnels indépendants, contrairement à ce qu'écrit le cahier des charges (§1, §2 : « met en relation », « professionnels indépendants »). Textes du site corrigés le jour même. Les conséquences sur le fonctionnement sont les questions 35 à 40. | 2026-11-23 |
| 14 bis | **Téléconsultation dans la première version** (le cahier des charges la classait en V2). Appel vidéo dans l'application ; fermée aux patients tant que le paiement par carte n'existe pas ; prestataire vidéo à choisir, pilote factice en attendant. | 2026-11-23 |
| 3 bis | **Médecine à domicile** : consultation d'un médecin généraliste à 500 DH le jour (tarif fixé directement, sans les 150 DH). | 2026-11-23 |
| 3 | **Grille tarifaire** : le tarif de jour de la grille de référence fournie par le client, **plus 150 DH par service**. Tarif du soir : 50 DH de plus, de 19 h à 8 h (majoration de nuit). Chargée par `NadorCatalogueSeeder` : 20 soins en 6 catégories. Restent ouverts les points 25 à 30. | 2026-11-23 |

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
| 25 | **Taxe.** La grille de référence est hors taxe (TVA de 20 % indiquée). Les prix chargés et affichés sont ces montants + 150 DH, sans taxe ajoutée. Sont-ils hors taxe ou toutes taxes comprises ? | 4.3, 7.1 |
| 26 | **Garde-malade.** Forfaits à la journée, à la nuit et à la semaine : ils ne rentrent pas dans une réservation par créneau. Le site les affiche (tarif par jour + 150 DH) depuis `web/src/content/home-guard.ts`, sans réservation en ligne. Faut-il un parcours de réservation propre ? Les 150 DH s'ajoutent-ils par jour ou par semaine au forfait hebdomadaire (non affiché pour l'instant) ? | 4.3, 4.4 |
| 27 | **Supplément de déplacement.** La grille de référence ajoute 50 DH hors de la ville. Quelles communes autour de Nador, et quel montant ? La majoration de distance existe mais n'est pas appliquée. | 6.7 |
| 28 | **Sonde gastrique.** La grille de référence répète « hors consommable » sur ses lignes à 390 et 455 DH. Elles ont été lues comme pour la sonde urinaire : matériel inclus, puis silicone. À confirmer. | 4.3 |
| 29 | **Durées et ordonnances.** Les durées des soins sont des estimations. L'ordonnance est exigée pour les injections, perfusions, sondes et la kinésithérapie, et pas pour les autres soins : à valider par un responsable médical. | 4.3 |
| 30 | **Infirmière auxiliaire** (garde-malade) : à quelle profession de la plateforme la rattacher ? | 5.1 |
| 31 | **Téléconsultation : prestataire vidéo.** Réponse du client (2026-11-23) : un prestataire fiable, de bonne qualité vidéo, sûr pour des données médicales et simple à intégrer ; **choix définitif après comparaison** des solutions, de leurs coûts et de leurs fonctions. Reste donc ouvert. Tant qu'il n'est pas choisi, l'appel est simulé. | Téléconsultation |
| 32 | **Téléconsultation : tarif et professions.** Réponse du client (2026-11-23) : durée de **15 à 30 minutes** ; réalisée par des **médecins généralistes et des spécialistes**, selon les disponibilités ; **tarif à définir selon le médecin et la nature de la consultation**. **Décision du 2026-11-23 : un soin par type de consultation** (généraliste, puis un soin par spécialité), chacun avec son tarif et sa durée ; pas de tarif propre à chaque médecin, donc aucune évolution du modèle. **Première phase (2026-11-23) : uniquement la téléconsultation avec un médecin généraliste, 20 minutes** ; les autres spécialités viendront ensuite, une fois le fonctionnement validé. **Tarif initial fixé le 2026-11-23 : 150 DH**, à réévaluer selon la demande, les coûts et les retours des patients. Le soin « Téléconsultation avec un médecin généraliste » est créé par `NadorCatalogueSeeder`, **désactivé**. Pour l'ouvrir le jour venu, trois choses au back-office : activer le soin, activer sa catégorie « Téléconsultation », et passer le réglage « Téléconsultation ouverte aux patients » à 1. **Tarif fixe (décision du 2026-11-23)** : le patient paie toujours 150 DH, quelle que soit l'heure. Aucune majoration ne s'applique à une téléconsultation — ni celle du soir et de la nuit, ni, par la même règle, celle des jours fériés (`PriceCalculator`). | Téléconsultation |
| 33 | **Téléconsultation : cadre légal.** Réponse du client (2026-11-23) : la conformité à la réglementation marocaine (autorisations, consentement du patient, confidentialité, conservation des données) **doit être vérifiée avant le lancement officiel**. Reste ouvert tant que cette vérification n'est pas faite ; la téléconsultation reste fermée d'ici là. Sous-questions toujours posées : consentement propre à la téléconsultation ? enregistrement de l'appel (aujourd'hui : non) ? | Téléconsultation |
| 34 | **Téléconsultation : ordonnance.** Réponse du client (2026-11-23) : **oui**. À la fin de la consultation, le médecin génère une ordonnance électronique, la transmet au patient par l'application, qui peut la télécharger en PDF — **sous réserve de conformité** à la réglementation. Non développé : à spécifier (contenu, signature du médecin, numéro d'Ordre, durée de validité, qui peut la relire) une fois le point 33 éclairci. | Téléconsultation |

### Conséquences du modèle « agence » (décision 1 du 2026-11-23)

L'application a été conçue pour des professionnels indépendants qui s'inscrivent, choisissent leurs missions et sont rémunérés à l'acte. Avec une équipe propre à l'agence, ces points étaient à trancher.

**Orientations données par le client le 2026-11-23** : comptes créés et gérés par l'agence (35) ; dossier de chaque soignant centralisé par l'agence, assurance à voir avec un juriste (36) ; affectation directe par le coordinateur, que le soignant confirme ou décline avec un motif (37) ; planning géré par l'agence, le soignant propose ses disponibilités et le coordinateur valide (38) ; ni commission ni reversement, mais un suivi des missions, des encaissements et des rémunérations dues (39) ; cadre légal à faire vérifier avant le lancement, documents au nom de l'entité exploitante (40).

Le fonctionnement cible qui en découle, ses conséquences par application et les dix points encore à préciser sont dans `docs/04-fonctionnement-cible-agence.md`, **à valider par le client avant toute modification importante du code**. Rien n'a été modifié dans le code en attendant.

| N° | Question | Ce qui existe aujourd'hui | Tâche |
| --- | --- | --- | --- |
| 35 | **Création des comptes soignants.** Un soignant de l'équipe s'inscrit-il lui-même dans l'application, ou est-ce l'agence qui crée son compte au back-office ? | Le soignant s'inscrit seul, choisit sa profession et dépose ses justificatifs ; un administrateur valide. | 5.1, 6.5 |
| 36 | **Justificatifs.** L'agence garde-t-elle dans l'application le dossier de chaque soignant (identité, diplôme, autorisation d'exercice, inscription à l'Ordre, assurance) ? L'assurance de responsabilité civile est-elle celle de l'agence plutôt que celle du soignant ? | Cinq justificatifs exigés par soignant, dont une assurance personnelle avec date de fin. | 5.1, 6.5 |
| 37 | **Missions : proposées ou affectées ?** Un soignant de l'équipe peut-il refuser une mission, ou le coordinateur l'affecte-t-il d'office selon le planning ? | Le soignant reçoit une proposition à durée limitée, qu'il accepte ou refuse ; il peut aussi se désister avec un motif. | 5.3, 6.2, 6.3 |
| 38 | **« En ligne » et agenda.** Le soignant déclare-t-il lui-même ses jours, ses heures et ses zones, ou est-ce l'agence qui fixe son planning ? | Le soignant se met en ligne ou hors ligne et règle lui-même ses zones et son agenda. | 5.2 |
| 39 | **Rémunération.** L'équipe étant celle de l'agence, les reversements par mission et la commission (cahier des charges §6, §9) n'ont plus lieu d'être : confirmez-vous qu'il n'y a ni commission ni reversement, et que la paie se fait hors de l'application ? Faut-il quand même un relevé d'activité par soignant ? | Rien n'est développé (tâches 5.8, 5.9, 6.9 en attente). | 5.8, 5.9, 6.9 |
| 40 | **Cadre légal de l'agence.** Le reçu est émis au nom de l'agence ; les textes de consentement et les conditions générales doivent le dire. Une agence qui emploie des soignants et réalise des soins à domicile relève d'un régime d'autorisation à vérifier avec un juriste, comme pour la téléconsultation. | Textes légaux non rédigés (tâche 7.6). | 4.13, 7.6 |

Consigne du client du 2026-11-23 : les points 31 à 34 **doivent être validés avant de finaliser le cahier des charges fonctionnel et de poursuivre le développement de la téléconsultation**. La première version déjà écrite (serveur et applications, appel simulé, fermée aux patients) reste en l'état ; rien de plus ne se développe sur ce sujet d'ici là.

## D. Dépendances externes

| N° | Question |
| --- | --- |
| 22 | Maquettes Figma et design system (lot 2) : existent-ils ? Sinon je pars sur un design system provisoire, à remplacer. |
| 23 | Compilation iOS : impossible sous Windows. Un Mac est-il disponible, ou passe-t-on par un service de build macOS ? |
| 24 | Comptes à créer par le client : Firebase (push), Google Maps Platform, comptes développeur Apple et Google, passerelle SMS, WhatsApp Business. En attendant, tout reste en implémentation factice. |
