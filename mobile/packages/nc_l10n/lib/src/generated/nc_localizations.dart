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

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get fieldRequired;

  /// No description provided for @homeProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Mes patients'**
  String get homeProfiles;

  /// No description provided for @homeProfilesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous-même, un parent, un enfant'**
  String get homeProfilesSubtitle;

  /// No description provided for @homeAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Mes adresses'**
  String get homeAddresses;

  /// No description provided for @homeAddressesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Là où le soignant doit se rendre'**
  String get homeAddressesSubtitle;

  /// No description provided for @profilesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez la personne à soigner : vous-même ou un proche.'**
  String get profilesEmpty;

  /// No description provided for @profileAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un patient'**
  String get profileAdd;

  /// No description provided for @profileNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau patient'**
  String get profileNewTitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le patient'**
  String get profileEditTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastNameLabel;

  /// No description provided for @relationshipLabel.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne est'**
  String get relationshipLabel;

  /// No description provided for @relationshipSelf.
  ///
  /// In fr, this message translates to:
  /// **'Moi-même'**
  String get relationshipSelf;

  /// No description provided for @relationshipParent.
  ///
  /// In fr, this message translates to:
  /// **'Mon père ou ma mère'**
  String get relationshipParent;

  /// No description provided for @relationshipChild.
  ///
  /// In fr, this message translates to:
  /// **'Mon enfant'**
  String get relationshipChild;

  /// No description provided for @relationshipSpouse.
  ///
  /// In fr, this message translates to:
  /// **'Mon conjoint ou ma conjointe'**
  String get relationshipSpouse;

  /// No description provided for @relationshipOther.
  ///
  /// In fr, this message translates to:
  /// **'Un autre proche'**
  String get relationshipOther;

  /// No description provided for @birthDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get birthDateLabel;

  /// No description provided for @birthDateChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get birthDateChoose;

  /// No description provided for @sexLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sexe'**
  String get sexLabel;

  /// No description provided for @sexFemale.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get sexFemale;

  /// No description provided for @sexMale.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get sexMale;

  /// No description provided for @patientPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du patient (facultatif)'**
  String get patientPhoneLabel;

  /// No description provided for @careNotesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Informations utiles au soignant'**
  String get careNotesLabel;

  /// No description provided for @careNotesHint.
  ///
  /// In fr, this message translates to:
  /// **'Allergies, maladies, mobilité…'**
  String get careNotesHint;

  /// No description provided for @careNotesPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Ces informations sont chiffrées. Seul le soignant qui intervient chez ce patient les voit.'**
  String get careNotesPrivacy;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce patient ?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Son historique de soins est conservé.'**
  String get profileDeleteBody;

  /// No description provided for @addressesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez l\'adresse où le soignant doit se rendre.'**
  String get addressesEmpty;

  /// No description provided for @addressAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une adresse'**
  String get addressAdd;

  /// No description provided for @addressNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse'**
  String get addressNewTitle;

  /// No description provided for @addressEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'adresse'**
  String get addressEditTitle;

  /// No description provided for @addressLabelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'adresse'**
  String get addressLabelLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'Maison, chez ma mère…'**
  String get addressLabelHint;

  /// No description provided for @addressLineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get addressLineLabel;

  /// No description provided for @addressLineHint.
  ///
  /// In fr, this message translates to:
  /// **'Rue, numéro, quartier'**
  String get addressLineHint;

  /// No description provided for @accessNotesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Repères pour trouver la porte'**
  String get accessNotesLabel;

  /// No description provided for @accessNotesHint.
  ///
  /// In fr, this message translates to:
  /// **'Étage, couleur de la porte, commerce voisin…'**
  String get accessNotesHint;

  /// No description provided for @locationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS'**
  String get locationLabel;

  /// No description provided for @locationHelp.
  ///
  /// In fr, this message translates to:
  /// **'À faire sur place, devant la porte du patient.'**
  String get locationHelp;

  /// No description provided for @locationUse.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position actuelle'**
  String get locationUse;

  /// No description provided for @locationSet.
  ///
  /// In fr, this message translates to:
  /// **'Position enregistrée'**
  String get locationSet;

  /// No description provided for @locationMissing.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez la position de cette adresse.'**
  String get locationMissing;

  /// No description provided for @locationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez la localisation pour Nador Care dans les réglages du téléphone.'**
  String get locationDenied;

  /// No description provided for @locationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Activez la localisation (GPS) du téléphone.'**
  String get locationDisabled;

  /// No description provided for @locationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position introuvable. Réessayez à l\'extérieur.'**
  String get locationUnavailable;

  /// No description provided for @addressCovered.
  ///
  /// In fr, this message translates to:
  /// **'Zone desservie'**
  String get addressCovered;

  /// No description provided for @addressNotCovered.
  ///
  /// In fr, this message translates to:
  /// **'Hors zone desservie pour le moment'**
  String get addressNotCovered;

  /// No description provided for @addressDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette adresse ?'**
  String get addressDeleteTitle;

  /// No description provided for @homeCatalogue.
  ///
  /// In fr, this message translates to:
  /// **'Nos soins'**
  String get homeCatalogue;

  /// No description provided for @homeCatalogueSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir les soins proposés à domicile'**
  String get homeCatalogueSubtitle;

  /// No description provided for @catalogueSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un soin'**
  String get catalogueSearchHint;

  /// No description provided for @catalogueEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun soin n\'est proposé pour le moment.'**
  String get catalogueEmpty;

  /// No description provided for @catalogueNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun soin ne correspond à « {query} ».'**
  String catalogueNoResult(String query);

  /// No description provided for @servicesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 soin} other{{count} soins}}'**
  String servicesCount(int count);

  /// No description provided for @serviceDuration.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String serviceDuration(int minutes);

  /// No description provided for @priceDirhams.
  ///
  /// In fr, this message translates to:
  /// **'{amount} DH'**
  String priceDirhams(String amount);

  /// No description provided for @serviceDurationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get serviceDurationLabel;

  /// No description provided for @servicePriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tarif indicatif'**
  String get servicePriceLabel;

  /// No description provided for @servicePriceNote.
  ///
  /// In fr, this message translates to:
  /// **'Le prix peut être majoré la nuit, les jours fériés et selon la distance.'**
  String get servicePriceNote;

  /// No description provided for @servicePrescriptionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnance obligatoire'**
  String get servicePrescriptionRequired;

  /// No description provided for @servicePrescriptionHelp.
  ///
  /// In fr, this message translates to:
  /// **'Pour réserver ce soin, vous devrez déposer une photo de l\'ordonnance.'**
  String get servicePrescriptionHelp;

  /// No description provided for @serviceSeries.
  ///
  /// In fr, this message translates to:
  /// **'Ce soin peut être programmé sur plusieurs jours.'**
  String get serviceSeries;

  /// No description provided for @serviceProvidedBy.
  ///
  /// In fr, this message translates to:
  /// **'Réalisé par : {profession}'**
  String serviceProvidedBy(String profession);

  /// No description provided for @bookingSoon.
  ///
  /// In fr, this message translates to:
  /// **'La réservation arrive bientôt dans l\'application.'**
  String get bookingSoon;
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
