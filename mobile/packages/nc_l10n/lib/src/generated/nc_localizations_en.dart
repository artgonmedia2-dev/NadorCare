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

  @override
  String get homeCatalogue => 'Our care services';

  @override
  String get homeCatalogueSubtitle => 'See the care available at home';

  @override
  String get catalogueSearchHint => 'Search for a care service';

  @override
  String get catalogueEmpty => 'No care service is available for now.';

  @override
  String catalogueNoResult(String query) {
    return 'No care service matches “$query”.';
  }

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
    );
    return '$_temp0';
  }

  @override
  String serviceDuration(int minutes) {
    return '$minutes min';
  }

  @override
  String priceDirhams(String amount) {
    return '$amount MAD';
  }

  @override
  String get serviceDurationLabel => 'Duration';

  @override
  String get servicePriceLabel => 'Indicative price';

  @override
  String get servicePriceNote =>
      'The price may be higher at night, on public holidays and depending on distance.';

  @override
  String get servicePrescriptionRequired => 'Prescription required';

  @override
  String get servicePrescriptionHelp =>
      'To book this care, you will need to upload a photo of the prescription.';

  @override
  String get serviceSeries => 'This care can be scheduled over several days.';

  @override
  String serviceProvidedBy(String profession) {
    return 'Provided by: $profession';
  }

  @override
  String get bookingSoon => 'Booking is coming soon to the app.';

  @override
  String get bookService => 'Book this care';

  @override
  String get homeBookings => 'My bookings';

  @override
  String get homeBookingsSubtitle => 'Follow or cancel a request';

  @override
  String get bookingStepPatientTitle => 'Who is this care for?';

  @override
  String get bookingStepAddressTitle => 'Where should the caregiver come?';

  @override
  String get bookingStepSlotTitle => 'When?';

  @override
  String get bookingStepSummaryTitle => 'Check your request';

  @override
  String get bookingNoProfile => 'First add the person who needs care.';

  @override
  String get bookingNoAddress => 'First add the patient\'s address.';

  @override
  String get bookingChoosePatient => 'Choose a patient.';

  @override
  String get bookingChooseAddress => 'Choose an address.';

  @override
  String get bookingAddressNotCovered =>
      'This address is outside the area served for now.';

  @override
  String get slotAsap => 'As soon as possible';

  @override
  String get slotChooseDay => 'Choose a day';

  @override
  String get slotNadorTime => 'Times are Nador times.';

  @override
  String get slotNone => 'No time slot that day. Choose another day.';

  @override
  String get slotChoose => 'Choose a time slot.';

  @override
  String get summaryService => 'Care';

  @override
  String get summaryPatient => 'Patient';

  @override
  String get summaryAddress => 'Address';

  @override
  String get summarySlot => 'Time slot';

  @override
  String get summaryPayment => 'Payment';

  @override
  String get summaryBasePrice => 'Price';

  @override
  String get summaryTotal => 'Total';

  @override
  String get paymentCash => 'Cash, paid to the caregiver';

  @override
  String get noteLabel => 'Note for the caregiver (optional)';

  @override
  String get noteHint => 'Example: ring twice';

  @override
  String get prescriptionCamera => 'Take a photo of the prescription';

  @override
  String get prescriptionGallery => 'Choose a photo of the prescription';

  @override
  String get prescriptionAdded => 'Prescription added';

  @override
  String get prescriptionMissing => 'Add the prescription to send the request.';

  @override
  String get bookingConfirm => 'Send my request';

  @override
  String get bookingSentTitle => 'Request sent';

  @override
  String bookingSentBody(String reference) {
    return 'The coordination team will validate your request $reference. Keep this number.';
  }

  @override
  String get bookingSeeMine => 'See my bookings';

  @override
  String get bookingsEmpty => 'You have no current booking.';

  @override
  String get bookingsPastEmpty => 'No past booking.';

  @override
  String get bookingsUpcoming => 'Current and upcoming';

  @override
  String get bookingsPast => 'Past';

  @override
  String get statusPending => 'Waiting for validation';

  @override
  String get statusConfirmed => 'Confirmed, looking for a caregiver';

  @override
  String get statusAssigned => 'Caregiver assigned';

  @override
  String get statusEnRoute => 'Caregiver on the way';

  @override
  String get statusInProgress => 'Care in progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusDisputed => 'Under review';

  @override
  String bookingReference(String reference) {
    return 'Request $reference';
  }

  @override
  String dateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get bookingCancel => 'Cancel the booking';

  @override
  String get bookingCancelTitle => 'Cancel this booking?';

  @override
  String get bookingCancelFree => 'Cancellation is free.';

  @override
  String bookingCancelFee(String amount) {
    return 'A cancellation fee of $amount MAD applies.';
  }

  @override
  String get bookingCancelConfirm => 'Yes, cancel';

  @override
  String get bookingKeep => 'Keep the booking';

  @override
  String bookingFeeCharged(String amount) {
    return 'Cancellation fee: $amount MAD';
  }

  @override
  String get back => 'Back';

  @override
  String get refresh => 'Refresh';

  @override
  String get proCreateFileTitle => 'Create your professional file';

  @override
  String get proCreateFileIntro =>
      'To receive assignments, your file must be verified by Nador Care.';

  @override
  String get proStart => 'Start';

  @override
  String get professionLabel => 'Your profession';

  @override
  String get professionRequired => 'Choose your profession.';

  @override
  String get licenseNumberLabel => 'Practice authorisation number';

  @override
  String get orderNumberLabel => 'Order registration number';

  @override
  String get proFileTitle => 'My file';

  @override
  String get proDocumentsTitle => 'Documents';

  @override
  String get docIdentity => 'Identity document';

  @override
  String get docDiploma => 'Diploma';

  @override
  String get docPracticeAuthorization => 'Practice authorisation';

  @override
  String get docOrderRegistration => 'Order registration';

  @override
  String get docRcInsurance => 'Professional liability insurance';

  @override
  String get docStatusMissing => 'To upload';

  @override
  String get docStatusPending => 'Uploaded, waiting to be checked';

  @override
  String get docStatusApproved => 'Approved';

  @override
  String docStatusRejected(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String get docStatusExpired => 'Expired, to renew';

  @override
  String get docTakePhoto => 'Take a photo';

  @override
  String get docChoosePhoto => 'Choose a photo';

  @override
  String get docExpiryChoose => 'Insurance expiry date';

  @override
  String get docExpiryRequired =>
      'First enter the expiry date of the insurance.';

  @override
  String docValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get proSubmit => 'Send my file';

  @override
  String get proSubmitIncomplete =>
      'Upload all the documents to send your file.';

  @override
  String get proChangeProfession => 'Change my profession';

  @override
  String get proStatusSubmittedTitle => 'File being verified';

  @override
  String get proStatusSubmittedBody =>
      'We are checking your documents. You will be able to receive assignments once your file is validated.';

  @override
  String get proStatusRejectedTitle => 'Your file needs correcting';

  @override
  String get proStatusSuspendedTitle => 'Account suspended';

  @override
  String get proStatusSuspendedBody =>
      'You no longer receive assignments. Contact the coordination team.';

  @override
  String proReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get proOnline => 'Online';

  @override
  String get proOffline => 'Offline';

  @override
  String get proOnlineHelp => 'When online, you can receive assignment offers.';

  @override
  String get proZones => 'My areas';

  @override
  String get proZonesTitle => 'Areas where you work';

  @override
  String get proZonesEmpty => 'No area is open yet.';

  @override
  String proZonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count areas',
      one: '1 area',
      zero: 'No area chosen',
    );
    return '$_temp0';
  }

  @override
  String get proSchedule => 'My schedule';

  @override
  String get proScheduleTitle => 'Working days and hours';

  @override
  String get proScheduleHelp => 'Times are Nador times.';

  @override
  String proScheduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days a week',
      one: '1 day a week',
      zero: 'No working day',
    );
    return '$_temp0';
  }

  @override
  String scheduleRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String get scheduleStart => 'Start';

  @override
  String get scheduleEnd => 'End';

  @override
  String get scheduleInvalid => 'The end time must be after the start time.';

  @override
  String get proOffersTitle => 'Assignment offers';

  @override
  String get proOffersEmpty => 'No offer for now.';

  @override
  String offerAnswerBefore(String time) {
    return 'Answer before $time';
  }

  @override
  String offerDistance(String distance) {
    return '$distance away';
  }

  @override
  String get offerAccept => 'Accept';

  @override
  String get offerDecline => 'Decline';

  @override
  String get proMissionsTitle => 'My assignments';

  @override
  String get proMissionsEmpty => 'No assignment.';

  @override
  String get missionStatusAssigned => 'Upcoming';

  @override
  String get missionStatusEnRoute => 'On the way';

  @override
  String get missionStatusInProgress => 'In progress';

  @override
  String get missionAccessNotes => 'Access landmarks';

  @override
  String get missionCareNotes => 'Useful information for the care';

  @override
  String get missionPatientNote => 'Patient\'s note';

  @override
  String get missionAmount => 'Cash to collect';

  @override
  String get missionPrescription =>
      'A prescription is attached to the request.';

  @override
  String get missionWithdraw => 'Withdraw';

  @override
  String get missionWithdrawTitle => 'Withdraw from this assignment?';

  @override
  String get missionWithdrawBody =>
      'The coordination team will look for another caregiver.';

  @override
  String get missionWithdrawReason => 'Reason';

  @override
  String get add => 'Add';

  @override
  String get missionDepart => 'I\'m leaving';

  @override
  String get missionArrive => 'I have arrived';

  @override
  String get missionOpenReport => 'Write the report';

  @override
  String get journeySharing =>
      'Your location is shared with the patient until you arrive.';

  @override
  String get journeyLocationOff =>
      'Location unavailable. Turn on location so the patient can follow your arrival.';

  @override
  String journeyEta(int minutes) {
    return 'Estimated arrival in $minutes min';
  }

  @override
  String get reportTitle => 'Care report';

  @override
  String get reportVitalsTitle => 'Vital signs';

  @override
  String get vitalSystolic => 'Systolic pressure (mmHg)';

  @override
  String get vitalDiastolic => 'Diastolic pressure (mmHg)';

  @override
  String get vitalPulse => 'Pulse (beats/min)';

  @override
  String get vitalTemperature => 'Temperature (°C)';

  @override
  String get vitalGlucose => 'Blood glucose (g/L)';

  @override
  String get vitalSpo2 => 'Oxygen saturation (%)';

  @override
  String vitalOutOfRange(String min, String max) {
    return 'Expected a value between $min and $max.';
  }

  @override
  String get reportObservations => 'Observations';

  @override
  String get reportObservationsRequired => 'Describe the care provided.';

  @override
  String get reportActsTitle => 'Procedures performed';

  @override
  String get reportActAdd => 'Add a procedure';

  @override
  String get reportConsumablesTitle => 'Supplies used';

  @override
  String get reportConsumableAdd => 'Add a supply';

  @override
  String get reportLineLabel => 'Description';

  @override
  String get reportLineQuantity => 'Quantity';

  @override
  String reportLineWithQuantity(String label, String quantity) {
    return '$label × $quantity';
  }

  @override
  String get reportPhotosTitle => 'Photos';

  @override
  String reportPhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
      zero: 'No photo',
    );
    return '$_temp0';
  }

  @override
  String get reportPhotoAdd => 'Add a photo';

  @override
  String get reportSignatureTitle => 'Patient signature';

  @override
  String get reportSign => 'Get signature';

  @override
  String get reportSignAgain => 'Sign again';

  @override
  String reportSignedBy(String name) {
    return 'Signed by $name';
  }

  @override
  String get reportNotSigned => 'Not signed yet';

  @override
  String get signatureName => 'Name of the person signing';

  @override
  String get signatureHelp =>
      'The patient, or a relative who is present, signs in the box with a finger.';

  @override
  String get signatureClear => 'Clear';

  @override
  String get signatureConfirm => 'Confirm signature';

  @override
  String get signatureEmpty => 'The signature is empty.';

  @override
  String reportCashCollected(String amount) {
    return 'I received $amount in cash';
  }

  @override
  String get reportSaveDraft => 'Save draft';

  @override
  String get reportSaved => 'Draft saved.';

  @override
  String get reportComplete => 'Finish the visit';

  @override
  String get reportCompleteTitle => 'Finish the visit?';

  @override
  String get reportCompleteBody =>
      'The report will be validated and can no longer be changed.';

  @override
  String get reportSignatureRequired =>
      'Get the patient signature before finishing.';

  @override
  String get reportCompleted => 'Visit finished. The report is validated.';

  @override
  String get bookingProfessional => 'Caregiver';

  @override
  String get trackingOnTheWay => 'Your caregiver is on the way.';

  @override
  String trackingEta(int minutes) {
    return 'Your caregiver arrives in about $minutes min.';
  }

  @override
  String get bookingReportOpen => 'View the report';

  @override
  String reportAmended(String reason) {
    return 'This report was corrected. Reason: $reason';
  }
}
