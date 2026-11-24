// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'nc_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class NcLocalizationsAr extends NcLocalizations {
  NcLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appNamePatient => 'Nador Care';

  @override
  String get appNamePro => 'Nador Care Pro';

  @override
  String get languageName => 'العربية';

  @override
  String get languageTitle => 'اختر لغتك';

  @override
  String get languageSubtitle => 'يمكنك تغييرها في أي وقت من الإعدادات.';

  @override
  String get continueButton => 'متابعة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get phoneTitle => 'رقم هاتفك';

  @override
  String get phoneSubtitle => 'نرسل إليك رمزا عبر رسالة قصيرة لتسجيل الدخول.';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phoneHint => '06 12 34 56 78';

  @override
  String get phoneHelper => 'من خارج المغرب، أضف رمز البلد: 33+، 34+، 31+…';

  @override
  String get phoneInvalid => 'أدخل رقم هاتف صحيحا.';

  @override
  String get sendCode => 'استلام الرمز';

  @override
  String get otpTitle => 'أدخل الرمز الذي وصلك';

  @override
  String otpSubtitle(String phone) {
    return 'تم إرسال الرمز عبر رسالة قصيرة إلى $phone.';
  }

  @override
  String get otpLabel => 'رمز من 6 أرقام';

  @override
  String get otpIncomplete => 'أدخل أرقام الرمز الستة.';

  @override
  String get verify => 'تأكيد';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendIn(int seconds) {
    return 'إعادة إرسال الرمز بعد $seconds ث';
  }

  @override
  String get codeResent => 'تم إرسال رمز جديد.';

  @override
  String get changeNumber => 'تغيير الرقم';

  @override
  String get consentTitle => 'قبل إنشاء حسابك';

  @override
  String get consentIntro => 'يحتاج Nador Care إلى موافقتك لإنشاء حسابك.';

  @override
  String get consentTerms => 'أوافق على الشروط العامة للاستخدام.';

  @override
  String get consentPrivacy => 'أوافق على سياسة الخصوصية.';

  @override
  String get consentHealthData =>
      'أوافق على استعمال بياناتي الصحية لتنظيم علاجي. لا يطلع عليها إلا المهني الذي يأتي إلى منزلي.';

  @override
  String get consentRights =>
      'يمكنك الاطلاع على بياناتك أو تصحيحها أو حذفها في أي وقت من التطبيق.';

  @override
  String get consentAccept => 'إنشاء حسابي';

  @override
  String get emergencyNotice =>
      'Nador Care لا يعوض المستعجلات. في حالة خطر على الحياة، اتصل بالرقم 141 أو 15.';

  @override
  String get unlockTitle => 'التطبيق مقفل';

  @override
  String get unlockSubtitle => 'استعمل بصمتك أو وجهك للمتابعة.';

  @override
  String get unlockButton => 'فتح القفل';

  @override
  String get biometricReason => 'أكد هويتك لفتح Nador Care';

  @override
  String homeGreeting(String name) {
    return 'مرحبا $name';
  }

  @override
  String get homeGreetingAnonymous => 'مرحبا';

  @override
  String get homePatientIntro => 'ما الرعاية التي تحتاجها اليوم؟';

  @override
  String get homeProSoon => 'مهامك ستصل قريبا إلى هذا التطبيق.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsOpen => 'فتح الإعدادات';

  @override
  String get nameLabel => 'اسمك';

  @override
  String get nameHint => 'الاسم الشخصي والعائلي';

  @override
  String get nameTooShort => 'أدخل حرفين على الأقل.';

  @override
  String get profileSaved => 'تم حفظ معلوماتك.';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get textSizeLabel => 'حجم النص';

  @override
  String get textSizeNormal => 'عادي';

  @override
  String get textSizeLarge => 'كبير';

  @override
  String get textSizeExtraLarge => 'كبير جدا';

  @override
  String get biometricLabel => 'القفل بالبصمة أو الوجه';

  @override
  String get biometricSubtitle => 'يطلب عند كل فتح للتطبيق.';

  @override
  String get biometricUnavailable =>
      'هذا الجهاز لا يدعم البصمة ولا التعرف على الوجه.';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get logoutConfirmBody => 'ستحتاج إلى رمز جديد لتسجيل الدخول من جديد.';

  @override
  String get errorNetwork => 'لا يوجد اتصال. تحقق من الشبكة وحاول من جديد.';

  @override
  String get errorUnknown => 'حدث خطأ. حاول بعد قليل.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get delete => 'حذف';

  @override
  String get fieldRequired => 'هذه الخانة إجبارية.';

  @override
  String get homeProfiles => 'مرضاي';

  @override
  String get homeProfilesSubtitle => 'أنت، أحد والديك، طفلك';

  @override
  String get homeAddresses => 'عناويني';

  @override
  String get homeAddressesSubtitle => 'المكان الذي سيأتي إليه المعالج';

  @override
  String get profilesEmpty =>
      'أضف الشخص الذي يحتاج إلى العلاج: أنت أو أحد أقاربك.';

  @override
  String get profileAdd => 'إضافة مريض';

  @override
  String get profileNewTitle => 'مريض جديد';

  @override
  String get profileEditTitle => 'تعديل المريض';

  @override
  String get firstNameLabel => 'الاسم الشخصي';

  @override
  String get lastNameLabel => 'الاسم العائلي';

  @override
  String get relationshipLabel => 'هذا الشخص هو';

  @override
  String get relationshipSelf => 'أنا';

  @override
  String get relationshipParent => 'أبي أو أمي';

  @override
  String get relationshipChild => 'طفلي';

  @override
  String get relationshipSpouse => 'زوجي أو زوجتي';

  @override
  String get relationshipOther => 'قريب آخر';

  @override
  String get birthDateLabel => 'تاريخ الازدياد';

  @override
  String get birthDateChoose => 'اختيار تاريخ';

  @override
  String get sexLabel => 'الجنس';

  @override
  String get sexFemale => 'أنثى';

  @override
  String get sexMale => 'ذكر';

  @override
  String get patientPhoneLabel => 'هاتف المريض (اختياري)';

  @override
  String get careNotesLabel => 'معلومات مفيدة للمعالج';

  @override
  String get careNotesHint => 'الحساسية، الأمراض، الحركة…';

  @override
  String get careNotesPrivacy =>
      'هذه المعلومات مشفرة. لا يراها إلا المعالج الذي يزور هذا المريض.';

  @override
  String get profileDeleteTitle => 'حذف هذا المريض؟';

  @override
  String get profileDeleteBody => 'يبقى سجل علاجاته محفوظا.';

  @override
  String get addressesEmpty => 'أضف العنوان الذي سيأتي إليه المعالج.';

  @override
  String get addressAdd => 'إضافة عنوان';

  @override
  String get addressNewTitle => 'عنوان جديد';

  @override
  String get addressEditTitle => 'تعديل العنوان';

  @override
  String get addressLabelLabel => 'اسم العنوان';

  @override
  String get addressLabelHint => 'المنزل، عند أمي…';

  @override
  String get addressLineLabel => 'العنوان';

  @override
  String get addressLineHint => 'الزنقة، الرقم، الحي';

  @override
  String get accessNotesLabel => 'علامات للوصول إلى الباب';

  @override
  String get accessNotesHint => 'الطابق، لون الباب، متجر قريب…';

  @override
  String get locationLabel => 'الموقع GPS';

  @override
  String get locationHelp => 'قم بذلك في عين المكان، أمام باب المريض.';

  @override
  String get locationUse => 'استعمال موقعي الحالي';

  @override
  String get locationSet => 'تم حفظ الموقع';

  @override
  String get locationMissing => 'احفظ موقع هذا العنوان.';

  @override
  String get locationDenied =>
      'اسمح لـ Nador Care باستعمال الموقع من إعدادات الهاتف.';

  @override
  String get locationDisabled => 'شغل خدمة الموقع (GPS) في الهاتف.';

  @override
  String get locationUnavailable =>
      'تعذر تحديد الموقع. حاول من جديد في الخارج.';

  @override
  String get addressCovered => 'منطقة مغطاة';

  @override
  String get addressNotCovered => 'خارج المنطقة المغطاة حاليا';

  @override
  String get addressDeleteTitle => 'حذف هذا العنوان؟';

  @override
  String get homeCatalogue => 'علاجاتنا';

  @override
  String get homeCatalogueSubtitle => 'تعرف على العلاجات المتوفرة في المنزل';

  @override
  String get catalogueSearchHint => 'ابحث عن علاج';

  @override
  String get catalogueEmpty => 'لا يوجد أي علاج متوفر حاليا.';

  @override
  String catalogueNoResult(String query) {
    return 'لا يوجد علاج يطابق «$query».';
  }

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count علاجا',
      few: '$count علاجات',
      two: 'علاجان',
      one: 'علاج واحد',
    );
    return '$_temp0';
  }

  @override
  String serviceDuration(int minutes) {
    return '$minutes د';
  }

  @override
  String priceDirhams(String amount) {
    return '$amount درهم';
  }

  @override
  String get serviceDurationLabel => 'المدة';

  @override
  String get servicePriceLabel => 'السعر التقريبي';

  @override
  String get servicePriceNote =>
      'قد يرتفع السعر ليلا وفي أيام العطل وحسب المسافة.';

  @override
  String get servicePrescriptionRequired => 'الوصفة الطبية إجبارية';

  @override
  String get servicePrescriptionHelp =>
      'لحجز هذا العلاج، يجب إرسال صورة للوصفة الطبية.';

  @override
  String get serviceSeries => 'يمكن برمجة هذا العلاج على عدة أيام.';

  @override
  String serviceProvidedBy(String profession) {
    return 'يقوم به: $profession';
  }

  @override
  String get bookingSoon => 'الحجز سيتوفر قريبا في التطبيق.';

  @override
  String get bookService => 'حجز هذا العلاج';

  @override
  String get homeBookings => 'حجوزاتي';

  @override
  String get homeBookingsSubtitle => 'متابعة طلب أو إلغاؤه';

  @override
  String get bookingStepPatientTitle => 'لمن هذا العلاج؟';

  @override
  String get bookingStepAddressTitle => 'إلى أين يأتي المعالج؟';

  @override
  String get bookingStepSlotTitle => 'متى؟';

  @override
  String get bookingStepSummaryTitle => 'راجع طلبك';

  @override
  String get bookingNoProfile => 'أضف أولا الشخص الذي يحتاج إلى العلاج.';

  @override
  String get bookingNoAddress => 'أضف أولا عنوان المريض.';

  @override
  String get bookingChoosePatient => 'اختر مريضا.';

  @override
  String get bookingChooseAddress => 'اختر عنوانا.';

  @override
  String get bookingAddressNotCovered =>
      'هذا العنوان خارج المنطقة المغطاة حاليا.';

  @override
  String get slotAsap => 'في أقرب وقت';

  @override
  String get slotChooseDay => 'اختيار يوم';

  @override
  String get slotNadorTime => 'الأوقات بتوقيت الناظور.';

  @override
  String get slotNone => 'لا يوجد موعد في هذا اليوم. اختر يوما آخر.';

  @override
  String get slotChoose => 'اختر موعدا.';

  @override
  String get summaryService => 'العلاج';

  @override
  String get summaryPatient => 'المريض';

  @override
  String get summaryAddress => 'العنوان';

  @override
  String get summarySlot => 'الموعد';

  @override
  String get summaryPayment => 'الأداء';

  @override
  String get summaryBasePrice => 'السعر';

  @override
  String get summaryTotal => 'المجموع';

  @override
  String get paymentCash => 'نقدا، يؤدى للمعالج';

  @override
  String get noteLabel => 'ملاحظة للمعالج (اختياري)';

  @override
  String get noteHint => 'مثال: اضغط على الجرس مرتين';

  @override
  String get prescriptionCamera => 'تصوير الوصفة الطبية';

  @override
  String get prescriptionGallery => 'اختيار صورة للوصفة الطبية';

  @override
  String get prescriptionAdded => 'تمت إضافة الوصفة الطبية';

  @override
  String get prescriptionMissing => 'أضف الوصفة الطبية لإرسال الطلب.';

  @override
  String get bookingConfirm => 'إرسال طلبي';

  @override
  String get bookingSentTitle => 'تم إرسال الطلب';

  @override
  String bookingSentBody(String reference) {
    return 'سيقوم فريق التنسيق بتأكيد طلبك $reference. احتفظ بهذا الرقم.';
  }

  @override
  String get bookingSeeMine => 'عرض حجوزاتي';

  @override
  String get bookingsEmpty => 'ليس لديك أي حجز جار.';

  @override
  String get bookingsPastEmpty => 'لا يوجد أي حجز سابق.';

  @override
  String get bookingsUpcoming => 'الجارية والقادمة';

  @override
  String get bookingsPast => 'السابقة';

  @override
  String get statusPending => 'في انتظار التأكيد';

  @override
  String get statusConfirmed => 'مؤكد، جار البحث عن معالج';

  @override
  String get statusAssigned => 'تم تعيين معالج';

  @override
  String get statusEnRoute => 'المعالج في الطريق';

  @override
  String get statusInProgress => 'العلاج جار';

  @override
  String get statusCompleted => 'انتهى';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get statusDisputed => 'قيد الدراسة';

  @override
  String bookingReference(String reference) {
    return 'الطلب $reference';
  }

  @override
  String dateAtTime(String date, String time) {
    return '$date على الساعة $time';
  }

  @override
  String get bookingCancel => 'إلغاء الحجز';

  @override
  String get bookingCancelTitle => 'إلغاء هذا الحجز؟';

  @override
  String get bookingCancelFree => 'الإلغاء مجاني.';

  @override
  String bookingCancelFee(String amount) {
    return 'تطبق رسوم إلغاء قدرها $amount درهم.';
  }

  @override
  String get bookingCancelConfirm => 'نعم، إلغاء';

  @override
  String get bookingKeep => 'الاحتفاظ بالحجز';

  @override
  String bookingFeeCharged(String amount) {
    return 'رسوم الإلغاء: $amount درهم';
  }

  @override
  String get back => 'رجوع';

  @override
  String get refresh => 'تحديث';

  @override
  String get proCreateFileTitle => 'أنشئ ملفك المهني';

  @override
  String get proCreateFileIntro =>
      'لاستقبال المهام، يجب أن يتحقق Nador Care من ملفك.';

  @override
  String get proStart => 'ابدأ';

  @override
  String get professionLabel => 'مهنتك';

  @override
  String get professionRequired => 'اختر مهنتك.';

  @override
  String get licenseNumberLabel => 'رقم رخصة المزاولة';

  @override
  String get orderNumberLabel => 'رقم التسجيل في الهيئة';

  @override
  String get proFileTitle => 'ملفي';

  @override
  String get proDocumentsTitle => 'الوثائق';

  @override
  String get docIdentity => 'وثيقة الهوية';

  @override
  String get docDiploma => 'الدبلوم';

  @override
  String get docPracticeAuthorization => 'رخصة المزاولة';

  @override
  String get docOrderRegistration => 'التسجيل في الهيئة';

  @override
  String get docRcInsurance => 'تأمين المسؤولية المدنية';

  @override
  String get docStatusMissing => 'يجب إيداعها';

  @override
  String get docStatusPending => 'تم الإيداع، في انتظار المراقبة';

  @override
  String get docStatusApproved => 'مقبولة';

  @override
  String docStatusRejected(String reason) {
    return 'مرفوضة: $reason';
  }

  @override
  String get docStatusExpired => 'منتهية الصلاحية، يجب تجديدها';

  @override
  String get docTakePhoto => 'التقاط صورة';

  @override
  String get docChoosePhoto => 'اختيار صورة';

  @override
  String get docExpiryChoose => 'تاريخ انتهاء صلاحية التأمين';

  @override
  String get docExpiryRequired => 'أدخل أولا تاريخ انتهاء صلاحية التأمين.';

  @override
  String docValidUntil(String date) {
    return 'صالحة إلى غاية $date';
  }

  @override
  String get proSubmit => 'إرسال ملفي';

  @override
  String get proSubmitIncomplete => 'أودع جميع الوثائق لإرسال ملفك.';

  @override
  String get proChangeProfession => 'تغيير مهنتي';

  @override
  String get proStatusSubmittedTitle => 'الملف قيد التحقق';

  @override
  String get proStatusSubmittedBody =>
      'نقوم بمراقبة وثائقك. يمكنك استقبال المهام فور قبول ملفك.';

  @override
  String get proStatusRejectedTitle => 'ملفك يحتاج إلى تصحيح';

  @override
  String get proStatusSuspendedTitle => 'الحساب موقوف';

  @override
  String get proStatusSuspendedBody => 'لن تستقبل أي مهمة. اتصل بفريق التنسيق.';

  @override
  String proReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get proOnline => 'متصل';

  @override
  String get proOffline => 'غير متصل';

  @override
  String get proOnlineHelp =>
      'عندما تكون متصلا، يمكنك استقبال اقتراحات المهام.';

  @override
  String get proZones => 'مناطقي';

  @override
  String get proZonesTitle => 'المناطق التي تشتغل فيها';

  @override
  String get proZonesEmpty => 'لا توجد أي منطقة مفتوحة بعد.';

  @override
  String proZonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منطقة',
      few: '$count مناطق',
      two: 'منطقتان',
      one: 'منطقة واحدة',
      zero: 'لم تختر أي منطقة',
    );
    return '$_temp0';
  }

  @override
  String get proSchedule => 'جدولي';

  @override
  String get proScheduleTitle => 'أيام وساعات العمل';

  @override
  String get proScheduleHelp => 'الأوقات بتوقيت الناظور.';

  @override
  String proScheduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوما في الأسبوع',
      few: '$count أيام في الأسبوع',
      two: 'يومان في الأسبوع',
      one: 'يوم واحد في الأسبوع',
      zero: 'لا يوجد يوم عمل',
    );
    return '$_temp0';
  }

  @override
  String scheduleRange(String start, String end) {
    return 'من $start إلى $end';
  }

  @override
  String get scheduleStart => 'البداية';

  @override
  String get scheduleEnd => 'النهاية';

  @override
  String get scheduleInvalid => 'يجب أن تكون ساعة النهاية بعد ساعة البداية.';

  @override
  String get proOffersTitle => 'اقتراحات المهام';

  @override
  String get proOffersEmpty => 'لا يوجد أي اقتراح حاليا.';

  @override
  String offerAnswerBefore(String time) {
    return 'الرد قبل $time';
  }

  @override
  String offerDistance(String distance) {
    return 'على بعد $distance';
  }

  @override
  String get offerAccept => 'قبول';

  @override
  String get offerDecline => 'رفض';

  @override
  String get proMissionsTitle => 'مهامي';

  @override
  String get proMissionsEmpty => 'لا توجد أي مهمة.';

  @override
  String get missionStatusAssigned => 'قادمة';

  @override
  String get missionStatusEnRoute => 'في الطريق';

  @override
  String get missionStatusInProgress => 'جارية';

  @override
  String get missionAccessNotes => 'علامات الوصول';

  @override
  String get missionCareNotes => 'معلومات مفيدة للعلاج';

  @override
  String get missionPatientNote => 'ملاحظة المريض';

  @override
  String get missionAmount => 'المبلغ الواجب تحصيله نقدا';

  @override
  String get missionPrescription => 'وصفة طبية مرفقة بالطلب.';

  @override
  String get missionWithdraw => 'الانسحاب';

  @override
  String get missionWithdrawTitle => 'الانسحاب من هذه المهمة؟';

  @override
  String get missionWithdrawBody => 'سيبحث فريق التنسيق عن معالج آخر.';

  @override
  String get missionWithdrawReason => 'السبب';

  @override
  String get add => 'إضافة';

  @override
  String get missionDepart => 'أنا في الطريق';

  @override
  String get missionArrive => 'لقد وصلت';

  @override
  String get missionOpenReport => 'تحرير التقرير';

  @override
  String get journeySharing => 'يُشارَك موقعك مع المريض إلى حين وصولك.';

  @override
  String get journeyLocationOff =>
      'الموقع غير متاح. فعّل تحديد الموقع ليتمكن المريض من متابعة وصولك.';

  @override
  String journeyEta(int minutes) {
    return 'الوصول المتوقع خلال $minutes د';
  }

  @override
  String get reportTitle => 'تقرير التدخل';

  @override
  String get reportVitalsTitle => 'العلامات الحيوية';

  @override
  String get vitalSystolic => 'الضغط الانقباضي (mmHg)';

  @override
  String get vitalDiastolic => 'الضغط الانبساطي (mmHg)';

  @override
  String get vitalPulse => 'النبض (نبضة/د)';

  @override
  String get vitalTemperature => 'الحرارة (°C)';

  @override
  String get vitalGlucose => 'السكر في الدم (g/L)';

  @override
  String get vitalSpo2 => 'تشبع الأكسجين (%)';

  @override
  String vitalOutOfRange(String min, String max) {
    return 'القيمة المتوقعة بين $min و$max.';
  }

  @override
  String get reportObservations => 'الملاحظات';

  @override
  String get reportObservationsRequired => 'صِف العلاج المنجز.';

  @override
  String get reportActsTitle => 'الأعمال المنجزة';

  @override
  String get reportActAdd => 'إضافة عمل';

  @override
  String get reportConsumablesTitle => 'المستلزمات المستعملة';

  @override
  String get reportConsumableAdd => 'إضافة مستلزم';

  @override
  String get reportLineLabel => 'التسمية';

  @override
  String get reportLineQuantity => 'الكمية';

  @override
  String reportLineWithQuantity(String label, String quantity) {
    return '$label × $quantity';
  }

  @override
  String get reportPhotosTitle => 'الصور';

  @override
  String reportPhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صورة',
      many: '$count صورة',
      few: '$count صور',
      two: 'صورتان',
      one: 'صورة واحدة',
      zero: 'لا توجد صور',
    );
    return '$_temp0';
  }

  @override
  String get reportPhotoAdd => 'إضافة صورة';

  @override
  String get reportSignatureTitle => 'توقيع المريض';

  @override
  String get reportSign => 'طلب التوقيع';

  @override
  String get reportSignAgain => 'إعادة التوقيع';

  @override
  String reportSignedBy(String name) {
    return 'وقّعه $name';
  }

  @override
  String get reportNotSigned => 'لم يُوقَّع بعد';

  @override
  String get signatureName => 'اسم الشخص الموقِّع';

  @override
  String get signatureHelp =>
      'يوقّع المريض، أو أحد أقاربه الحاضرين، بإصبعه داخل الإطار.';

  @override
  String get signatureClear => 'مسح';

  @override
  String get signatureConfirm => 'تأكيد التوقيع';

  @override
  String get signatureEmpty => 'التوقيع فارغ.';

  @override
  String reportCashCollected(String amount) {
    return 'استلمتُ $amount نقدًا';
  }

  @override
  String get reportSaveDraft => 'حفظ المسودة';

  @override
  String get reportSaved => 'تم حفظ المسودة.';

  @override
  String get reportComplete => 'إنهاء التدخل';

  @override
  String get reportCompleteTitle => 'إنهاء التدخل؟';

  @override
  String get reportCompleteBody => 'سيُعتمد التقرير ولن يمكن تعديله بعد ذلك.';

  @override
  String get reportSignatureRequired => 'اطلب توقيع المريض قبل الإنهاء.';

  @override
  String get reportCompleted => 'انتهى التدخل. تم اعتماد التقرير.';

  @override
  String get bookingProfessional => 'مقدّم الرعاية';

  @override
  String get trackingOnTheWay => 'مقدّم الرعاية في الطريق إليك.';

  @override
  String trackingEta(int minutes) {
    return 'يصل مقدّم الرعاية خلال $minutes د تقريبًا.';
  }

  @override
  String get bookingReportOpen => 'عرض التقرير';

  @override
  String reportAmended(String reason) {
    return 'تم تصحيح هذا التقرير. السبب: $reason';
  }

  @override
  String get proScheduleMissing =>
      'لم تحدّد أي يوم عمل. املأ جدولك لتصلك العروض التي تناسبك.';

  @override
  String get proScheduleSetUp => 'تحديد جدولي';

  @override
  String get proZonesMissing =>
      'لم تختر أي منطقة. حدّد الأماكن التي تقبل العمل فيها.';

  @override
  String get proZonesSetUp => 'اختيار مناطقي';

  @override
  String get proAccountSection => 'نشاطي';

  @override
  String get docRenewInsurance => 'تجديد التأمين';

  @override
  String stepProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get teleconsultationLabel => 'استشارة عن بعد';

  @override
  String get teleconsultationServiceNote =>
      'يتم هذا العلاج عبر مكالمة فيديو داخل التطبيق، دون تنقل.';

  @override
  String get teleconsultationJoin => 'الانضمام إلى الاستشارة عن بعد';

  @override
  String get teleconsultationStart => 'بدء الاستشارة عن بعد';

  @override
  String get teleconsultationRoomHelp => 'تفتح القاعة قبل الموعد بدقائق.';

  @override
  String get teleconsultationNoJourney => 'استشارة عن بعد: لا يوجد تنقل.';

  @override
  String get callConnecting => 'جار الاتصال بالقاعة…';

  @override
  String get callInProgress => 'المكالمة جارية';

  @override
  String get callSimulated => 'مكالمة تجريبية: خدمة الفيديو غير مفعلة بعد.';

  @override
  String get callHangUp => 'إنهاء المكالمة';

  @override
  String get callMute => 'كتم الميكروفون';

  @override
  String get callUnmute => 'تشغيل الميكروفون';

  @override
  String get callCameraOff => 'إيقاف الكاميرا';

  @override
  String get callCameraOn => 'تشغيل الكاميرا';

  @override
  String get paymentCard => 'بطاقة بنكية';

  @override
  String get unsavedTitle => 'المغادرة دون حفظ؟';

  @override
  String get unsavedBody => 'ستضيع تعديلاتك.';

  @override
  String get unsavedLeave => 'مغادرة';

  @override
  String get unsavedStay => 'البقاء';

  @override
  String get changesSaved => 'تم حفظ التعديلات.';

  @override
  String get proNoTeamTitle => 'الحساب غير مسجل ضمن الفريق';

  @override
  String get proNoTeamBody =>
      'هذا الحساب ليس ضمن فريق Nador Care. اتصل بالوكالة.';

  @override
  String get proPlanningTitle => 'جدولي';

  @override
  String get proPlanningHelp =>
      'جدولك تحدده الوكالة. لتغييره، أرسل طلبا: يتغير عندما يقبله التنسيق.';

  @override
  String get planningZones => 'مناطق التدخل';

  @override
  String get planningZone => 'المنطقة';

  @override
  String get planningWeek => 'الأسبوع النموذجي';

  @override
  String get planningNotSet => 'لم تحدده الوكالة بعد.';

  @override
  String get planningMissing =>
      'جدولك غير مكتمل بعد. الوكالة هي التي تحدده، ويمكنك اقتراح أوقات توفرك.';

  @override
  String get planningProposeWeek => 'اقتراح أسبوع آخر';

  @override
  String get planningProposeTitle => 'اقتراح أسبوع نموذجي';

  @override
  String get planningProposeHelp =>
      'حدد الأيام والساعات التي تناسبك. الأوقات بتوقيت الناظور.';

  @override
  String get planningReportUnavailability => 'الإبلاغ عن عدم التوفر';

  @override
  String get planningUnavailabilityTitle => 'الإبلاغ عن عدم التوفر';

  @override
  String get planningUnavailabilityHelp => 'عطلة أو مانع: حدد الأيام المعنية.';

  @override
  String get planningFirstDay => 'اليوم الأول';

  @override
  String get planningLastDay => 'اليوم الأخير';

  @override
  String get planningChooseDate => 'اختر تاريخا';

  @override
  String get planningNoteLabel => 'توضيح (اختياري)';

  @override
  String get planningNoteHint => 'مثلا: عطلة، موعد';

  @override
  String get planningSend => 'إرسال الطلب';

  @override
  String get planningSent => 'تم إرسال الطلب إلى التنسيق.';

  @override
  String get planningRequests => 'طلباتي';

  @override
  String get planningRequestsEmpty => 'لا يوجد أي طلب حاليا.';

  @override
  String get planningKindWeekly => 'أسبوع نموذجي جديد';

  @override
  String get planningKindUnavailability => 'عدم التوفر';

  @override
  String planningFromTo(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String get planningStatusPending => 'قيد الانتظار';

  @override
  String get planningStatusAccepted => 'مقبول';

  @override
  String get planningStatusRefused => 'مرفوض';

  @override
  String get planningStatusCancelled => 'مسحوب';

  @override
  String get planningWithdraw => 'سحب الطلب';

  @override
  String planningDecisionNote(String note) {
    return 'رد التنسيق: $note';
  }

  @override
  String get proToConfirmTitle => 'للتأكيد';

  @override
  String get missionToConfirm => 'للتأكيد';

  @override
  String missionConfirmBefore(String time) {
    return 'أكد قبل $time';
  }

  @override
  String get missionConfirmHelp =>
      'أسند إليك التنسيق هذه المهمة. أكد أنك ستتكفل بها، أو أبلغ عن عدم توفرك.';

  @override
  String get missionConfirm => 'تأكيد التكفل';

  @override
  String get missionConfirmed => 'تم تأكيد التكفل.';

  @override
  String get missionDecline => 'لست متوفرا';

  @override
  String get missionDeclineTitle => 'الإبلاغ عن عدم توفرك؟';

  @override
  String get missionDeclineBody => 'سيسند التنسيق هذه المهمة إلى معالج آخر.';

  @override
  String get missionDeclineSend => 'إرسال';

  @override
  String get declineReasonBusy => 'في تدخل آخر';

  @override
  String get declineReasonSick => 'مرض';

  @override
  String get declineReasonPersonal => 'مانع شخصي';

  @override
  String get declineReasonOther => 'سبب آخر';

  @override
  String get declineReasonRequired => 'اختر سببا.';

  @override
  String get declineNoteLabel => 'توضيح';

  @override
  String get declineNoteRequired => 'يرجى توضيح السبب.';

  @override
  String get docOptional => 'اختياري';

  @override
  String get homeHeroEyebrow => 'العلاج في المنزل · الناظور ونواحيها';

  @override
  String get homeHeroTitle => 'علاج في منزلكم، على يد فريقنا الخاص';

  @override
  String get homeHeroBody =>
      'اختاروا العلاج والعنوان والموعد: يظهر السعر قبل الإرسال.';

  @override
  String get homeHeroAction => 'حجز علاج';

  @override
  String get homeProofTeam => 'فريقنا الخاص';

  @override
  String get homeProofPrice => 'سعر معروف مسبقا';

  @override
  String get homeProofCash => 'الأداء للمعالج';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCare => 'العلاجات';

  @override
  String get navBookings => 'المواعيد';

  @override
  String get navAccount => 'الحساب';

  @override
  String get navMissions => 'المهام';

  @override
  String get navPlanning => 'الجدول';

  @override
  String get navFile => 'الملف';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get homeQuickActions => 'وصول سريع';

  @override
  String get homeUpcomingTitle => 'علاجاتكم القادمة';

  @override
  String get homeUpcomingEmpty => 'لا يوجد علاج مبرمج حاليا.';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get proStatToday => 'اليوم';

  @override
  String get proStatToConfirm => 'بانتظار ردكم';

  @override
  String get proStatUpcoming => 'القادمة';

  @override
  String get slotMorning => 'الصباح';

  @override
  String get slotAfternoon => 'بعد الظهر';

  @override
  String get slotEvening => 'المساء';

  @override
  String get slotOtherDay => 'يوم آخر';

  @override
  String get bookingProgressTitle => 'تتبع الطلب';

  @override
  String get timelineSent => 'تم إرسال الطلب';

  @override
  String get timelineConfirmed => 'تمت المصادقة من الوكالة';

  @override
  String get timelineAssigned => 'تم تعيين المعالج';

  @override
  String get timelineOnTheWay => 'في الطريق إليكم';

  @override
  String get timelineCare => 'التدخل جارٍ';

  @override
  String get timelineDone => 'انتهى العلاج';

  @override
  String get serviceAboutTitle => 'حول هذا العلاج';

  @override
  String get missionWhereTitle => 'مكان العلاج';

  @override
  String get missionNotesTitle => 'معلومات مهمة';

  @override
  String get bookingDetailsTitle => 'التفاصيل';

  @override
  String get planningDayOff => 'راحة';

  @override
  String docProgress(int done, int total) {
    return '$done من $total مقبولة';
  }
}
