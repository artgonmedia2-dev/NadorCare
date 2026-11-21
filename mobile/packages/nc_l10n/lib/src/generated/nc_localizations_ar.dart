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
}
