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
}
