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

  /// No description provided for @homePatientIntro.
  ///
  /// In fr, this message translates to:
  /// **'De quel soin avez-vous besoin aujourd\'hui ?'**
  String get homePatientIntro;

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

  /// No description provided for @bookService.
  ///
  /// In fr, this message translates to:
  /// **'Réserver ce soin'**
  String get bookService;

  /// No description provided for @homeBookings.
  ///
  /// In fr, this message translates to:
  /// **'Mes réservations'**
  String get homeBookings;

  /// No description provided for @homeBookingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivre ou annuler une demande'**
  String get homeBookingsSubtitle;

  /// No description provided for @bookingStepPatientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour qui est ce soin ?'**
  String get bookingStepPatientTitle;

  /// No description provided for @bookingStepAddressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où le soignant doit-il venir ?'**
  String get bookingStepAddressTitle;

  /// No description provided for @bookingStepSlotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quand ?'**
  String get bookingStepSlotTitle;

  /// No description provided for @bookingStepSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre demande'**
  String get bookingStepSummaryTitle;

  /// No description provided for @bookingNoProfile.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord la personne à soigner.'**
  String get bookingNoProfile;

  /// No description provided for @bookingNoAddress.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord l\'adresse du patient.'**
  String get bookingNoAddress;

  /// No description provided for @bookingChoosePatient.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un patient.'**
  String get bookingChoosePatient;

  /// No description provided for @bookingChooseAddress.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une adresse.'**
  String get bookingChooseAddress;

  /// No description provided for @bookingAddressNotCovered.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse est hors de la zone desservie pour le moment.'**
  String get bookingAddressNotCovered;

  /// No description provided for @slotAsap.
  ///
  /// In fr, this message translates to:
  /// **'Dès que possible'**
  String get slotAsap;

  /// No description provided for @slotChooseDay.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un jour'**
  String get slotChooseDay;

  /// No description provided for @slotNadorTime.
  ///
  /// In fr, this message translates to:
  /// **'Les heures sont celles de Nador.'**
  String get slotNadorTime;

  /// No description provided for @slotNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun créneau ce jour-là. Choisissez un autre jour.'**
  String get slotNone;

  /// No description provided for @slotChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un créneau.'**
  String get slotChoose;

  /// No description provided for @summaryService.
  ///
  /// In fr, this message translates to:
  /// **'Soin'**
  String get summaryService;

  /// No description provided for @summaryPatient.
  ///
  /// In fr, this message translates to:
  /// **'Patient'**
  String get summaryPatient;

  /// No description provided for @summaryAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get summaryAddress;

  /// No description provided for @summarySlot.
  ///
  /// In fr, this message translates to:
  /// **'Créneau'**
  String get summarySlot;

  /// No description provided for @summaryPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get summaryPayment;

  /// No description provided for @summaryBasePrice.
  ///
  /// In fr, this message translates to:
  /// **'Tarif'**
  String get summaryBasePrice;

  /// No description provided for @summaryTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get summaryTotal;

  /// No description provided for @paymentCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces, à régler au soignant'**
  String get paymentCash;

  /// No description provided for @noteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note pour le soignant (facultatif)'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In fr, this message translates to:
  /// **'Exemple : sonner deux fois'**
  String get noteHint;

  /// No description provided for @prescriptionCamera.
  ///
  /// In fr, this message translates to:
  /// **'Prendre l\'ordonnance en photo'**
  String get prescriptionCamera;

  /// No description provided for @prescriptionGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo de l\'ordonnance'**
  String get prescriptionGallery;

  /// No description provided for @prescriptionAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnance ajoutée'**
  String get prescriptionAdded;

  /// No description provided for @prescriptionMissing.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez l\'ordonnance pour envoyer la demande.'**
  String get prescriptionMissing;

  /// No description provided for @bookingConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer ma demande'**
  String get bookingConfirm;

  /// No description provided for @bookingSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get bookingSentTitle;

  /// No description provided for @bookingSentBody.
  ///
  /// In fr, this message translates to:
  /// **'La coordination va valider votre demande {reference}. Gardez ce numéro.'**
  String bookingSentBody(String reference);

  /// No description provided for @bookingSeeMine.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes réservations'**
  String get bookingSeeMine;

  /// No description provided for @bookingsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez aucune réservation en cours.'**
  String get bookingsEmpty;

  /// No description provided for @bookingsPastEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation passée.'**
  String get bookingsPastEmpty;

  /// No description provided for @bookingsUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'En cours et à venir'**
  String get bookingsUpcoming;

  /// No description provided for @bookingsPast.
  ///
  /// In fr, this message translates to:
  /// **'Passées'**
  String get bookingsPast;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée, recherche d\'un soignant'**
  String get statusConfirmed;

  /// No description provided for @statusAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Soignant affecté'**
  String get statusAssigned;

  /// No description provided for @statusEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'Soignant en route'**
  String get statusEnRoute;

  /// No description provided for @statusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Soin en cours'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get statusCancelled;

  /// No description provided for @statusDisputed.
  ///
  /// In fr, this message translates to:
  /// **'En cours d\'examen'**
  String get statusDisputed;

  /// No description provided for @bookingReference.
  ///
  /// In fr, this message translates to:
  /// **'Demande {reference}'**
  String bookingReference(String reference);

  /// No description provided for @dateAtTime.
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String dateAtTime(String date, String time);

  /// No description provided for @bookingCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation'**
  String get bookingCancel;

  /// No description provided for @bookingCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette réservation ?'**
  String get bookingCancelTitle;

  /// No description provided for @bookingCancelFree.
  ///
  /// In fr, this message translates to:
  /// **'L\'annulation est gratuite.'**
  String get bookingCancelFree;

  /// No description provided for @bookingCancelFee.
  ///
  /// In fr, this message translates to:
  /// **'Des frais d\'annulation de {amount} DH s\'appliquent.'**
  String bookingCancelFee(String amount);

  /// No description provided for @bookingCancelConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get bookingCancelConfirm;

  /// No description provided for @bookingKeep.
  ///
  /// In fr, this message translates to:
  /// **'Garder la réservation'**
  String get bookingKeep;

  /// No description provided for @bookingFeeCharged.
  ///
  /// In fr, this message translates to:
  /// **'Frais d\'annulation : {amount} DH'**
  String bookingFeeCharged(String amount);

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @proCreateFileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre dossier professionnel'**
  String get proCreateFileTitle;

  /// No description provided for @proCreateFileIntro.
  ///
  /// In fr, this message translates to:
  /// **'Pour recevoir des missions, votre dossier doit être vérifié par Nador Care.'**
  String get proCreateFileIntro;

  /// No description provided for @proStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get proStart;

  /// No description provided for @professionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre profession'**
  String get professionLabel;

  /// No description provided for @professionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre profession.'**
  String get professionRequired;

  /// No description provided for @licenseNumberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro d\'autorisation d\'exercice'**
  String get licenseNumberLabel;

  /// No description provided for @orderNumberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro d\'inscription à l\'Ordre'**
  String get orderNumberLabel;

  /// No description provided for @proFileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon dossier'**
  String get proFileTitle;

  /// No description provided for @proDocumentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Justificatifs'**
  String get proDocumentsTitle;

  /// No description provided for @docIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'identité'**
  String get docIdentity;

  /// No description provided for @docDiploma.
  ///
  /// In fr, this message translates to:
  /// **'Diplôme'**
  String get docDiploma;

  /// No description provided for @docPracticeAuthorization.
  ///
  /// In fr, this message translates to:
  /// **'Autorisation d\'exercice'**
  String get docPracticeAuthorization;

  /// No description provided for @docOrderRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Inscription à l\'Ordre'**
  String get docOrderRegistration;

  /// No description provided for @docRcInsurance.
  ///
  /// In fr, this message translates to:
  /// **'Assurance responsabilité civile'**
  String get docRcInsurance;

  /// No description provided for @docStatusMissing.
  ///
  /// In fr, this message translates to:
  /// **'À déposer'**
  String get docStatusMissing;

  /// No description provided for @docStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'Déposé, en attente de contrôle'**
  String get docStatusPending;

  /// No description provided for @docStatusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Approuvé'**
  String get docStatusApproved;

  /// No description provided for @docStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusé : {reason}'**
  String docStatusRejected(String reason);

  /// No description provided for @docStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Périmé, à renouveler'**
  String get docStatusExpired;

  /// No description provided for @docTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre en photo'**
  String get docTakePhoto;

  /// No description provided for @docChoosePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo'**
  String get docChoosePhoto;

  /// No description provided for @docExpiryChoose.
  ///
  /// In fr, this message translates to:
  /// **'Date de fin de validité de l\'assurance'**
  String get docExpiryChoose;

  /// No description provided for @docExpiryRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez d\'abord la date de fin de validité de l\'assurance.'**
  String get docExpiryRequired;

  /// No description provided for @docValidUntil.
  ///
  /// In fr, this message translates to:
  /// **'Valable jusqu\'au {date}'**
  String docValidUntil(String date);

  /// No description provided for @proSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon dossier'**
  String get proSubmit;

  /// No description provided for @proSubmitIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Déposez tous les justificatifs pour envoyer votre dossier.'**
  String get proSubmitIncomplete;

  /// No description provided for @proChangeProfession.
  ///
  /// In fr, this message translates to:
  /// **'Modifier ma profession'**
  String get proChangeProfession;

  /// No description provided for @proStatusSubmittedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dossier en cours de vérification'**
  String get proStatusSubmittedTitle;

  /// No description provided for @proStatusSubmittedBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous vérifions vos justificatifs. Vous pourrez recevoir des missions dès que votre dossier sera validé.'**
  String get proStatusSubmittedBody;

  /// No description provided for @proStatusRejectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre dossier est à corriger'**
  String get proStatusRejectedTitle;

  /// No description provided for @proStatusSuspendedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu'**
  String get proStatusSuspendedTitle;

  /// No description provided for @proStatusSuspendedBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne recevez plus de mission. Contactez la coordination.'**
  String get proStatusSuspendedBody;

  /// No description provided for @proReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String proReason(String reason);

  /// No description provided for @proOnline.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get proOnline;

  /// No description provided for @proOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get proOffline;

  /// No description provided for @proOnlineHelp.
  ///
  /// In fr, this message translates to:
  /// **'En ligne, vous pouvez recevoir des propositions de mission.'**
  String get proOnlineHelp;

  /// No description provided for @proZones.
  ///
  /// In fr, this message translates to:
  /// **'Mes zones'**
  String get proZones;

  /// No description provided for @proZonesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Zones où vous intervenez'**
  String get proZonesTitle;

  /// No description provided for @proZonesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune zone n\'est encore ouverte.'**
  String get proZonesEmpty;

  /// No description provided for @proZonesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune zone choisie} =1{1 zone} other{{count} zones}}'**
  String proZonesCount(int count);

  /// No description provided for @proSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Mon agenda'**
  String get proSchedule;

  /// No description provided for @proScheduleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jours et heures de travail'**
  String get proScheduleTitle;

  /// No description provided for @proScheduleHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les heures sont celles de Nador.'**
  String get proScheduleHelp;

  /// No description provided for @proScheduleCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun jour travaillé} =1{1 jour par semaine} other{{count} jours par semaine}}'**
  String proScheduleCount(int count);

  /// No description provided for @scheduleRange.
  ///
  /// In fr, this message translates to:
  /// **'{start} à {end}'**
  String scheduleRange(String start, String end);

  /// No description provided for @scheduleStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get scheduleStart;

  /// No description provided for @scheduleEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get scheduleEnd;

  /// No description provided for @scheduleInvalid.
  ///
  /// In fr, this message translates to:
  /// **'L\'heure de fin doit être après l\'heure de début.'**
  String get scheduleInvalid;

  /// No description provided for @proOffersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Propositions de mission'**
  String get proOffersTitle;

  /// No description provided for @proOffersEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition pour le moment.'**
  String get proOffersEmpty;

  /// No description provided for @offerAnswerBefore.
  ///
  /// In fr, this message translates to:
  /// **'Répondre avant {time}'**
  String offerAnswerBefore(String time);

  /// No description provided for @offerDistance.
  ///
  /// In fr, this message translates to:
  /// **'À {distance}'**
  String offerDistance(String distance);

  /// No description provided for @offerAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get offerAccept;

  /// No description provided for @offerDecline.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get offerDecline;

  /// No description provided for @proMissionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes missions'**
  String get proMissionsTitle;

  /// No description provided for @proMissionsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mission affectée.'**
  String get proMissionsEmpty;

  /// No description provided for @missionStatusAssigned.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get missionStatusAssigned;

  /// No description provided for @missionStatusEnRoute.
  ///
  /// In fr, this message translates to:
  /// **'En route'**
  String get missionStatusEnRoute;

  /// No description provided for @missionStatusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get missionStatusInProgress;

  /// No description provided for @missionAccessNotes.
  ///
  /// In fr, this message translates to:
  /// **'Repères d\'accès'**
  String get missionAccessNotes;

  /// No description provided for @missionCareNotes.
  ///
  /// In fr, this message translates to:
  /// **'Informations utiles au soin'**
  String get missionCareNotes;

  /// No description provided for @missionPatientNote.
  ///
  /// In fr, this message translates to:
  /// **'Note du patient'**
  String get missionPatientNote;

  /// No description provided for @missionAmount.
  ///
  /// In fr, this message translates to:
  /// **'À encaisser en espèces'**
  String get missionAmount;

  /// No description provided for @missionPrescription.
  ///
  /// In fr, this message translates to:
  /// **'Une ordonnance est jointe à la demande.'**
  String get missionPrescription;

  /// No description provided for @missionWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Me désister'**
  String get missionWithdraw;

  /// No description provided for @missionWithdrawTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous désister de cette mission ?'**
  String get missionWithdrawTitle;

  /// No description provided for @missionWithdrawBody.
  ///
  /// In fr, this message translates to:
  /// **'La coordination cherchera un autre soignant.'**
  String get missionWithdrawBody;

  /// No description provided for @missionWithdrawReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get missionWithdrawReason;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @missionDepart.
  ///
  /// In fr, this message translates to:
  /// **'Je pars'**
  String get missionDepart;

  /// No description provided for @missionArrive.
  ///
  /// In fr, this message translates to:
  /// **'Je suis arrivé'**
  String get missionArrive;

  /// No description provided for @missionOpenReport.
  ///
  /// In fr, this message translates to:
  /// **'Rédiger le compte rendu'**
  String get missionOpenReport;

  /// No description provided for @journeySharing.
  ///
  /// In fr, this message translates to:
  /// **'Votre position est partagée avec le patient jusqu\'à votre arrivée.'**
  String get journeySharing;

  /// No description provided for @journeyLocationOff.
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible. Activez la localisation pour que le patient suive votre arrivée.'**
  String get journeyLocationOff;

  /// No description provided for @journeyEta.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée estimée dans {minutes} min'**
  String journeyEta(int minutes);

  /// No description provided for @reportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte rendu'**
  String get reportTitle;

  /// No description provided for @reportVitalsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Constantes'**
  String get reportVitalsTitle;

  /// No description provided for @vitalSystolic.
  ///
  /// In fr, this message translates to:
  /// **'Tension systolique (mmHg)'**
  String get vitalSystolic;

  /// No description provided for @vitalDiastolic.
  ///
  /// In fr, this message translates to:
  /// **'Tension diastolique (mmHg)'**
  String get vitalDiastolic;

  /// No description provided for @vitalPulse.
  ///
  /// In fr, this message translates to:
  /// **'Pouls (battements/min)'**
  String get vitalPulse;

  /// No description provided for @vitalTemperature.
  ///
  /// In fr, this message translates to:
  /// **'Température (°C)'**
  String get vitalTemperature;

  /// No description provided for @vitalGlucose.
  ///
  /// In fr, this message translates to:
  /// **'Glycémie (g/L)'**
  String get vitalGlucose;

  /// No description provided for @vitalSpo2.
  ///
  /// In fr, this message translates to:
  /// **'Saturation en oxygène (%)'**
  String get vitalSpo2;

  /// No description provided for @vitalOutOfRange.
  ///
  /// In fr, this message translates to:
  /// **'Valeur attendue entre {min} et {max}.'**
  String vitalOutOfRange(String min, String max);

  /// No description provided for @reportObservations.
  ///
  /// In fr, this message translates to:
  /// **'Observations'**
  String get reportObservations;

  /// No description provided for @reportObservationsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le soin réalisé.'**
  String get reportObservationsRequired;

  /// No description provided for @reportActsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Actes réalisés'**
  String get reportActsTitle;

  /// No description provided for @reportActAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un acte'**
  String get reportActAdd;

  /// No description provided for @reportConsumablesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Consommables utilisés'**
  String get reportConsumablesTitle;

  /// No description provided for @reportConsumableAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un consommable'**
  String get reportConsumableAdd;

  /// No description provided for @reportLineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Désignation'**
  String get reportLineLabel;

  /// No description provided for @reportLineQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get reportLineQuantity;

  /// No description provided for @reportLineWithQuantity.
  ///
  /// In fr, this message translates to:
  /// **'{label} × {quantity}'**
  String reportLineWithQuantity(String label, String quantity);

  /// No description provided for @reportPhotosTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get reportPhotosTitle;

  /// No description provided for @reportPhotosCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune photo} =1{1 photo} other{{count} photos}}'**
  String reportPhotosCount(int count);

  /// No description provided for @reportPhotoAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get reportPhotoAdd;

  /// No description provided for @reportSignatureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signature du patient'**
  String get reportSignatureTitle;

  /// No description provided for @reportSign.
  ///
  /// In fr, this message translates to:
  /// **'Faire signer'**
  String get reportSign;

  /// No description provided for @reportSignAgain.
  ///
  /// In fr, this message translates to:
  /// **'Refaire signer'**
  String get reportSignAgain;

  /// No description provided for @reportSignedBy.
  ///
  /// In fr, this message translates to:
  /// **'Signé par {name}'**
  String reportSignedBy(String name);

  /// No description provided for @reportNotSigned.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore signé'**
  String get reportNotSigned;

  /// No description provided for @signatureName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la personne qui signe'**
  String get signatureName;

  /// No description provided for @signatureHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le patient, ou un proche présent, signe dans le cadre avec le doigt.'**
  String get signatureHelp;

  /// No description provided for @signatureClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get signatureClear;

  /// No description provided for @signatureConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Valider la signature'**
  String get signatureConfirm;

  /// No description provided for @signatureEmpty.
  ///
  /// In fr, this message translates to:
  /// **'La signature est vide.'**
  String get signatureEmpty;

  /// No description provided for @reportCashCollected.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai reçu {amount} en espèces'**
  String reportCashCollected(String amount);

  /// No description provided for @reportSaveDraft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le brouillon'**
  String get reportSaveDraft;

  /// No description provided for @reportSaved.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon enregistré.'**
  String get reportSaved;

  /// No description provided for @reportComplete.
  ///
  /// In fr, this message translates to:
  /// **'Terminer l\'intervention'**
  String get reportComplete;

  /// No description provided for @reportCompleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Terminer l\'intervention ?'**
  String get reportCompleteTitle;

  /// No description provided for @reportCompleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Le compte rendu sera validé : il ne pourra plus être modifié.'**
  String get reportCompleteBody;

  /// No description provided for @reportSignatureRequired.
  ///
  /// In fr, this message translates to:
  /// **'Faites signer le patient avant de terminer.'**
  String get reportSignatureRequired;

  /// No description provided for @reportCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Intervention terminée. Le compte rendu est validé.'**
  String get reportCompleted;

  /// No description provided for @bookingProfessional.
  ///
  /// In fr, this message translates to:
  /// **'Soignant'**
  String get bookingProfessional;

  /// No description provided for @trackingOnTheWay.
  ///
  /// In fr, this message translates to:
  /// **'Votre soignant est en route.'**
  String get trackingOnTheWay;

  /// No description provided for @trackingEta.
  ///
  /// In fr, this message translates to:
  /// **'Votre soignant arrive dans environ {minutes} min.'**
  String trackingEta(int minutes);

  /// No description provided for @bookingReportOpen.
  ///
  /// In fr, this message translates to:
  /// **'Voir le compte rendu'**
  String get bookingReportOpen;

  /// No description provided for @reportAmended.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte rendu a été corrigé. Motif : {reason}'**
  String reportAmended(String reason);

  /// No description provided for @proScheduleMissing.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez indiqué aucun jour de travail. Renseignez votre agenda pour recevoir les propositions qui vous conviennent.'**
  String get proScheduleMissing;

  /// No description provided for @proScheduleSetUp.
  ///
  /// In fr, this message translates to:
  /// **'Renseigner mon agenda'**
  String get proScheduleSetUp;

  /// No description provided for @proZonesMissing.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez choisi aucune zone. Indiquez où vous acceptez d\'intervenir.'**
  String get proZonesMissing;

  /// No description provided for @proZonesSetUp.
  ///
  /// In fr, this message translates to:
  /// **'Choisir mes zones'**
  String get proZonesSetUp;

  /// No description provided for @proAccountSection.
  ///
  /// In fr, this message translates to:
  /// **'Mon activité'**
  String get proAccountSection;

  /// No description provided for @docRenewInsurance.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler l\'assurance'**
  String get docRenewInsurance;

  /// No description provided for @stepProgress.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @teleconsultationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléconsultation'**
  String get teleconsultationLabel;

  /// No description provided for @teleconsultationServiceNote.
  ///
  /// In fr, this message translates to:
  /// **'Ce soin se fait par appel vidéo dans l\'application, sans déplacement.'**
  String get teleconsultationServiceNote;

  /// No description provided for @teleconsultationJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre la téléconsultation'**
  String get teleconsultationJoin;

  /// No description provided for @teleconsultationStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer la téléconsultation'**
  String get teleconsultationStart;

  /// No description provided for @teleconsultationRoomHelp.
  ///
  /// In fr, this message translates to:
  /// **'La salle ouvre quelques minutes avant l\'heure prévue.'**
  String get teleconsultationRoomHelp;

  /// No description provided for @teleconsultationNoJourney.
  ///
  /// In fr, this message translates to:
  /// **'Téléconsultation : aucun déplacement.'**
  String get teleconsultationNoJourney;

  /// No description provided for @callConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à la salle…'**
  String get callConnecting;

  /// No description provided for @callInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Appel en cours'**
  String get callInProgress;

  /// No description provided for @callSimulated.
  ///
  /// In fr, this message translates to:
  /// **'Appel simulé : le service vidéo n\'est pas encore branché.'**
  String get callSimulated;

  /// No description provided for @callHangUp.
  ///
  /// In fr, this message translates to:
  /// **'Raccrocher'**
  String get callHangUp;

  /// No description provided for @callMute.
  ///
  /// In fr, this message translates to:
  /// **'Couper le micro'**
  String get callMute;

  /// No description provided for @callUnmute.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver le micro'**
  String get callUnmute;

  /// No description provided for @callCameraOff.
  ///
  /// In fr, this message translates to:
  /// **'Couper la caméra'**
  String get callCameraOff;

  /// No description provided for @callCameraOn.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver la caméra'**
  String get callCameraOn;

  /// No description provided for @paymentCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get paymentCard;
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
