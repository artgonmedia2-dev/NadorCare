// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'nc_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class NcLocalizationsEn extends NcLocalizations {
  NcLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appNamePatient => 'Nador Care';

  @override
  String get appNamePro => 'Nador Care Pro';

  @override
  String get languageName => 'English';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change it at any time in settings.';

  @override
  String get continueButton => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get phoneTitle => 'Your phone number';

  @override
  String get phoneSubtitle => 'We send you a code by SMS to sign you in.';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHint => '06 12 34 56 78';

  @override
  String get phoneHelper => 'From abroad, add the country code: +33, +34, +31…';

  @override
  String get phoneInvalid => 'Enter a valid phone number.';

  @override
  String get sendCode => 'Get the code';

  @override
  String get otpTitle => 'Enter the code you received';

  @override
  String otpSubtitle(String phone) {
    return 'Code sent by SMS to $phone.';
  }

  @override
  String get otpLabel => '6-digit code';

  @override
  String get otpIncomplete => 'Enter the 6 digits of the code.';

  @override
  String get verify => 'Confirm';

  @override
  String get resendCode => 'Resend the code';

  @override
  String resendIn(int seconds) {
    return 'Resend the code in $seconds s';
  }

  @override
  String get codeResent => 'A new code has just been sent.';

  @override
  String get changeNumber => 'Change number';

  @override
  String get consentTitle => 'Before creating your account';

  @override
  String get consentIntro =>
      'Nador Care needs your agreement to create your account.';

  @override
  String get consentTerms => 'I accept the terms of use.';

  @override
  String get consentPrivacy => 'I accept the privacy policy.';

  @override
  String get consentHealthData =>
      'I agree that my health data is used to organise my care. Only the professional who comes to my home can access it.';

  @override
  String get consentRights =>
      'You can view, correct or delete your data at any time from the app.';

  @override
  String get consentAccept => 'Create my account';

  @override
  String get emergencyNotice =>
      'Nador Care does not replace emergency services. In a life-threatening emergency, call 141 or 15.';

  @override
  String get unlockTitle => 'App locked';

  @override
  String get unlockSubtitle => 'Use your fingerprint or face to continue.';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get biometricReason => 'Confirm your identity to open Nador Care';

  @override
  String homeGreeting(String name) {
    return 'Hello $name';
  }

  @override
  String get homeGreetingAnonymous => 'Hello';

  @override
  String get homePatientSoon => 'Care booking is coming soon to this app.';

  @override
  String get homeProSoon => 'Your assignments will arrive soon in this app.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsOpen => 'Open settings';

  @override
  String get nameLabel => 'Your name';

  @override
  String get nameHint => 'First and last name';

  @override
  String get nameTooShort => 'Enter at least 2 characters.';

  @override
  String get profileSaved => 'Your details are saved.';

  @override
  String get languageLabel => 'Language';

  @override
  String get textSizeLabel => 'Text size';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra large';

  @override
  String get biometricLabel => 'Fingerprint or face lock';

  @override
  String get biometricSubtitle => 'Asked every time the app opens.';

  @override
  String get biometricUnavailable =>
      'This device has no fingerprint or face recognition.';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirmTitle => 'Sign out?';

  @override
  String get logoutConfirmBody => 'You will need a new code to sign in again.';

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorUnknown => 'Something went wrong. Try again in a moment.';

  @override
  String get retry => 'Try again';

  @override
  String get delete => 'Delete';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get homeProfiles => 'My patients';

  @override
  String get homeProfilesSubtitle => 'Yourself, a parent, a child';

  @override
  String get homeAddresses => 'My addresses';

  @override
  String get homeAddressesSubtitle => 'Where the caregiver should go';

  @override
  String get profilesEmpty =>
      'Add the person who needs care: yourself or a relative.';

  @override
  String get profileAdd => 'Add a patient';

  @override
  String get profileNewTitle => 'New patient';

  @override
  String get profileEditTitle => 'Edit patient';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get relationshipLabel => 'This person is';

  @override
  String get relationshipSelf => 'Myself';

  @override
  String get relationshipParent => 'My father or mother';

  @override
  String get relationshipChild => 'My child';

  @override
  String get relationshipSpouse => 'My spouse';

  @override
  String get relationshipOther => 'Another relative';

  @override
  String get birthDateLabel => 'Date of birth';

  @override
  String get birthDateChoose => 'Choose a date';

  @override
  String get sexLabel => 'Sex';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexMale => 'Male';

  @override
  String get patientPhoneLabel => 'Patient\'s phone (optional)';

  @override
  String get careNotesLabel => 'Useful information for the caregiver';

  @override
  String get careNotesHint => 'Allergies, illnesses, mobility…';

  @override
  String get careNotesPrivacy =>
      'This information is encrypted. Only the caregiver who visits this patient can see it.';

  @override
  String get profileDeleteTitle => 'Remove this patient?';

  @override
  String get profileDeleteBody => 'Their care history is kept.';

  @override
  String get addressesEmpty => 'Add the address where the caregiver should go.';

  @override
  String get addressAdd => 'Add an address';

  @override
  String get addressNewTitle => 'New address';

  @override
  String get addressEditTitle => 'Edit address';

  @override
  String get addressLabelLabel => 'Address name';

  @override
  String get addressLabelHint => 'Home, my mother\'s place…';

  @override
  String get addressLineLabel => 'Address';

  @override
  String get addressLineHint => 'Street, number, neighbourhood';

  @override
  String get accessNotesLabel => 'Landmarks to find the door';

  @override
  String get accessNotesHint => 'Floor, door colour, nearby shop…';

  @override
  String get locationLabel => 'GPS position';

  @override
  String get locationHelp => 'Do this on site, at the patient\'s door.';

  @override
  String get locationUse => 'Use my current position';

  @override
  String get locationSet => 'Position saved';

  @override
  String get locationMissing => 'Save the position of this address.';

  @override
  String get locationDenied =>
      'Allow location for Nador Care in the phone settings.';

  @override
  String get locationDisabled => 'Turn on the phone\'s location (GPS).';

  @override
  String get locationUnavailable => 'Position not found. Try again outdoors.';

  @override
  String get addressCovered => 'Area served';

  @override
  String get addressNotCovered => 'Outside the area served for now';

  @override
  String get addressDeleteTitle => 'Remove this address?';
}
