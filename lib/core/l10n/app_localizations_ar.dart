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

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get languageSectionTitle => 'اللغة';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get settingsSaveFailed =>
      'تعذر حفظ اختيار اللغة. لا يزال ساريًا لهذه الجلسة — سنواصل المحاولة.';

  @override
  String get themeSectionTitle => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystemDefault => 'افتراضي النظام';

  @override
  String get themeSaveFailed =>
      'تعذر حفظ اختيار المظهر. لا يزال ساريًا لهذه الجلسة — سنواصل المحاولة.';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get onboardingUnderstandingMoneyTitle =>
      'افهم وضعك المالي بنظرة واحدة';

  @override
  String get onboardingUnderstandingMoneyDescription =>
      'شاهد من يدين لك، ومن تدين له، والوضع العام كله في مكان واحد.';

  @override
  String get onboardingMoneyBetweenPeopleTitle =>
      'تتبّع الأموال بينك وبين الأشخاص';

  @override
  String get onboardingMoneyBetweenPeopleDescription =>
      'أضف شخصًا، سجّل ما أعطيته أو استلمته، ويحتفظ دفتري بالمجموع الجاري نيابة عنك.';

  @override
  String get onboardingSocialOccasionsTitle =>
      'حافظ على وضوح التبادلات الاجتماعية';

  @override
  String get onboardingSocialOccasionsDescription =>
      'إقراض صديق نقودًا، أو تقاسم هدية، أو تغطية شخص في مناسبة — دوّنها حتى لا تُنسى.';

  @override
  String get onboardingScanningRecordsTitle => 'راجع سجلك وقتما احتجت';

  @override
  String get onboardingScanningRecordsDescription =>
      'يُحفظ كل إدخال بتاريخه، لذا يمكنك مراجعة سجلك الكامل مع أي شخص في أي وقت.';

  @override
  String get onboardingAiAssistantTitle => 'احصل على مساعدة لفهم كل شيء';

  @override
  String get onboardingAiAssistantDescription =>
      'يمكن لمساعد الذكاء الاصطناعي مساعدتك في مراجعة وتنظيم ما سجّلته — وهو لا يقدّم استشارات مالية ولا يضمن أي نتائج.';

  @override
  String get onboardingBackAction => 'رجوع';

  @override
  String get onboardingNextAction => 'التالي';

  @override
  String get onboardingGetStartedAction => 'ابدأ الآن';

  @override
  String get onboardingSkipAction => 'تخطي';

  @override
  String get financeTitle => 'الدخل والمصروفات';

  @override
  String get financeOverviewCardTitle => 'هذا الشهر';

  @override
  String get financeAddExpenseAction => 'إضافة مصروف';

  @override
  String get financeAddIncomeAction => 'إضافة دخل';

  @override
  String get financeAddFirstEntryAction => 'أضف أول سجل';

  @override
  String get financeViewAllAction => 'عرض الكل';

  @override
  String get financeEntryFormExpenseTitle => 'إضافة مصروف';

  @override
  String get financeEntryFormIncomeTitle => 'إضافة دخل';

  @override
  String get financeEntryFormEditTitle => 'تعديل السجل';

  @override
  String get financeTypeExpense => 'مصروف';

  @override
  String get financeTypeIncome => 'دخل';

  @override
  String get financeCategoryLabel => 'الفئة';

  @override
  String get financeCategoryRequiredError => 'اختر فئة';

  @override
  String get financeManageCategoriesAction => 'إدارة الفئات';

  @override
  String get financeNoCategoriesTitle => 'لا توجد فئات بعد';

  @override
  String get financeNoCategoriesMessage => 'أنشئ فئة لتبدأ تسجيل مدخلاتك.';

  @override
  String get financeCategoryManagementTitle => 'الفئات';

  @override
  String get financeCategoryFormCreateTitle => 'فئة جديدة';

  @override
  String get financeCategoryFormEditTitle => 'تعديل الفئة';

  @override
  String get financeCategoryNameLabel => 'اسم الفئة';

  @override
  String get financeCategoryNameRequiredError => 'اسم الفئة مطلوب';

  @override
  String get financeCategoryIconLabel => 'الأيقونة';

  @override
  String get financeCategoryIconRequiredError => 'اختر أيقونة';

  @override
  String get financeCategoryTypeLabel => 'النوع';

  @override
  String financeCategoryDuplicateError(String name) {
    return 'لديك بالفعل فئة باسم \"$name\".';
  }

  @override
  String get financeCategorySectionActive => 'نشطة';

  @override
  String get financeCategorySectionArchived => 'مؤرشفة';

  @override
  String get financeAddCategoryAction => 'إضافة فئة';

  @override
  String get financeRemoveCategoryAction => 'إزالة الفئة';

  @override
  String get financeRemoveCategoryConfirmTitle => 'إزالة هذه الفئة؟';

  @override
  String get financeRemoveCategoryConfirmMessage =>
      'إذا كانت هناك أي مدخلات تستخدم هذه الفئة، فسيتم أرشفتها للحفاظ على سجلّها. وإلا فسيتم حذفها.';

  @override
  String get financeCategoryArchivedNotice =>
      'مؤرشفة — مخفية عن المدخلات الجديدة، ومحفوظة للمدخلات الحالية.';

  @override
  String get financePeriodThisMonth => 'هذا الشهر';

  @override
  String get financePeriodLastMonth => 'الشهر الماضي';

  @override
  String get financePeriodCustom => 'نطاق مخصص';

  @override
  String get financePeriodStartLabel => 'من';

  @override
  String get financePeriodEndLabel => 'إلى';

  @override
  String get financeSummaryTotalIncome => 'إجمالي الدخل';

  @override
  String get financeSummaryTotalExpense => 'إجمالي المصروفات';

  @override
  String get financeSummaryNet => 'الصافي';

  @override
  String get financeBreakdownTitle => 'حسب الفئة';

  @override
  String financeBreakdownShare(String percent) {
    return '$percent٪ من الإجمالي';
  }

  @override
  String get financeHistoryTitle => 'السجل';

  @override
  String get financeFilterTypeLabel => 'النوع';

  @override
  String get financeFilterCategoryLabel => 'الفئة';

  @override
  String get financeClearFiltersAction => 'مسح عوامل التصفية';

  @override
  String get financeEmptyTitle => 'لا توجد مدخلات بعد';

  @override
  String get financeEmptyMessage => 'سجّل دخلك ومصروفاتك لترى أين تذهب أموالك.';

  @override
  String get financeNoMatchTitle => 'لا توجد مدخلات مطابقة';

  @override
  String get financeNoMatchMessage =>
      'لا توجد مدخلات تطابق عوامل التصفية التي اخترتها. جرّب فترة أو فئة مختلفة.';

  @override
  String get financeDeleteEntryConfirmTitle => 'حذف هذا السجل؟';

  @override
  String get financeDeleteEntryConfirmMessage =>
      'سيتم تحديث إجمالياتك فورًا. يمكنك التراجع خلال ثوانٍ قليلة.';

  @override
  String get financeEntryDeletedMessage => 'تم حذف السجل';

  @override
  String get financeUndoAction => 'تراجع';

  @override
  String get financeCategoryRent => 'الإيجار';

  @override
  String get financeCategoryElectricity => 'الكهرباء';

  @override
  String get financeCategoryWater => 'المياه';

  @override
  String get financeCategoryInternet => 'الإنترنت';

  @override
  String get financeCategoryPhone => 'الهاتف';

  @override
  String get financeCategoryGroceries => 'البقالة';

  @override
  String get financeCategoryTransportation => 'المواصلات';

  @override
  String get financeCategoryFuel => 'الوقود';

  @override
  String get financeCategoryMedical => 'الرعاية الصحية';

  @override
  String get financeCategoryEducation => 'التعليم';

  @override
  String get financeCategoryEntertainment => 'الترفيه';

  @override
  String get financeCategoryShopping => 'التسوق';

  @override
  String get financeCategoryRestaurants => 'المطاعم';

  @override
  String get financeCategorySubscriptions => 'الاشتراكات';

  @override
  String get financeCategoryFamily => 'الأسرة';

  @override
  String get financeCategoryOther => 'أخرى';

  @override
  String get financeCategorySalary => 'الراتب';

  @override
  String get financeCategoryFreelance => 'العمل الحر';

  @override
  String get financeCategoryBusiness => 'الأعمال';

  @override
  String get financeCategoryBonus => 'المكافأة';

  @override
  String get financeCategoryGift => 'هدية';

  @override
  String get financeCategoryOtherIncome => 'دخل آخر';
}
