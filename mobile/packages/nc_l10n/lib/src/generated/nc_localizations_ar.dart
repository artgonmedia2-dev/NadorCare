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
  String get homePatientSoon => 'حجز العلاجات سيتوفر قريبا في هذا التطبيق.';

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
}
