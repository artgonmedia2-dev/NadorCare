import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'nc_localizations_ar.dart';
import 'nc_localizations_en.dart';
import 'nc_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of NcLocalizations
/// returned by `NcLocalizations.of(context)`.
///
/// Applications need to include `NcLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/nc_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: NcLocalizations.localizationsDelegates,
///   supportedLocales: NcLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the NcLocalizations.supportedLocales
/// property.
abstract class NcLocalizations {
  NcLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static NcLocalizations of(BuildContext context) {
    return Localizations.of<NcLocalizations>(context, NcLocalizations)!;
  }

  static const LocalizationsDelegate<NcLocalizations> delegate =
      _NcLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appNamePatient.
  ///
  /// In fr, this message translates to:
  /// **'Nador Care'**
  String get appNamePatient;

  /// No description provided for @appNamePro.
  ///
  /// In fr, this message translates to:
  /// **'Nador Care Pro'**
  String get appNamePro;

  /// No description provided for @languageName.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageName;

  /// No description provided for @languageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre langue'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez la changer à tout moment dans les réglages.'**
  String get languageSubtitle;

  /// No description provided for @continueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @phoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre numéro de téléphone'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Nous vous envoyons un code par SMS pour vous connecter.'**
  String get phoneSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'06 12 34 56 78'**
  String get phoneHint;

  /// No description provided for @phoneHelper.
  ///
  /// In fr, this message translates to:
  /// **'Depuis l\'étranger, ajoutez l\'indicatif : +33, +34, +31…'**
  String get phoneHelper;

  /// No description provided for @phoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un numéro de téléphone valide.'**
  String get phoneInvalid;

  /// No description provided for @sendCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code reçu'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé par SMS au {phone}.'**
  String otpSubtitle(String phone);

  /// No description provided for @otpLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres'**
  String get otpLabel;

  /// No description provided for @otpIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Entrez les 6 chiffres du code.'**
  String get otpIncomplete;

  /// No description provided for @verify.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {seconds} s'**
  String resendIn(int seconds);

  /// No description provided for @codeResent.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau code vient d\'être envoyé.'**
  String get codeResent;

  /// No description provided for @changeNumber.
  ///
  /// In fr, this message translates to:
  /// **'Changer de numéro'**
  String get changeNumber;

  /// No description provided for @consentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avant de créer votre compte'**
  String get consentTitle;

  /// No description provided for @consentIntro.
  ///
  /// In fr, this message translates to:
  /// **'Nador Care a besoin de votre accord pour créer votre compte.'**
  String get consentIntro;

  /// No description provided for @consentTerms.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les conditions générales d\'utilisation.'**
  String get consentTerms;

  /// No description provided for @consentPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte la politique de confidentialité.'**
  String get consentPrivacy;

  /// No description provided for @consentHealthData.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte que mes données de santé soient utilisées pour organiser mes soins. Seul le professionnel qui intervient chez moi y a accès.'**
  String get consentHealthData;

  /// No description provided for @consentRights.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez consulter, corriger ou supprimer vos données à tout moment depuis l\'application.'**
  String get consentRights;

  /// No description provided for @consentAccept.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get consentAccept;

  /// No description provided for @emergencyNotice.
  ///
  /// In fr, this message translates to:
  /// **'Nador Care ne remplace pas les urgences. En cas d\'urgence vitale, appelez le 141 ou le 15.'**
  String get emergencyNotice;

  /// No description provided for @unlockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Application verrouillée'**
  String get unlockTitle;

  /// No description provided for @unlockSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez votre empreinte ou votre visage pour continuer.'**
  String get unlockSubtitle;

  /// No description provided for @unlockButton.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get unlockButton;

  /// No description provided for @biometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre identité pour ouvrir Nador Care'**
  String get biometricReason;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingAnonymous.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get homeGreetingAnonymous;

  /// No description provided for @homePatientSoon.
  ///
  /// In fr, this message translates to:
  /// **'La réservation de soins arrive bientôt dans cette application.'**
  String get homePatientSoon;

  /// No description provided for @homeProSoon.
  ///
  /// In fr, this message translates to:
  /// **'Vos missions arriveront bientôt dans cette application.'**
  String get homeProSoon;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @settingsOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get settingsOpen;

  /// No description provided for @nameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In fr, this message translates to:
  /// **'Prénom et nom'**
  String get nameHint;

  /// No description provided for @nameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Entrez au moins 2 caractères.'**
  String get nameTooShort;

  /// No description provided for @profileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Vos informations sont enregistrées.'**
  String get profileSaved;

  /// No description provided for @languageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageLabel;

  /// No description provided for @textSizeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte'**
  String get textSizeLabel;

  /// No description provided for @textSizeNormal.
  ///
  /// In fr, this message translates to:
  /// **'Normale'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In fr, this message translates to:
  /// **'Grande'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In fr, this message translates to:
  /// **'Très grande'**
  String get textSizeExtraLarge;

  /// No description provided for @biometricLabel.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage par empreinte ou visage'**
  String get biometricLabel;

  /// No description provided for @biometricSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandé à chaque ouverture de l\'application.'**
  String get biometricSubtitle;

  /// No description provided for @biometricUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil ne propose pas l\'empreinte ni la reconnaissance du visage.'**
  String get biometricUnavailable;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez saisir un nouveau code pour vous reconnecter.'**
  String get logoutConfirmBody;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifiez votre réseau et réessayez.'**
  String get errorNetwork;

  /// No description provided for @errorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez dans un instant.'**
  String get errorUnknown;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;
}

class _NcLocalizationsDelegate extends LocalizationsDelegate<NcLocalizations> {
  const _NcLocalizationsDelegate();

  @override
  Future<NcLocalizations> load(Locale locale) {
    return SynchronousFuture<NcLocalizations>(lookupNcLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_NcLocalizationsDelegate old) => false;
}

NcLocalizations lookupNcLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return NcLocalizationsAr();
    case 'en':
      return NcLocalizationsEn();
    case 'fr':
      return NcLocalizationsFr();
  }

  throw FlutterError(
    'NcLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
