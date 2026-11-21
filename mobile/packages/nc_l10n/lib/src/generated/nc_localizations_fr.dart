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
}
