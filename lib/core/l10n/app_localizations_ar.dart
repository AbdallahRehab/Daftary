// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get budgetMonthNavPrevious => 'الشهر السابق';

  @override
  String get budgetMonthNavNext => 'الشهر التالي';

  @override
  String budgetMonthNavCurrentLabel(String month) {
    return 'شهر الميزانية: $month';
  }

  @override
  String budgetCopyFromMonthAction(String month) {
    return 'نسخ ميزانية $month';
  }

  @override
  String budgetCopyFromMonthMessage(String month) {
    return 'ابدأ من الخطة التي وضعتها لشهر $month. يمكنك تعديلها لاحقًا دون تغيير ميزانية $month.';
  }

  @override
  String get budgetCopyInProgress => 'جارٍ النسخ…';

  @override
  String budgetCopySuccess(String month) {
    return 'تم نسخ الميزانية من $month';
  }

  @override
  String get budgetCopyFailed => 'تعذّر نسخ الميزانية. يرجى المحاولة مرة أخرى.';

  @override
  String get budgetCopyAlreadyExists => 'يوجد بالفعل ميزانية لهذا الشهر.';

  @override
  String get budgetTrendTitle => 'اتجاهات الإنفاق';

  @override
  String get budgetTrendSubtitle => 'المخطط مقابل الفعلي، آخر 6 أشهر';

  @override
  String get budgetTrendOverall => 'الإجمالي';

  @override
  String get budgetTrendCategoryLabel => 'الفئة';

  @override
  String get budgetTrendPlanned => 'المخطط';

  @override
  String get budgetTrendActual => 'الفعلي';

  @override
  String get budgetTrendOverPlan => 'تجاوز المخطط';

  @override
  String get budgetTrendNoBudget => 'لا توجد ميزانية';

  @override
  String get budgetTrendInsufficientTitle => 'لا يوجد سجل كافٍ بعد';

  @override
  String get budgetTrendInsufficientMessage =>
      'تحتاج الاتجاهات إلى ميزانية لشهرين على الأقل. استمر في وضع ميزانيتك وعُد الشهر القادم.';

  @override
  String budgetTrendMonthSummary(String month, String planned, String actual) {
    return '$month: المخطط $planned، الفعلي $actual';
  }

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

  @override
  String get occasionsTitle => 'المناسبات';

  @override
  String get occasionsEmptyTitle => 'لا توجد مناسبات بعد';

  @override
  String get occasionsEmptyMessage =>
      'أفراح وخطوبة وأعياد ميلاد وسبوع وعزاء — أنشئ مناسبة لتسجّل النقوط اللي أخدتها أو دفعتها فيها.';

  @override
  String get occasionAddAction => 'مناسبة جديدة';

  @override
  String get occasionAddFirstAction => 'أنشئ أول مناسبة';

  @override
  String get occasionSearchHint => 'ابحث عن مناسبة';

  @override
  String get occasionFilterTypeLabel => 'النوع';

  @override
  String get occasionFilterAllTypes => 'كل الأنواع';

  @override
  String get occasionFilterDateRangeLabel => 'نطاق التاريخ';

  @override
  String get occasionFilterDateFromLabel => 'من';

  @override
  String get occasionFilterDateToLabel => 'إلى';

  @override
  String get occasionFilterAllDates => 'أي تاريخ';

  @override
  String get occasionClearFiltersAction => 'مسح عوامل التصفية';

  @override
  String get occasionNoMatchTitle => 'لا توجد مناسبات مطابقة';

  @override
  String get occasionNoMatchMessage =>
      'لا توجد مناسبات تطابق بحثك أو عوامل التصفية. جرّب اسمًا أو نوعًا أو نطاق تاريخ مختلفًا.';

  @override
  String get occasionArchivedAction => 'المناسبات المؤرشفة';

  @override
  String get occasionArchivedTitle => 'المناسبات المؤرشفة';

  @override
  String get occasionArchivedEmptyTitle => 'لا توجد مناسبات مؤرشفة';

  @override
  String get occasionArchivedEmptyMessage =>
      'المناسبات التي تقوم بأرشفتها ستظهر هنا، مع الاحتفاظ بمساهماتها وأرصدتها كاملة.';

  @override
  String get occasionArchivedLabel => 'مؤرشفة';

  @override
  String get occasionUpcomingLabel => 'قادمة';

  @override
  String get occasionTypeWedding => 'فرح';

  @override
  String get occasionTypeEngagement => 'خطوبة';

  @override
  String get occasionTypeBirthday => 'عيد ميلاد';

  @override
  String get occasionTypeNewbornSebou => 'سبوع';

  @override
  String get occasionTypeCondolence => 'عزاء';

  @override
  String get occasionTypeCelebration => 'احتفال';

  @override
  String get occasionTypeOther => 'أخرى';

  @override
  String get occasionTypeCustomLabel => 'نوع مخصص';

  @override
  String get occasionTypeCustomHint => 'اكتب نوعًا من عندك، مثل حفل تخرج';

  @override
  String get occasionFormCreateTitle => 'مناسبة جديدة';

  @override
  String get occasionFormEditTitle => 'تعديل المناسبة';

  @override
  String get occasionNameLabel => 'اسم المناسبة';

  @override
  String get occasionNameHint => 'مثال: فرح أحمد';

  @override
  String get occasionNameRequiredError => 'اسم المناسبة مطلوب';

  @override
  String get occasionDateLabel => 'التاريخ';

  @override
  String get occasionTypeLabel => 'النوع';

  @override
  String get occasionTypeRequiredError => 'اختر نوع المناسبة';

  @override
  String get occasionNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get occasionCreateAction => 'إنشاء المناسبة';

  @override
  String get occasionUpdateAction => 'حفظ التعديلات';

  @override
  String get occasionEditAction => 'تعديل المناسبة';

  @override
  String get occasionDeleteAction => 'حذف المناسبة';

  @override
  String get occasionArchiveAction => 'أرشفة المناسبة';

  @override
  String get occasionRestoreAction => 'استعادة المناسبة';

  @override
  String get occasionParticipantFormAddTitle => 'إضافة مشارك';

  @override
  String get occasionParticipantFormEditTitle => 'تعديل المساهمة';

  @override
  String get occasionParticipantPersonLabel => 'الشخص';

  @override
  String get occasionParticipantAmountLabel => 'المبلغ (جنيه مصري)';

  @override
  String get occasionParticipantAmountInvalidError =>
      'أدخل مبلغًا صحيحًا أكبر من صفر';

  @override
  String get occasionParticipantDirectionLabel => 'الاتجاه';

  @override
  String get occasionParticipantDirectionReceived => 'استلمت منه';

  @override
  String get occasionParticipantDirectionGiven => 'أعطيته';

  @override
  String get occasionParticipantNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get occasionParticipantCountsTowardBalanceLabel => 'تُحتسب ضمن رصيده';

  @override
  String get occasionParticipantCountsTowardBalanceHint =>
      'نقوط العزاء لا تُرد عادةً، لذا لا تُحتسب ضمن الرصيد افتراضيًا. فعّل هذا الخيار لاحتسابها مثل أي تبادل آخر.';

  @override
  String get occasionParticipantSaveAction => 'حفظ المشارك';

  @override
  String get occasionParticipantUpdateAction => 'حفظ التعديلات';

  @override
  String get occasionDetailTotalReceived => 'إجمالي المستلم';

  @override
  String get occasionDetailTotalGiven => 'إجمالي المدفوع';

  @override
  String get occasionDetailNet => 'الصافي';

  @override
  String get occasionSettlementSettled => 'تمت التسوية';

  @override
  String occasionSettlementMoreReceived(String amount) {
    return 'استلمت $amount أكثر مما دفعت';
  }

  @override
  String occasionSettlementMoreGiven(String amount) {
    return 'دفعت $amount أكثر مما استلمت';
  }

  @override
  String get occasionParticipantsHeader => 'المشاركون';

  @override
  String get occasionParticipantsEmptyTitle => 'لا يوجد مشاركون بعد';

  @override
  String get occasionParticipantsEmptyMessage =>
      'أضف أول شخص أعطى أو استلم نقوطًا في هذه المناسبة.';

  @override
  String get occasionAddParticipantAction => 'إضافة مشارك';

  @override
  String get occasionEditParticipantAction => 'تعديل المساهمة';

  @override
  String get occasionRemoveParticipantAction => 'إزالة المساهمة';

  @override
  String get occasionContributionBadge => 'مناسبة';

  @override
  String get occasionRemoveParticipantConfirmTitle => 'إزالة هذه المساهمة؟';

  @override
  String get occasionRemoveParticipantConfirmMessage =>
      'ستختفي أيضًا من سجل هذا الشخص ومن رصيده. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get occasionDeleteConfirmTitle => 'حذف هذه المناسبة؟';

  @override
  String occasionDeleteConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'سيتم أيضًا حذف $count مساهمة وتحديث أرصدة أصحابها. لا يمكن التراجع عن هذا الإجراء.',
      many:
          'سيتم أيضًا حذف $count مساهمة وتحديث أرصدة أصحابها. لا يمكن التراجع عن هذا الإجراء.',
      few:
          'سيتم أيضًا حذف $count مساهمات وتحديث أرصدة أصحابها. لا يمكن التراجع عن هذا الإجراء.',
      two:
          'سيتم أيضًا حذف مساهمتين وتحديث رصيد صاحبيهما. لا يمكن التراجع عن هذا الإجراء.',
      one:
          'سيتم أيضًا حذف مساهمة واحدة وتحديث رصيد صاحبها. لا يمكن التراجع عن هذا الإجراء.',
      zero:
          'لا توجد مساهمات مسجلة في هذه المناسبة. لا يمكن التراجع عن هذا الإجراء.',
    );
    return '$_temp0';
  }

  @override
  String get occasionArchiveConfirmTitle => 'أرشفة هذه المناسبة؟';

  @override
  String get occasionArchiveConfirmMessage =>
      'ستنتقل إلى المناسبات المؤرشفة. تبقى مساهماتها في سجل كل شخص وفي رصيده، ويمكنك استعادتها في أي وقت.';

  @override
  String get occasionRestoreConfirmTitle => 'استعادة هذه المناسبة؟';

  @override
  String get occasionRestoreConfirmMessage =>
      'ستظهر مرة أخرى في قائمة المناسبات.';

  @override
  String get occasionAttachmentsHeader => 'الصور';

  @override
  String get occasionAttachPhotoAction => 'إرفاق صورة';

  @override
  String get occasionAttachFromCameraAction => 'التقاط صورة';

  @override
  String get occasionAttachFromGalleryAction => 'الاختيار من المعرض';

  @override
  String get occasionAttachmentsEmptyTitle => 'لا توجد صور بعد';

  @override
  String get occasionAttachmentsEmptyMessage =>
      'أرفق صورة لكشف النقوط أو الدعوة أو المناسبة نفسها لتبقى محفوظة مع هذا السجل.';

  @override
  String get occasionRemoveAttachmentAction => 'إزالة الصورة';

  @override
  String get occasionRemoveAttachmentConfirmTitle => 'إزالة هذه الصورة؟';

  @override
  String get occasionRemoveAttachmentConfirmMessage =>
      'سيتم حذف الصورة من هذه المناسبة. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get occasionCameraPermissionDeniedTitle => 'الوصول إلى الكاميرا مغلق';

  @override
  String get occasionCameraPermissionDeniedMessage =>
      'يحتاج دفتري إلى الكاميرا لالتقاط صورة لهذه المناسبة. افتح إعدادات جهازك واسمح لدفتري باستخدام الكاميرا، أو اختر صورة من المعرض بدلًا من ذلك.';

  @override
  String get occasionPhotoLibraryPermissionDeniedTitle =>
      'الوصول إلى الصور مغلق';

  @override
  String get occasionPhotoLibraryPermissionDeniedMessage =>
      'يحتاج دفتري إلى الوصول لصورك ليتمكن من إرفاق صورة بهذه المناسبة. افتح إعدادات جهازك واسمح لدفتري بالوصول إلى الصور، أو التقط صورة جديدة بالكاميرا بدلًا من ذلك.';

  @override
  String get occasionOpenSettingsAction => 'فتح الإعدادات';

  @override
  String get ocrCaptureTitle => 'مسح ورقة';

  @override
  String get ocrCaptureHeadline => 'حوّل قائمة ورقية إلى معاملات';

  @override
  String get ocrCaptureMessage =>
      'صوّر قائمة بالأسماء والمبالغ. تتم القراءة بالكامل على هذا الجهاز، ولا يُحفظ أي شيء قبل مراجعتك له.';

  @override
  String get ocrCaptureTakePhoto => 'التقاط صورة';

  @override
  String get ocrCaptureChooseFromGallery => 'اختيار من المعرض';

  @override
  String get ocrCaptureUnsupportedTitle => 'المسح غير متاح على هذا الجهاز';

  @override
  String get ocrCaptureUnsupportedMessage =>
      'لا يستطيع هذا الجهاز تشغيل التعرّف على النصوص محليًا، لذا لن يعمل مسح الورق هنا. ما زال بإمكانك إضافة المعاملات يدويًا.';

  @override
  String get ocrCaptureEnterManually => 'إدخال يدوي';

  @override
  String get ocrPrepTitle => 'تجهيز الصورة';

  @override
  String get ocrPrepHint =>
      'اقتصّ الصورة على قائمة الأسماء والمبالغ فقط، ثم حسّن الإضاءة للحصول على أفضل قراءة.';

  @override
  String get ocrPrepCropRotate => 'اقتصاص وتدوير';

  @override
  String get ocrPrepRecrop => 'إعادة الاقتصاص';

  @override
  String get ocrPrepEnhance => 'تحسين الصورة';

  @override
  String get ocrPrepEnhanceAgain => 'تحسين مرة أخرى';

  @override
  String get ocrPrepProcess => 'اقرأ الورقة';

  @override
  String get ocrPrepProcessingTitle => 'جارٍ قراءة الورقة';

  @override
  String get ocrPrepProcessingMessage =>
      'يعمل التعرّف على النصوص على هذا الجهاز. لا يتم رفع أي شيء إلى أي مكان.';

  @override
  String get ocrPrepCancel => 'إلغاء';

  @override
  String get ocrPrepInterruptedTitle => 'لم تكتمل العملية';

  @override
  String get ocrPrepInterruptedMessage =>
      'توقفت القراءة قبل أن تنتهي، على الأرجح بسبب مقاطعة التطبيق. لم يُحفظ أي شيء، ويمكنك المحاولة من جديد.';

  @override
  String get ocrPrepRetry => 'إعادة المحاولة';

  @override
  String get ocrPrepDefaultDirectionLabel => 'الاتجاه الافتراضي لهذه القائمة';

  @override
  String get ocrPrepDefaultDirectionHint =>
      'يُطبَّق على كل معاملة لا يمكن معرفة اتجاهها من الورقة. يمكنك تعديل أي معاملة أثناء المراجعة.';

  @override
  String get ocrPrepDirectionReceived => 'مبلغ مستلم';

  @override
  String get ocrPrepDirectionGiven => 'مبلغ مدفوع';

  @override
  String get ocrFailureNoTextTitle => 'لم يُعثر على نص';

  @override
  String get ocrFailureNoTextMessage =>
      'لم يُعثر على نص مقروء في هذه الصورة. عادةً ما تحل المشكلة صورة أوضح وبإضاءة أفضل ومن زاوية مستقيمة.';

  @override
  String get ocrFailureNoCandidatesTitle => 'تعذّر استخراج أي معاملات';

  @override
  String get ocrFailureNoCandidatesMessage =>
      'تم العثور على نص، لكن لم يبدُ أي سطر كاسم ومبلغ. جرّب الاقتصاص على القائمة وحدها، أو أدخل المعاملات يدويًا.';

  @override
  String get ocrFailurePermissionTitle => 'مطلوب إذن';

  @override
  String get ocrFailurePermissionMessage =>
      'يحتاج المسح إلى إذن الوصول إلى الكاميرا أو الصور لقراءة الورقة. امنح الإذن من إعدادات التطبيق ثم أعد المحاولة.';

  @override
  String get ocrFailureUnsupportedTitle => 'المسح غير متاح على هذا الجهاز';

  @override
  String get ocrFailureUnsupportedMessage =>
      'لا يستطيع هذا الجهاز تشغيل التعرّف على النصوص محليًا. الإدخال اليدوي يعمل بالطريقة نفسها تمامًا.';

  @override
  String get ocrFailureGenericTitle => 'لم تنجح عملية المسح';

  @override
  String get ocrFailureGenericMessage =>
      'حدث خطأ أثناء قراءة الورقة. لم يُحفظ أي شيء، ويمكنك إعادة المحاولة أو إدخال المعاملات يدويًا.';

  @override
  String get ocrFailureRetakePhoto => 'التقاط صورة جديدة';

  @override
  String get ocrFailureRecrop => 'تعديل الاقتصاص وإعادة المحاولة';

  @override
  String get ocrFailureManualEntry => 'إدخال يدوي';

  @override
  String get ocrFailureOpenSettings => 'فتح الإعدادات';

  @override
  String get ocrConfidenceLow => 'ثقة منخفضة';

  @override
  String get ocrConfidenceMedium => 'ثقة متوسطة';

  @override
  String get ocrConfidenceHigh => 'ثقة عالية';

  @override
  String get ocrConfidenceInferred => 'مُستنتَج وليس مقروءًا';

  @override
  String get ocrReviewTitle => 'مراجعة القيود';

  @override
  String get ocrReviewBatchSectionTitle => 'تنطبق على الدفعة كلها';

  @override
  String get ocrReviewBatchSectionMessage =>
      'تنطبق هذه الاختيارات على كل قيد ليس له اختيار خاص به. لا يُحفَظ أي شيء قبل التأكيد.';

  @override
  String get ocrReviewBatchDirectionLabel => 'الاتجاه الافتراضي';

  @override
  String get ocrReviewDirectionLabel => 'الاتجاه';

  @override
  String get ocrReviewDirectionReceived => 'مستلَم';

  @override
  String get ocrReviewDirectionGiven => 'مدفوع';

  @override
  String get ocrReviewDirectionRequired =>
      'اختر اتجاهًا لهذا القيد، أو عيّن اتجاهًا افتراضيًا للدفعة.';

  @override
  String get ocrReviewPersonLabel => 'الشخص';

  @override
  String get ocrReviewPersonRequired => 'أدخل اسم الشخص.';

  @override
  String get ocrReviewDuplicateWarningAction => 'أسماء مشابهة محفوظة بالفعل';

  @override
  String get ocrReviewAmountLabel => 'المبلغ';

  @override
  String get ocrReviewAmountRequired => 'أدخل مبلغًا أكبر من صفر.';

  @override
  String get ocrReviewAmountInvalid => 'أدخل مبلغًا صحيحًا، مثل 150.50';

  @override
  String get ocrReviewDateLabel => 'التاريخ';

  @override
  String get ocrReviewNotesLabel => 'ملاحظات';

  @override
  String get ocrReviewRawTextAction => 'النص الأصلي';

  @override
  String get ocrReviewRawTextLabel => 'المقروء من الورقة';

  @override
  String get ocrReviewEditedBadge => 'مُعدَّل';

  @override
  String get ocrReviewDiscardAction => 'استبعاد هذا القيد';

  @override
  String get ocrReviewIncompleteTitle => 'غير جاهز للحفظ';

  @override
  String get ocrReviewIncompleteBatchMessage =>
      'ما زالت بعض القيود تنقصها بيانات مطلوبة. لم يُحفَظ أي شيء.';

  @override
  String get ocrReviewConfirmAction => 'تأكيد وحفظ';

  @override
  String get ocrReviewConfirmBlockedHint =>
      'أكمل القيود المميّزة أو استبعدها قبل الحفظ.';

  @override
  String get ocrReviewNothingToConfirm => 'لم يعد هناك ما يُحفَظ في هذا المسح.';

  @override
  String get ocrReviewCancelAction => 'إلغاء المسح';

  @override
  String get ocrReviewCancelPromptTitle => 'هل تريد التخلي عن تصحيحاتك؟';

  @override
  String get ocrReviewCancelPromptMessage =>
      'لقد صحّحت بعض القيود. إلغاء هذا المسح يتخلى عن هذا العمل ولا يحفظ شيئًا.';

  @override
  String get ocrReviewCancelPromptConfirm => 'تخلَّ وألغِ';

  @override
  String get ocrReviewCancelPromptKeep => 'متابعة المراجعة';

  @override
  String get ocrReviewEmptyTitle => 'لم تتبقَّ أي قيود';

  @override
  String get ocrReviewEmptyMessage =>
      'لقد استبعدت كل قيود هذا المسح. ألغِ المسح، أو ارجع والتقط صورة الورقة من جديد.';

  @override
  String get ocrReviewLoadErrorTitle => 'تعذّر فتح هذا المسح';

  @override
  String get ocrReviewLoadErrorMessage =>
      'تعذّر تحميل المسح وقيوده. لم يُحفَظ أي شيء.';

  @override
  String get ocrReviewRetryAction => 'أعد المحاولة';

  @override
  String get ocrReviewSaveErrorMessage =>
      'تعذّر حفظ القيود. لم يُسجَّل أي شيء، لذا يمكنك إعادة المحاولة بأمان.';

  @override
  String get ocrReviewOccasionLabel => 'المناسبة';

  @override
  String get ocrReviewOccasionNone => 'بدون مناسبة';

  @override
  String get ocrReviewOccasionClear => 'إزالة ربط المناسبة';

  @override
  String get ocrReviewOccasionPickerTitle => 'اربط هذه الدفعة بمناسبة';

  @override
  String get ocrReviewOccasionEmpty =>
      'ليس لديك مناسبات بعد. أنشئ مناسبة من شاشة المناسبات أولًا.';

  @override
  String get ocrHistoryTitle => 'سجل عمليات المسح';

  @override
  String get ocrHistoryEmptyTitle => 'لا توجد عمليات مسح بعد';

  @override
  String get ocrHistoryEmptyMessage =>
      'بعد أن تمسح ورقة بها قائمة، ستظهر هنا كل عملية مسح تحتفظ بها مع صورتها ونتيجتها.';

  @override
  String get ocrHistoryErrorTitle => 'تعذّر تحميل عمليات المسح';

  @override
  String get ocrHistoryErrorMessage =>
      'حدث خطأ أثناء قراءة سجل عمليات المسح. حاول مرة أخرى.';

  @override
  String get ocrHistoryStatusProcessing => 'قيد المعالجة';

  @override
  String get ocrHistoryStatusNeedsReview => 'في انتظار المراجعة';

  @override
  String get ocrHistoryStatusConfirmed => 'مؤكَّدة';

  @override
  String get ocrHistoryStatusDiscarded => 'لم تنتج شيئًا';

  @override
  String get ocrHistoryStatusFailed => 'تعذّرت قراءة أي نص';

  @override
  String ocrHistoryConfirmedEntries(Object count) {
    return 'تم تأكيد $count من الإدخالات';
  }

  @override
  String get ocrHistoryDeleteAction => 'حذف عملية المسح';

  @override
  String get ocrHistoryDeleteTitle => 'حذف عملية المسح هذه؟';

  @override
  String get ocrHistoryDeleteMessage =>
      'سيؤدي هذا إلى حذف عملية المسح وصورتها من جهازك. أما المعاملات التي أنشأتها فلن تُحذف وستبقى في سجلاتك.';

  @override
  String get ocrHistoryDeleteConfirm => 'حذف عملية المسح';

  @override
  String get ocrScanDetailTitle => 'تفاصيل عملية المسح';

  @override
  String get ocrScanDetailImageMissing =>
      'لم تعد صورة عملية المسح هذه موجودة على جهازك.';

  @override
  String get ocrScanDetailEntriesTitle => 'الإدخالات المقروءة من الورقة';

  @override
  String get ocrScanDetailNoEntries =>
      'لم تُقرأ أي إدخالات من عملية المسح هذه.';

  @override
  String get ocrScanDetailUnknownPerson => 'لم يُقرأ أي اسم';

  @override
  String get ocrScanDetailNoAmount => 'لم يُقرأ أي مبلغ';

  @override
  String get ocrScanDetailEntryStatusPending => 'لم تُراجع';

  @override
  String get ocrScanDetailEntryStatusConfirmed => 'مؤكَّد';

  @override
  String get ocrScanDetailEntryStatusDiscarded => 'مستبعَد';

  @override
  String get ocrScanDetailTransactionsTitle => 'المعاملات التي أُنشئت';

  @override
  String get ocrScanDetailNoTransactionsMessage =>
      'لم تُنشئ عملية المسح هذه أي معاملات.';

  @override
  String get ocrScanDetailTransactionsKeptNote =>
      'هذه معاملات فعلية في سجلاتك. حذف عملية المسح هذه لا يحذفها.';

  @override
  String get ocrScanDetailDeleteAction => 'حذف عملية المسح';

  @override
  String get ocrScanDetailDeleteTitle => 'حذف عملية المسح هذه؟';

  @override
  String ocrScanDetailDeleteMessage(Object count) {
    return 'سيؤدي هذا إلى حذف عملية المسح وصورتها من جهازك. أما المعاملات التي أنشأتها وعددها $count فلن تُحذف وستبقى في سجلاتك، وكل ما تفقده هو الرابط إلى الصورة الأصلية.';
  }

  @override
  String get ocrScanDetailDeleteConfirm => 'حذف عملية المسح';

  @override
  String get ocrScanDetailDeletedMessage =>
      'تم حذف عملية المسح مع الإبقاء على معاملاتها.';

  @override
  String get ocrScanDetailErrorTitle => 'تعذّر تحميل عملية المسح';

  @override
  String get ocrScanDetailErrorMessage =>
      'حدث خطأ أثناء قراءة عملية المسح هذه.';

  @override
  String get budgetsTitle => 'الميزانيات';

  @override
  String get budgetsOverviewEntrySubtitle =>
      'خطّط لمصروفات هذا الشهر حسب الفئة';

  @override
  String get budgetFormCreateTitle => 'ميزانية جديدة';

  @override
  String get budgetFormEditTitle => 'تعديل الميزانية';

  @override
  String get budgetFormMonthLabel => 'الشهر';

  @override
  String get budgetExpectedIncomeLabel => 'الدخل المتوقع (اختياري)';

  @override
  String get budgetExpectedIncomeHelp =>
      'للرجوع إليه فقط — لا يغيّر طريقة متابعة المصروفات.';

  @override
  String get budgetAllocationsHeader => 'المصروفات المخططة حسب الفئة';

  @override
  String get budgetAllocationsEmpty =>
      'لا توجد فئات بعد. اختر فئة مصروفات بالأسفل لتبدأ التخطيط.';

  @override
  String get budgetAddCategoryHeader => 'إضافة فئة';

  @override
  String get budgetAllCategoriesAdded =>
      'كل فئات المصروفات النشطة موجودة بالفعل في هذه الميزانية.';

  @override
  String get budgetPlannedAmountLabel => 'المبلغ المخطط';

  @override
  String get budgetRemoveAllocationAction => 'إزالة من الميزانية';

  @override
  String get budgetAmountRequiredError => 'أدخل المبلغ المخطط (يُسمح بالصفر)';

  @override
  String get budgetAmountInvalidError => 'أدخل مبلغًا صحيحًا';

  @override
  String get budgetAmountNegativeError => 'لا يمكن أن يكون المبلغ سالبًا';

  @override
  String get budgetTotalPlannedLabel => 'إجمالي المخطط';

  @override
  String budgetExceedsIncomeWarning(String amount) {
    return 'المصروفات المخططة تتجاوز الدخل المتوقع بمقدار $amount';
  }

  @override
  String get budgetExceedsIncomeSaveNote =>
      'لا يزال بإمكانك حفظ هذه الميزانية.';

  @override
  String get budgetDeleteAction => 'حذف الميزانية';

  @override
  String get budgetDeleteConfirmTitle => 'حذف هذه الميزانية؟';

  @override
  String budgetDeleteConfirmMessage(String month) {
    return 'سيتم حذف خطة $month. لن تتأثر مصروفاتك المسجلة.';
  }

  @override
  String get budgetDeletedConfirmation => 'تم حذف الميزانية';

  @override
  String get budgetAlreadyExistsError =>
      'يوجد بالفعل ميزانية لهذا الشهر. افتحها لإجراء التعديلات.';

  @override
  String get budgetDuplicateCategoryError =>
      'هذه الفئة موجودة بالفعل في الميزانية.';

  @override
  String get budgetNotFoundError => 'هذه الميزانية لم تعد موجودة.';

  @override
  String budgetEmptyTitle(String month) {
    return 'لا توجد ميزانية لشهر $month';
  }

  @override
  String get budgetEmptyMessage =>
      'خطّط لما تنوي إنفاقه في كل فئة، ثم تابعه مقابل مصروفاتك الفعلية.';

  @override
  String get budgetCreateAction => 'إنشاء ميزانية';

  @override
  String get budgetLoadErrorTitle => 'تعذّر تحميل الميزانية';

  @override
  String get budgetOverallTitle => 'الإجمالي';

  @override
  String get budgetPlannedLabel => 'المخطط';

  @override
  String get budgetActualLabel => 'المصروف';

  @override
  String get budgetRemainingLabel => 'المتبقي';

  @override
  String get budgetOverByLabel => 'تجاوز بمقدار';

  @override
  String budgetSpentOfPlanned(String actual, String planned) {
    return '$actual من $planned';
  }

  @override
  String budgetRemainingAmount(String amount) {
    return 'متبقٍ $amount';
  }

  @override
  String budgetOverByAmount(String amount) {
    return 'تجاوز بمقدار $amount';
  }

  @override
  String budgetPercentUsed(int percent) {
    return 'مُستخدم $percent٪';
  }

  @override
  String get budgetPercentNotApplicable => 'لا يوجد مبلغ مخطط';

  @override
  String get budgetStatusOnTrack => 'ضمن الخطة';

  @override
  String get budgetStatusNearFull => 'يقترب من الحد';

  @override
  String get budgetStatusOverBudget => 'تجاوز الميزانية';

  @override
  String get budgetCategoryArchivedTag => 'مؤرشفة';

  @override
  String get budgetCategoryMissingName => 'فئة محذوفة';

  @override
  String get budgetCategoriesHeader => 'الفئات';

  @override
  String get budgetNoAllocationsMessage =>
      'لا تحتوي هذه الميزانية على فئات بعد. عدّلها لإضافة المبالغ المخططة.';

  @override
  String get budgetExpectedIncomeDisplay => 'الدخل المتوقع';

  @override
  String get budgetUnbudgetedTitle => 'مصروفات خارج الميزانية';

  @override
  String get budgetUnbudgetedMessage =>
      'ما أُنفق هذا الشهر في فئات غير مدرجة في ميزانيتك.';

  @override
  String get budgetUnbudgetedTotalLabel => 'إجمالي خارج الميزانية';
}
