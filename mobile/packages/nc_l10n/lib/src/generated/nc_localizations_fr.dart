// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'nc_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class NcLocalizationsFr extends NcLocalizations {
  NcLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appNamePatient => 'Nador Care';

  @override
  String get appNamePro => 'Nador Care Pro';

  @override
  String get languageName => 'Français';

  @override
  String get languageTitle => 'Choisissez votre langue';

  @override
  String get languageSubtitle =>
      'Vous pourrez la changer à tout moment dans les réglages.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get phoneTitle => 'Votre numéro de téléphone';

  @override
  String get phoneSubtitle =>
      'Nous vous envoyons un code par SMS pour vous connecter.';

  @override
  String get phoneLabel => 'Numéro de téléphone';

  @override
  String get phoneHint => '06 12 34 56 78';

  @override
  String get phoneHelper =>
      'Depuis l\'étranger, ajoutez l\'indicatif : +33, +34, +31…';

  @override
  String get phoneInvalid => 'Entrez un numéro de téléphone valide.';

  @override
  String get sendCode => 'Recevoir le code';

  @override
  String get otpTitle => 'Entrez le code reçu';

  @override
  String otpSubtitle(String phone) {
    return 'Code envoyé par SMS au $phone.';
  }

  @override
  String get otpLabel => 'Code à 6 chiffres';

  @override
  String get otpIncomplete => 'Entrez les 6 chiffres du code.';

  @override
  String get verify => 'Valider';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String resendIn(int seconds) {
    return 'Renvoyer le code dans $seconds s';
  }

  @override
  String get codeResent => 'Un nouveau code vient d\'être envoyé.';

  @override
  String get changeNumber => 'Changer de numéro';

  @override
  String get consentTitle => 'Avant de créer votre compte';

  @override
  String get consentIntro =>
      'Nador Care a besoin de votre accord pour créer votre compte.';

  @override
  String get consentTerms =>
      'J\'accepte les conditions générales d\'utilisation.';

  @override
  String get consentPrivacy => 'J\'accepte la politique de confidentialité.';

  @override
  String get consentHealthData =>
      'J\'accepte que mes données de santé soient utilisées pour organiser mes soins. Seul le professionnel qui intervient chez moi y a accès.';

  @override
  String get consentRights =>
      'Vous pouvez consulter, corriger ou supprimer vos données à tout moment depuis l\'application.';

  @override
  String get consentAccept => 'Créer mon compte';

  @override
  String get emergencyNotice =>
      'Nador Care ne remplace pas les urgences. En cas d\'urgence vitale, appelez le 141 ou le 15.';

  @override
  String get unlockTitle => 'Application verrouillée';

  @override
  String get unlockSubtitle =>
      'Utilisez votre empreinte ou votre visage pour continuer.';

  @override
  String get unlockButton => 'Déverrouiller';

  @override
  String get biometricReason =>
      'Confirmez votre identité pour ouvrir Nador Care';

  @override
  String homeGreeting(String name) {
    return 'Bonjour $name';
  }

  @override
  String get homeGreetingAnonymous => 'Bonjour';

  @override
  String get homePatientSoon =>
      'La réservation de soins arrive bientôt dans cette application.';

  @override
  String get homeProSoon =>
      'Vos missions arriveront bientôt dans cette application.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsOpen => 'Ouvrir les réglages';

  @override
  String get nameLabel => 'Votre nom';

  @override
  String get nameHint => 'Prénom et nom';

  @override
  String get nameTooShort => 'Entrez au moins 2 caractères.';

  @override
  String get profileSaved => 'Vos informations sont enregistrées.';

  @override
  String get languageLabel => 'Langue';

  @override
  String get textSizeLabel => 'Taille du texte';

  @override
  String get textSizeNormal => 'Normale';

  @override
  String get textSizeLarge => 'Grande';

  @override
  String get textSizeExtraLarge => 'Très grande';

  @override
  String get biometricLabel => 'Verrouillage par empreinte ou visage';

  @override
  String get biometricSubtitle =>
      'Demandé à chaque ouverture de l\'application.';

  @override
  String get biometricUnavailable =>
      'Cet appareil ne propose pas l\'empreinte ni la reconnaissance du visage.';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmBody =>
      'Vous devrez saisir un nouveau code pour vous reconnecter.';

  @override
  String get errorNetwork =>
      'Pas de connexion. Vérifiez votre réseau et réessayez.';

  @override
  String get errorUnknown =>
      'Une erreur est survenue. Réessayez dans un instant.';

  @override
  String get retry => 'Réessayer';

  @override
  String get delete => 'Supprimer';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get homeProfiles => 'Mes patients';

  @override
  String get homeProfilesSubtitle => 'Vous-même, un parent, un enfant';

  @override
  String get homeAddresses => 'Mes adresses';

  @override
  String get homeAddressesSubtitle => 'Là où le soignant doit se rendre';

  @override
  String get profilesEmpty =>
      'Ajoutez la personne à soigner : vous-même ou un proche.';

  @override
  String get profileAdd => 'Ajouter un patient';

  @override
  String get profileNewTitle => 'Nouveau patient';

  @override
  String get profileEditTitle => 'Modifier le patient';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get lastNameLabel => 'Nom';

  @override
  String get relationshipLabel => 'Cette personne est';

  @override
  String get relationshipSelf => 'Moi-même';

  @override
  String get relationshipParent => 'Mon père ou ma mère';

  @override
  String get relationshipChild => 'Mon enfant';

  @override
  String get relationshipSpouse => 'Mon conjoint ou ma conjointe';

  @override
  String get relationshipOther => 'Un autre proche';

  @override
  String get birthDateLabel => 'Date de naissance';

  @override
  String get birthDateChoose => 'Choisir une date';

  @override
  String get sexLabel => 'Sexe';

  @override
  String get sexFemale => 'Femme';

  @override
  String get sexMale => 'Homme';

  @override
  String get patientPhoneLabel => 'Téléphone du patient (facultatif)';

  @override
  String get careNotesLabel => 'Informations utiles au soignant';

  @override
  String get careNotesHint => 'Allergies, maladies, mobilité…';

  @override
  String get careNotesPrivacy =>
      'Ces informations sont chiffrées. Seul le soignant qui intervient chez ce patient les voit.';

  @override
  String get profileDeleteTitle => 'Retirer ce patient ?';

  @override
  String get profileDeleteBody => 'Son historique de soins est conservé.';

  @override
  String get addressesEmpty =>
      'Ajoutez l\'adresse où le soignant doit se rendre.';

  @override
  String get addressAdd => 'Ajouter une adresse';

  @override
  String get addressNewTitle => 'Nouvelle adresse';

  @override
  String get addressEditTitle => 'Modifier l\'adresse';

  @override
  String get addressLabelLabel => 'Nom de l\'adresse';

  @override
  String get addressLabelHint => 'Maison, chez ma mère…';

  @override
  String get addressLineLabel => 'Adresse';

  @override
  String get addressLineHint => 'Rue, numéro, quartier';

  @override
  String get accessNotesLabel => 'Repères pour trouver la porte';

  @override
  String get accessNotesHint => 'Étage, couleur de la porte, commerce voisin…';

  @override
  String get locationLabel => 'Position GPS';

  @override
  String get locationHelp => 'À faire sur place, devant la porte du patient.';

  @override
  String get locationUse => 'Utiliser ma position actuelle';

  @override
  String get locationSet => 'Position enregistrée';

  @override
  String get locationMissing => 'Enregistrez la position de cette adresse.';

  @override
  String get locationDenied =>
      'Autorisez la localisation pour Nador Care dans les réglages du téléphone.';

  @override
  String get locationDisabled => 'Activez la localisation (GPS) du téléphone.';

  @override
  String get locationUnavailable =>
      'Position introuvable. Réessayez à l\'extérieur.';

  @override
  String get addressCovered => 'Zone desservie';

  @override
  String get addressNotCovered => 'Hors zone desservie pour le moment';

  @override
  String get addressDeleteTitle => 'Retirer cette adresse ?';

  @override
  String get homeCatalogue => 'Nos soins';

  @override
  String get homeCatalogueSubtitle => 'Voir les soins proposés à domicile';

  @override
  String get catalogueSearchHint => 'Rechercher un soin';

  @override
  String get catalogueEmpty => 'Aucun soin n\'est proposé pour le moment.';

  @override
  String catalogueNoResult(String query) {
    return 'Aucun soin ne correspond à « $query ».';
  }

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soins',
      one: '1 soin',
    );
    return '$_temp0';
  }

  @override
  String serviceDuration(int minutes) {
    return '$minutes min';
  }

  @override
  String priceDirhams(String amount) {
    return '$amount DH';
  }

  @override
  String get serviceDurationLabel => 'Durée';

  @override
  String get servicePriceLabel => 'Tarif indicatif';

  @override
  String get servicePriceNote =>
      'Le prix peut être majoré la nuit, les jours fériés et selon la distance.';

  @override
  String get servicePrescriptionRequired => 'Ordonnance obligatoire';

  @override
  String get servicePrescriptionHelp =>
      'Pour réserver ce soin, vous devrez déposer une photo de l\'ordonnance.';

  @override
  String get serviceSeries =>
      'Ce soin peut être programmé sur plusieurs jours.';

  @override
  String serviceProvidedBy(String profession) {
    return 'Réalisé par : $profession';
  }

  @override
  String get bookingSoon =>
      'La réservation arrive bientôt dans l\'application.';

  @override
  String get bookService => 'Réserver ce soin';

  @override
  String get homeBookings => 'Mes réservations';

  @override
  String get homeBookingsSubtitle => 'Suivre ou annuler une demande';

  @override
  String get bookingStepPatientTitle => 'Pour qui est ce soin ?';

  @override
  String get bookingStepAddressTitle => 'Où le soignant doit-il venir ?';

  @override
  String get bookingStepSlotTitle => 'Quand ?';

  @override
  String get bookingStepSummaryTitle => 'Vérifiez votre demande';

  @override
  String get bookingNoProfile => 'Ajoutez d\'abord la personne à soigner.';

  @override
  String get bookingNoAddress => 'Ajoutez d\'abord l\'adresse du patient.';

  @override
  String get bookingChoosePatient => 'Choisissez un patient.';

  @override
  String get bookingChooseAddress => 'Choisissez une adresse.';

  @override
  String get bookingAddressNotCovered =>
      'Cette adresse est hors de la zone desservie pour le moment.';

  @override
  String get slotAsap => 'Dès que possible';

  @override
  String get slotChooseDay => 'Choisir un jour';

  @override
  String get slotNadorTime => 'Les heures sont celles de Nador.';

  @override
  String get slotNone => 'Aucun créneau ce jour-là. Choisissez un autre jour.';

  @override
  String get slotChoose => 'Choisissez un créneau.';

  @override
  String get summaryService => 'Soin';

  @override
  String get summaryPatient => 'Patient';

  @override
  String get summaryAddress => 'Adresse';

  @override
  String get summarySlot => 'Créneau';

  @override
  String get summaryPayment => 'Paiement';

  @override
  String get summaryBasePrice => 'Tarif';

  @override
  String get summaryTotal => 'Total';

  @override
  String get paymentCash => 'Espèces, à régler au soignant';

  @override
  String get noteLabel => 'Note pour le soignant (facultatif)';

  @override
  String get noteHint => 'Exemple : sonner deux fois';

  @override
  String get prescriptionCamera => 'Prendre l\'ordonnance en photo';

  @override
  String get prescriptionGallery => 'Choisir une photo de l\'ordonnance';

  @override
  String get prescriptionAdded => 'Ordonnance ajoutée';

  @override
  String get prescriptionMissing =>
      'Ajoutez l\'ordonnance pour envoyer la demande.';

  @override
  String get bookingConfirm => 'Envoyer ma demande';

  @override
  String get bookingSentTitle => 'Demande envoyée';

  @override
  String bookingSentBody(String reference) {
    return 'La coordination va valider votre demande $reference. Gardez ce numéro.';
  }

  @override
  String get bookingSeeMine => 'Voir mes réservations';

  @override
  String get bookingsEmpty => 'Vous n\'avez aucune réservation en cours.';

  @override
  String get bookingsPastEmpty => 'Aucune réservation passée.';

  @override
  String get bookingsUpcoming => 'En cours et à venir';

  @override
  String get bookingsPast => 'Passées';

  @override
  String get statusPending => 'En attente de validation';

  @override
  String get statusConfirmed => 'Confirmée, recherche d\'un soignant';

  @override
  String get statusAssigned => 'Soignant affecté';

  @override
  String get statusEnRoute => 'Soignant en route';

  @override
  String get statusInProgress => 'Soin en cours';

  @override
  String get statusCompleted => 'Terminée';

  @override
  String get statusCancelled => 'Annulée';

  @override
  String get statusDisputed => 'En cours d\'examen';

  @override
  String bookingReference(String reference) {
    return 'Demande $reference';
  }

  @override
  String dateAtTime(String date, String time) {
    return '$date à $time';
  }

  @override
  String get bookingCancel => 'Annuler la réservation';

  @override
  String get bookingCancelTitle => 'Annuler cette réservation ?';

  @override
  String get bookingCancelFree => 'L\'annulation est gratuite.';

  @override
  String bookingCancelFee(String amount) {
    return 'Des frais d\'annulation de $amount DH s\'appliquent.';
  }

  @override
  String get bookingCancelConfirm => 'Oui, annuler';

  @override
  String get bookingKeep => 'Garder la réservation';

  @override
  String bookingFeeCharged(String amount) {
    return 'Frais d\'annulation : $amount DH';
  }

  @override
  String get back => 'Retour';

  @override
  String get refresh => 'Actualiser';

  @override
  String get proCreateFileTitle => 'Créez votre dossier professionnel';

  @override
  String get proCreateFileIntro =>
      'Pour recevoir des missions, votre dossier doit être vérifié par Nador Care.';

  @override
  String get proStart => 'Commencer';

  @override
  String get professionLabel => 'Votre profession';

  @override
  String get professionRequired => 'Choisissez votre profession.';

  @override
  String get licenseNumberLabel => 'Numéro d\'autorisation d\'exercice';

  @override
  String get orderNumberLabel => 'Numéro d\'inscription à l\'Ordre';

  @override
  String get proFileTitle => 'Mon dossier';

  @override
  String get proDocumentsTitle => 'Justificatifs';

  @override
  String get docIdentity => 'Pièce d\'identité';

  @override
  String get docDiploma => 'Diplôme';

  @override
  String get docPracticeAuthorization => 'Autorisation d\'exercice';

  @override
  String get docOrderRegistration => 'Inscription à l\'Ordre';

  @override
  String get docRcInsurance => 'Assurance responsabilité civile';

  @override
  String get docStatusMissing => 'À déposer';

  @override
  String get docStatusPending => 'Déposé, en attente de contrôle';

  @override
  String get docStatusApproved => 'Approuvé';

  @override
  String docStatusRejected(String reason) {
    return 'Refusé : $reason';
  }

  @override
  String get docStatusExpired => 'Périmé, à renouveler';

  @override
  String get docTakePhoto => 'Prendre en photo';

  @override
  String get docChoosePhoto => 'Choisir une photo';

  @override
  String get docExpiryChoose => 'Date de fin de validité de l\'assurance';

  @override
  String get docExpiryRequired =>
      'Indiquez d\'abord la date de fin de validité de l\'assurance.';

  @override
  String docValidUntil(String date) {
    return 'Valable jusqu\'au $date';
  }

  @override
  String get proSubmit => 'Envoyer mon dossier';

  @override
  String get proSubmitIncomplete =>
      'Déposez tous les justificatifs pour envoyer votre dossier.';

  @override
  String get proChangeProfession => 'Modifier ma profession';

  @override
  String get proStatusSubmittedTitle => 'Dossier en cours de vérification';

  @override
  String get proStatusSubmittedBody =>
      'Nous vérifions vos justificatifs. Vous pourrez recevoir des missions dès que votre dossier sera validé.';

  @override
  String get proStatusRejectedTitle => 'Votre dossier est à corriger';

  @override
  String get proStatusSuspendedTitle => 'Compte suspendu';

  @override
  String get proStatusSuspendedBody =>
      'Vous ne recevez plus de mission. Contactez la coordination.';

  @override
  String proReason(String reason) {
    return 'Motif : $reason';
  }

  @override
  String get proOnline => 'En ligne';

  @override
  String get proOffline => 'Hors ligne';

  @override
  String get proOnlineHelp =>
      'En ligne, vous pouvez recevoir des propositions de mission.';

  @override
  String get proZones => 'Mes zones';

  @override
  String get proZonesTitle => 'Zones où vous intervenez';

  @override
  String get proZonesEmpty => 'Aucune zone n\'est encore ouverte.';

  @override
  String proZonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones',
      one: '1 zone',
      zero: 'Aucune zone choisie',
    );
    return '$_temp0';
  }

  @override
  String get proSchedule => 'Mon agenda';

  @override
  String get proScheduleTitle => 'Jours et heures de travail';

  @override
  String get proScheduleHelp => 'Les heures sont celles de Nador.';

  @override
  String proScheduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours par semaine',
      one: '1 jour par semaine',
      zero: 'Aucun jour travaillé',
    );
    return '$_temp0';
  }

  @override
  String scheduleRange(String start, String end) {
    return '$start à $end';
  }

  @override
  String get scheduleStart => 'Début';

  @override
  String get scheduleEnd => 'Fin';

  @override
  String get scheduleInvalid =>
      'L\'heure de fin doit être après l\'heure de début.';

  @override
  String get proOffersTitle => 'Propositions de mission';

  @override
  String get proOffersEmpty => 'Aucune proposition pour le moment.';

  @override
  String offerAnswerBefore(String time) {
    return 'Répondre avant $time';
  }

  @override
  String offerDistance(String distance) {
    return 'À $distance';
  }

  @override
  String get offerAccept => 'Accepter';

  @override
  String get offerDecline => 'Refuser';

  @override
  String get proMissionsTitle => 'Mes missions';

  @override
  String get proMissionsEmpty => 'Aucune mission affectée.';

  @override
  String get missionStatusAssigned => 'À venir';

  @override
  String get missionStatusEnRoute => 'En route';

  @override
  String get missionStatusInProgress => 'En cours';

  @override
  String get missionAccessNotes => 'Repères d\'accès';

  @override
  String get missionCareNotes => 'Informations utiles au soin';

  @override
  String get missionPatientNote => 'Note du patient';

  @override
  String get missionAmount => 'À encaisser en espèces';

  @override
  String get missionPrescription => 'Une ordonnance est jointe à la demande.';

  @override
  String get missionWithdraw => 'Me désister';

  @override
  String get missionWithdrawTitle => 'Vous désister de cette mission ?';

  @override
  String get missionWithdrawBody =>
      'La coordination cherchera un autre soignant.';

  @override
  String get missionWithdrawReason => 'Motif';
}
