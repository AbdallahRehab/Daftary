// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get finEduCalcCompoundTitle => 'حاسبة النمو المركب';

  @override
  String get finEduCalcCompoundIntro =>
      'شاهد كيف يمكن أن ينمو مبلغ شهري ثابت مع الوقت بمعدل تختاره أنت، مع تركيب شهري.';

  @override
  String get finEduCalcDoublingTitle => 'حاسبة مدة التضاعف';

  @override
  String get finEduCalcDoublingIntro =>
      'قدّر تقريبًا عدد السنوات اللازمة لتضاعف المال بمعدل سنوي ثابت تختاره أنت.';

  @override
  String get finEduCalcSavingsRateTitle => 'حاسبة نسبة الادخار';

  @override
  String get finEduCalcSavingsRateIntro =>
      'احسب النسبة التي يتم ادخارها من الدخل، باستخدام أرقام تُدخلها بنفسك.';

  @override
  String get finEduCalcMonthlyContributionLabel => 'المبلغ الشهري (جنيه)';

  @override
  String get finEduCalcAnnualRateLabel => 'معدل النمو السنوي (%)';

  @override
  String get finEduCalcYearsLabel => 'المدة (بالسنوات)';

  @override
  String get finEduCalcIncomeLabel => 'الدخل (جنيه)';

  @override
  String get finEduCalcSavingsAmountLabel => 'المبلغ المدخر (جنيه)';

  @override
  String get finEduCalcCalculate => 'احسب';

  @override
  String get finEduCalcPrefillFromSavingsGoal => 'ابدأ من مبلغ هدف الادخار';

  @override
  String get finEduCalcPrefillHint =>
      'يملأ المبلغ كنقطة بداية فقط — يمكنك تغييره بحرية.';

  @override
  String get finEduCalcErrorRequired => 'أدخل قيمة';

  @override
  String get finEduCalcErrorInvalidNumber => 'أدخل رقمًا صحيحًا';

  @override
  String get finEduCalcErrorWholeYears => 'أدخل عددًا صحيحًا من السنوات';

  @override
  String get finEduCalcErrorAmountPositive => 'أدخل مبلغًا أكبر من صفر';

  @override
  String get finEduCalcErrorRateNegative => 'لا يمكن أن يكون المعدل سالبًا';

  @override
  String get finEduCalcErrorRatePositive =>
      'أدخل معدلًا أكبر من صفر — مدة التضاعف غير معرّفة عند 0%';

  @override
  String get finEduCalcErrorYearsPositive => 'أدخل مدة لا تقل عن سنة واحدة';

  @override
  String get finEduCalcErrorIncomePositive => 'أدخل دخلًا أكبر من صفر';

  @override
  String get finEduCalcErrorSavingsNegative =>
      'لا يمكن أن يكون المبلغ المدخر سالبًا';

  @override
  String get finEduCalcErrorResultTooLarge =>
      'هذه المدخلات تنتج رقمًا أكبر من أن يُعرض. جرّب مبلغًا أو معدلًا أو مدة أصغر.';

  @override
  String get finEduCalcResultFutureValue => 'الإجمالي المتوقع';

  @override
  String get finEduCalcResultTotalContributed => 'إجمالي المساهمات';

  @override
  String get finEduCalcResultTotalGrowth => 'إجمالي النمو';

  @override
  String get finEduCalcResultDoublingYears => 'مدة التضاعف التقريبية';

  @override
  String get finEduCalcResultSavingsRate => 'نسبة الادخار';

  @override
  String finEduCalcYearsValue(String years) {
    return '$years سنة';
  }

  @override
  String finEduCalcPercentValue(String percent) {
    return '$percent٪';
  }

  @override
  String get finEduCalcIllustrativeNote =>
      'للتوضيح فقط — يفترض معدلًا ثابتًا؛ العوائد الفعلية تتغير وغير مضمونة';

  @override
  String get finEduCalcHighRateNote =>
      'هذا المعدل مرتفع بشكل غير معتاد. النتيجة للتوضيح فقط — نادرًا ما تستمر عوائد بهذا الارتفاع.';

  @override
  String get finEduCalcRuleOf72Note =>
      'تقدير تقريبي باستخدام قاعدة 72 (72 ÷ المعدل السنوي)، وليس رقمًا دقيقًا.';

  @override
  String get finEduCalcSavingsAboveIncomeNote =>
      'المبلغ المدخر أكبر من الدخل المُدخل، لذلك النسبة أعلى من 100%.';

  @override
  String get finEduCalcSavingsRateNote =>
      'محسوبة فقط من الرقمين اللذين أدخلتهما.';

  @override
  String get finEduTitle => 'التثقيف المالي';

  @override
  String get finEduSettingsSectionTitle => 'تعلّم';

  @override
  String get finEduSettingsEntrySubtitle => 'مقالات وحاسبات توضيحية';

  @override
  String get finEduDisclaimer =>
      'لأغراض تعليمية عامة فقط. هذا المحتوى ليس نصيحة مالية أو استثمارية مخصصة لك.';

  @override
  String get finEduTopicsSectionTitle => 'الموضوعات';

  @override
  String get finEduToolsSectionTitle => 'الحاسبات';

  @override
  String get finEduCompoundGrowthTileTitle => 'النمو المركب';

  @override
  String get finEduCompoundGrowthTileSubtitle =>
      'شاهد كيف يمكن أن ينمو مبلغ شهري منتظم مع الوقت';

  @override
  String get finEduDoublingTimeTileTitle => 'مدة التضاعف';

  @override
  String get finEduDoublingTimeTileSubtitle =>
      'قدّر المدة اللازمة لتضاعف المال باستخدام قاعدة ٧٢';

  @override
  String get finEduSavingsRateTileTitle => 'نسبة الادخار';

  @override
  String get finEduSavingsRateTileSubtitle =>
      'احسب نسبة الدخل التي يتم ادخارها';

  @override
  String get finEduLoadErrorTitle => 'تعذّر تحميل هذا المحتوى';

  @override
  String get finEduLoadErrorMessage =>
      'حدث خطأ أثناء فتح المحتوى المضمّن. يرجى المحاولة مرة أخرى.';

  @override
  String get finEduRetry => 'حاول مرة أخرى';

  @override
  String get finEduEmptyCategoryTitle => 'لا توجد مقالات بعد';

  @override
  String get finEduEmptyCategoryMessage => 'ستظهر مقالات هذا الموضوع هنا.';

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
  String get commonRetry => 'حاول مرة أخرى';

  @override
  String get commonUndo => 'تراجع';

  @override
  String get errorLoadTitle => 'تعذّر تحميل المحتوى';

  @override
  String get errorCache =>
      'تعذّر قراءة بياناتك أو حفظها على هذا الجهاز. حاول مرة أخرى.';

  @override
  String get errorNotFound => 'هذا العنصر لم يعد موجودًا. ربما تم حذفه.';

  @override
  String get errorValidation =>
      'بعض البيانات غير صحيحة. راجعها وحاول مرة أخرى.';

  @override
  String get errorUnknown => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errorSyncNetwork =>
      'لا يوجد اتصال بالإنترنت. بياناتك محفوظة على هذا الجهاز وستتم مزامنتها عند عودة الاتصال.';

  @override
  String get errorSyncTimeout =>
      'استغرقت السحابة وقتًا طويلًا للرد. سنحاول مرة أخرى قريبًا.';

  @override
  String get errorSyncServer =>
      'تواجه الخدمة السحابية مشكلة الآن. سنحاول مرة أخرى قريبًا.';

  @override
  String get errorSyncUnauthorized =>
      'انتهت جلستك السحابية. سجّل الدخول مرة أخرى لمتابعة المزامنة.';

  @override
  String get errorSyncForbidden => 'حسابك السحابي لا يسمح بهذا التغيير.';

  @override
  String get errorSyncRejected =>
      'تعذّر على السحابة قبول هذا التغيير. راجعه وحاول مرة أخرى.';

  @override
  String get errorSyncConflict =>
      'تم تغيير هذا السجل على جهاز آخر. اختر النسخة التي تريد الاحتفاظ بها.';

  @override
  String get peopleListTitle => 'الأشخاص';

  @override
  String get searchPeopleHint => 'ابحث عن شخص';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterTheyOweYou => 'لك عندهم';

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
  String archivePersonTooltip(String name) {
    return 'أرشفة $name';
  }

  @override
  String personArchivedMessage(String name) {
    return 'تمت أرشفة $name. يمكنك العثور عليه في الأشخاص المؤرشفين.';
  }

  @override
  String get addPersonAction => 'إضافة شخص';

  @override
  String get personFormCreateTitle => 'شخص جديد';

  @override
  String get personFormEditTitle => 'تعديل الشخص';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get nameRequiredError => 'أدخل الاسم';

  @override
  String get personRequiredError => 'اختر شخصًا أو أنشئ شخصًا جديدًا';

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
  String get duplicateWarningMessage =>
      'يوجد في قائمتك شخص باسم مشابه. هل هو الشخص نفسه؟';

  @override
  String get duplicateUseExisting => 'استخدام الشخص الموجود';

  @override
  String get duplicateCreateNew => 'إنشاء شخص جديد على أي حال';

  @override
  String get transactionFormCreateTitle => 'تسجيل معاملة';

  @override
  String get transactionFormEditTitle => 'تعديل المعاملة';

  @override
  String get amountLabel => 'المبلغ';

  @override
  String get amountInvalidError => 'أدخل مبلغًا أكبر من صفر، بحد أقصى 12 رقمًا';

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
      'ستُحذف من سجل هذا الشخص ومن رصيده. لا يمكن التراجع عن ذلك.';

  @override
  String get deleteTransactionTooltip => 'حذف المعاملة';

  @override
  String get overviewTitle => 'نظرة عامة';

  @override
  String get overviewTotalOwedToYou => 'إجمالي المستحق لك';

  @override
  String get overviewTotalYouOwe => 'إجمالي المستحق عليك';

  @override
  String get overviewSectionTheyOweYou => 'لك عندهم';

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
      'تعذّر حفظ اختيار اللغة. هو مفعّل الآن لكنه قد يعود كما كان عند فتح التطبيق مرة أخرى — جرّب اختياره من جديد.';

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
      'تعذّر حفظ اختيار المظهر. هو مفعّل الآن لكنه قد يعود كما كان عند فتح التطبيق مرة أخرى — جرّب اختياره من جديد.';

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
      'إقراض صديق نقودًا، أو تقاسم هدية، أو تغطية شخص في مناسبة — سجّلها مع هذا الشخص حتى لا تُنسى.';

  @override
  String get onboardingScanningRecordsTitle => 'راجع سجلك وقتما احتجت';

  @override
  String get onboardingScanningRecordsDescription =>
      'يُحفظ كل إدخال بتاريخه، لذا يمكنك مراجعة سجلك الكامل مع أي شخص في أي وقت.';

  @override
  String get onboardingIncomeExpenseTitle => 'اعرف أين تذهب أموالك';

  @override
  String get onboardingIncomeExpenseDescription =>
      'سجّل دخلك ومصروفاتك حسب الفئة، وشاهد إجماليات كل شهر بجانب ما لك عند الناس.';

  @override
  String get onboardingBackAction => 'رجوع';

  @override
  String get onboardingNextAction => 'التالي';

  @override
  String get onboardingGetStartedAction => 'ابدأ الآن';

  @override
  String get onboardingSkipAction => 'تخطي';

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
  String get financeCategoryNameRequiredError => 'أدخل اسم الفئة';

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
  String notificationBudgetNearLimitTitle(String category) {
    return 'ميزانية $category تقترب من حدّها';
  }

  @override
  String notificationBudgetNearLimitBody(String category, String percent) {
    return 'استخدمت $percent٪ من ميزانية $category هذا الشهر.';
  }

  @override
  String notificationBudgetExceededTitle(String category) {
    return 'تجاوزت ميزانية $category';
  }

  @override
  String notificationBudgetExceededBody(String category, String percent) {
    return 'أنفقت $percent٪ من ميزانية $category هذا الشهر.';
  }

  @override
  String notificationBudgetExceededNoPlanBody(String category) {
    return 'لديك مصروفات على $category هذا الشهر رغم أنه لم يُخصَّص لها أي مبلغ.';
  }

  @override
  String notificationSavingsBehindPaceTitle(String goal) {
    return 'هدف $goal متأخر عن خطته';
  }

  @override
  String notificationSavingsBehindPaceBody(String goal, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months شهر',
      many: '$months شهرًا',
      few: '$months أشهر',
      two: 'شهرين',
      one: 'شهرًا واحدًا',
    );
    return 'بوتيرتك الحالية ستبلغ هدف $goal متأخرًا $_temp0 عن الموعد المخطط.';
  }

  @override
  String notificationSavingsAheadOfPaceTitle(String goal) {
    return 'هدف $goal يسبق موعده';
  }

  @override
  String notificationSavingsAheadOfPaceBody(String goal, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months شهر',
      many: '$months شهرًا',
      few: '$months أشهر',
      two: 'شهرين',
      one: 'شهر واحد',
    );
    return 'أحسنت — أنت في طريقك لبلوغ هدف $goal قبل موعده بـ$_temp0.';
  }

  @override
  String notificationSavingsAchievedTitle(String goal) {
    return 'تحقق الهدف: $goal';
  }

  @override
  String notificationSavingsAchievedBody(String goal) {
    return 'لقد ادّخرت المبلغ كاملًا لهدف $goal. أحسنت!';
  }

  @override
  String get notificationSettingsTitle => 'الإشعارات';

  @override
  String get notificationSettingsEntrySubtitle =>
      'تنبيهات الميزانية ومتابعة أهداف الادخار وساعات الهدوء';

  @override
  String get notificationSettingsMasterTitle => 'تذكيرات الميزانية والادخار';

  @override
  String get notificationSettingsMasterOffDescription =>
      'متوقفة افتراضيًا. فعّلها لتصلك تنبيهات عندما توشك ميزانية على النفاد أو يبتعد هدف ادخار عن خطته. تُحسب كلها على هذا الجهاز من بياناتك أنت.';

  @override
  String get notificationSettingsMasterOnDescription =>
      'لن تصلك تذكيرات إلا عندما يتغيّر شيء فعلًا في ميزانياتك أو أهدافك.';

  @override
  String get notificationSettingsCategoriesHeader =>
      'ما الذي تريد التنبيه بشأنه';

  @override
  String get notificationBudgetWarningsTitle => 'تنبيهات الميزانية';

  @override
  String get notificationBudgetWarningsSubtitle =>
      'عندما تقترب فئة من حدها الشهري أو تتجاوزه';

  @override
  String get notificationSavingsCheckInsTitle => 'متابعة أهداف الادخار';

  @override
  String get notificationSavingsCheckInsSubtitle =>
      'عندما يتأخر هدف عن خطته أو يسبقها، أو عند تحقيقه';

  @override
  String get notificationQuietHoursTitle => 'ساعات الهدوء';

  @override
  String get notificationQuietHoursSubtitle =>
      'أجِّل الإشعارات خلال هذه الساعات وأرسلها بعدها';

  @override
  String get notificationQuietHoursFrom => 'من';

  @override
  String get notificationQuietHoursTo => 'إلى';

  @override
  String get notificationQuietHoursNextDay => 'اليوم التالي';

  @override
  String get notificationPermissionRationaleTitle => 'السماح بالإشعارات؟';

  @override
  String get notificationPermissionRationaleMessage =>
      'يحتاج دفتري إلى إذنك لعرض هذه التذكيرات. وهي تخص ميزانياتك وأهداف ادخارك فقط، ولا يغادر أي شيء جهازك.';

  @override
  String get notificationPermissionRationaleConfirm => 'متابعة';

  @override
  String get notificationPermissionDeniedTitle => 'الإشعارات محظورة';

  @override
  String get notificationPermissionDeniedMessage =>
      'جهازك لا يسمح لدفتري بعرض الإشعارات، لذلك لن يصلك شيء رغم تفعيل التذكيرات. اسمح بالإشعارات من إعدادات جهازك لتبدأ في تلقيها.';

  @override
  String get notificationPermissionDeniedAction => 'فتح إعدادات الجهاز';

  @override
  String get notificationSettingsSaveFailed =>
      'تعذّر حفظ إعدادات الإشعارات. حاول مرة أخرى.';

  @override
  String get notificationSettingsLoadFailed => 'تعذّر تحميل إعدادات الإشعارات.';

  @override
  String get notificationBudgetNoLongerExists => 'هذه الميزانية لم تعد موجودة.';

  @override
  String get notificationSavingsGoalNoLongerExists =>
      'هدف الادخار هذا لم يعد موجودًا.';

  @override
  String get currencyFieldLabel => 'العملة';

  @override
  String get rateNeededTitle => 'الإجمالي غير متاح — يلزم سعر صرف';

  @override
  String rateNeededMessage(String currencies) {
    return 'أضف سعر صرف لـ $currencies لعرض هذا الإجمالي. سجلاتك آمنة ولم تتغير.';
  }

  @override
  String get rateNeededAction => 'تعيين سعر الصرف';

  @override
  String get currencySettingsTitle => 'العملة';

  @override
  String get currencySettingsEntrySubtitle => 'العملة الأساسية وأسعار الصرف';

  @override
  String get primaryCurrencyLabel => 'العملة الأساسية';

  @override
  String get primaryCurrencyDescription =>
      'تُعرض كل الإجماليات والأرصدة بهذه العملة.';

  @override
  String get primaryCurrencyChange => 'تغيير';

  @override
  String get primaryCurrencyChanged => 'تم تحديث العملة الأساسية';

  @override
  String get primaryCurrencySwitchRateTitle => 'يلزم سعر صرف';

  @override
  String primaryCurrencySwitchRateMessage(String previous, String next) {
    return 'لديك سجلات بعملة $previous. أدخل قيمة واحد $previous بعملة $next حتى تظل إجمالياتك صحيحة.';
  }

  @override
  String get exchangeRatesTitle => 'أسعار الصرف';

  @override
  String get exchangeRatesManualDisclosure =>
      'أنت من يُدخل الأسعار ولا تُجلب تلقائيًا أبدًا. حدّثها متى شئت.';

  @override
  String get exchangeRatesEmpty => 'لا توجد أسعار صرف بعد';

  @override
  String get exchangeRateAdd => 'إضافة سعر';

  @override
  String get exchangeRateEditTitle => 'سعر الصرف';

  @override
  String exchangeRateValueLabel(String from, String to) {
    return 'قيمة 1 $from بعملة $to';
  }

  @override
  String exchangeRateLastUpdated(String date) {
    return 'آخر تحديث $date';
  }

  @override
  String get exchangeRateInvalid => 'أدخل سعرًا أكبر من صفر';

  @override
  String get exchangeRateSave => 'حفظ';

  @override
  String get exchangeRateRemove => 'حذف السعر';

  @override
  String get exchangeRateRemoveConfirm =>
      'ستصبح الإجماليات التي تحتاج هذا السعر غير متاحة حتى تضيفه مرة أخرى. لن تتغير سجلاتك.';

  @override
  String get exchangeRateSaveFailed => 'تعذر حفظ سعر الصرف. حاول مرة أخرى.';

  @override
  String get currencySettingsLoadFailed => 'تعذر تحميل إعدادات العملة.';

  @override
  String get primaryCurrencyChangeFailed =>
      'تعذر تغيير العملة الأساسية. حاول مرة أخرى.';

  @override
  String get splashTagline => 'كل أخذ وعطاء في دفتر واحد';

  @override
  String get splashErrorMessage => 'تعذّر إكمال فتح دفتري. حاول مرة أخرى.';

  @override
  String get appearanceSectionTitle => 'التأثيرات المرئية';

  @override
  String get liquidGlassTitle => 'الزجاج السائل';

  @override
  String get liquidGlassSubtitle => 'تأثير زجاجي مصنفر على الأشرطة والأزرار';

  @override
  String get glassSaveFailed =>
      'تعذّر حفظ إعداد الزجاج. سيظل مطبقًا حتى تغلق التطبيق.';

  @override
  String get glassTransparencyTitle => 'شفافية الزجاج';

  @override
  String get glassIntensityTitle => 'قوة الزجاج';

  @override
  String get glassLevelLow => 'منخفضة';

  @override
  String get glassLevelMedium => 'متوسطة';

  @override
  String get glassLevelHigh => 'عالية';

  @override
  String get glassPreviewTitle => 'معاينة';

  @override
  String get glassPreviewSemantics =>
      'نموذج لتأثير الزجاج السائل بإعداداتك الحالية';
}
