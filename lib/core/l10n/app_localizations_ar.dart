// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دفتري';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonArchive => 'أرشفة';

  @override
  String get commonRestore => 'استعادة';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonSearch => 'بحث';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get commonError => 'حدث خطأ ما';

  @override
  String get errorCache => 'حدث خطأ في التخزين المحلي. من فضلك حاول مرة أخرى.';

  @override
  String get errorNotFound => 'تعذر العثور على هذا العنصر.';

  @override
  String get errorValidation => 'من فضلك راجع البيانات المدخلة وحاول مرة أخرى.';

  @override
  String get errorUnknown => 'حدث خطأ غير متوقع. من فضلك حاول مرة أخرى.';

  @override
  String get peopleListTitle => 'الأشخاص';

  @override
  String get searchPeopleHint => 'ابحث عن شخص';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterTheyOweYou => 'لهم عندك';

  @override
  String get filterYouOweThem => 'عليك لهم';

  @override
  String get filterSettled => 'تمت التسوية';

  @override
  String get emptyPeopleTitle => 'لا يوجد أشخاص بعد';

  @override
  String get emptyPeopleMessage =>
      'أضف شخصًا لتبدأ في تتبع الأموال التي تعطيها أو تستلمها معه.';

  @override
  String get archivedPeopleAction => 'الأشخاص المؤرشفون';

  @override
  String get addPersonAction => 'إضافة شخص';

  @override
  String get personFormCreateTitle => 'شخص جديد';

  @override
  String get personFormEditTitle => 'تعديل الشخص';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get nameRequiredError => 'الاسم مطلوب';

  @override
  String get phoneLabel => 'رقم الهاتف (اختياري)';

  @override
  String get relationshipTagLabel => 'العلاقة (اختياري)';

  @override
  String get notesLabel => 'ملاحظات (اختياري)';

  @override
  String get deletePersonAction => 'حذف الشخص';

  @override
  String get deleteBlockedTitle => 'لا يمكن حذف هذا الشخص';

  @override
  String get deleteBlockedMessage =>
      'لهذا الشخص معاملات مسجلة. قم بأرشفته بدلًا من ذلك للحفاظ على سجله.';

  @override
  String get archiveInsteadAction => 'أرشفة بدلًا من الحذف';

  @override
  String get relationshipFamily => 'عائلة';

  @override
  String get relationshipFriend => 'صديق';

  @override
  String get relationshipColleague => 'زميل';

  @override
  String get relationshipCustomer => 'عميل';

  @override
  String get relationshipSupplier => 'مورّد';

  @override
  String get relationshipOther => 'أخرى';

  @override
  String get duplicateWarningTitle => 'تكرار محتمل';

  @override
  String get duplicateWarningMessage => 'هذا الاسم يشبه شخصًا تعرفه بالفعل.';

  @override
  String get duplicateUseExisting => 'استخدام الشخص الموجود';

  @override
  String get duplicateCreateNew => 'إنشاء شخص جديد على أي حال';

  @override
  String get transactionFormCreateTitle => 'تسجيل معاملة';

  @override
  String get transactionFormEditTitle => 'تعديل المعاملة';

  @override
  String get amountLabel => 'المبلغ (جنيه مصري)';

  @override
  String get amountInvalidError => 'أدخل مبلغًا صحيحًا أكبر من صفر';

  @override
  String get directionGiven => 'أعطيت';

  @override
  String get directionReceived => 'استلمت';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get noteLabel => 'ملاحظة (اختياري)';

  @override
  String get personLabel => 'الشخص';

  @override
  String get createPersonInlineAction => 'إنشاء شخص جديد';

  @override
  String get savedConfirmation => 'تم الحفظ';

  @override
  String get editedLabel => 'معدَّل';

  @override
  String get repaymentLabel => 'سداد';

  @override
  String get repaymentFormTitle => 'تسجيل سداد';

  @override
  String get recordRepaymentAction => 'تسجيل سداد';

  @override
  String personDetailTheyOweYou(String name, String amount) {
    return '$name مديون لك بمبلغ $amount';
  }

  @override
  String personDetailYouOweThem(String name, String amount) {
    return 'أنت مدين لـ $name بمبلغ $amount';
  }

  @override
  String get personDetailSettled => 'تمت التسوية';

  @override
  String get historyEmptyTitle => 'لا توجد معاملات بعد';

  @override
  String historyEmptyMessage(String name) {
    return 'سجّل معاملة مع $name لتبدأ في تتبع رصيدك.';
  }

  @override
  String get recordTransactionAction => 'تسجيل معاملة';

  @override
  String get deleteTransactionConfirmTitle => 'هل تريد حذف هذه المعاملة؟';

  @override
  String get deleteTransactionConfirmMessage =>
      'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get overviewTitle => 'نظرة عامة';

  @override
  String get overviewTotalOwedToYou => 'إجمالي المستحق لك';

  @override
  String get overviewTotalYouOwe => 'إجمالي المستحق عليك';

  @override
  String get overviewSectionTheyOweYou => 'لهم عندك';

  @override
  String get overviewSectionYouOweThem => 'عليك لهم';

  @override
  String get overviewAllSettledTitle => 'كل شيء تمت تسويته';

  @override
  String get overviewAllSettledMessage =>
      'ليس لديك أي أرصدة مستحقة مع أي شخص الآن.';

  @override
  String get archivedLabel => 'مؤرشف';

  @override
  String get archivedPeopleTitle => 'الأشخاص المؤرشفون';

  @override
  String get archivedEmptyTitle => 'لا يوجد أشخاص مؤرشفون';

  @override
  String get archivedEmptyMessage =>
      'الأشخاص الذين تقوم بأرشفتهم سيظهرون هنا، مع الاحتفاظ الكامل بسجلهم.';

  @override
  String get restoreAction => 'استعادة';
}
