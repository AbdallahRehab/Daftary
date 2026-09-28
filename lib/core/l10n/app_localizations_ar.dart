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

  @override
  String get syncConflictBadgeLabel => 'تعارض';

  @override
  String get syncConflictBadgeSemantics =>
      'تم تعديله على جهاز آخر. اختر النسخة التي تريد الاحتفاظ بها.';

  @override
  String get syncConflictSheetTitle => 'تم التعديل على جهازين';

  @override
  String get syncConflictSheetMessage =>
      'تم تعديل هذا السجل على هذا الجهاز وعلى جهاز آخر. اختر النسخة التي تريد الاحتفاظ بها. تُحفظ النسخة الأخرى في السجل.';

  @override
  String get syncConflictMineLabel => 'هذا الجهاز';

  @override
  String get syncConflictTheirsLabel => 'جهاز آخر';

  @override
  String get syncConflictKeepMine => 'الاحتفاظ بنسختي';

  @override
  String get syncConflictKeepTheirs => 'الاحتفاظ بالنسخة الأخرى';

  @override
  String get syncConflictDeletedLabel => 'محذوف';

  @override
  String get syncConflictResolveFailed => 'تعذّر حل التعارض. حاول مرة أخرى.';

  @override
  String get syncSettingsTitle => 'النسخ الاحتياطي والمزامنة';

  @override
  String get syncStatusUpToDate => 'كل شيء محدَّث';

  @override
  String syncStatusPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغيير في انتظار المزامنة',
      few: '$count تغييرات في انتظار المزامنة',
      two: 'تغييران في انتظار المزامنة',
      one: 'تغيير واحد في انتظار المزامنة',
    );
    return '$_temp0';
  }

  @override
  String get syncStatusSyncing => 'جارٍ المزامنة…';

  @override
  String get syncStatusOffline =>
      'غير متصل. التغييرات محفوظة على هذا الجهاز وستتم مزامنتها لاحقًا.';

  @override
  String get syncStatusRetrying =>
      'تعذّر الوصول إلى السحابة. ستتم المحاولة مرة أخرى قريبًا.';

  @override
  String get syncStatusFailed => 'تعذّرت مزامنة بعض التغييرات';

  @override
  String get syncStatusConflict => 'بعض السجلات تحتاج إلى مراجعتك';

  @override
  String get syncStatusAuthRequired =>
      'انتهت جلستك السحابية. ستُستأنف المزامنة بعد تسجيل الدخول مرة أخرى.';

  @override
  String get syncStatusOff => 'المزامنة متوقفة. تبقى بياناتك على هذا الجهاز.';

  @override
  String get syncStatusUnavailable =>
      'النسخ الاحتياطي السحابي غير متاح في هذا الإصدار.';

  @override
  String get syncStatusUnreadable => 'تعذّرت قراءة بعض بيانات السحابة';

  @override
  String get syncProblemUnreadableMessage =>
      'تعذّر على هذا الإصدار من التطبيق قراءة بعض البيانات القادمة من أجهزتك الأخرى. لم يُفقد أي شيء. حدّث التطبيق وستستمر المزامنة.';

  @override
  String syncLastSynced(String dateTime) {
    return 'آخر مزامنة $dateTime';
  }

  @override
  String get syncNeverSynced => 'لم تتم المزامنة بعد';

  @override
  String get syncCountPending => 'في الانتظار';

  @override
  String get syncCountFailed => 'فشلت';

  @override
  String get syncCountConflicts => 'تعارضات';

  @override
  String get syncNowButton => 'زامن الآن';

  @override
  String get syncEnabledTitle => 'النسخ الاحتياطي والمزامنة';

  @override
  String get syncEnabledSubtitle =>
      'احتفظ بنسخة من بياناتك في السحابة وعلى هواتفك الأخرى.';

  @override
  String get syncAccountSectionTitle => 'الحساب';

  @override
  String get syncLinkEmailTitle => 'ربط البريد الإلكتروني';

  @override
  String get syncLinkEmailSubtitle =>
      'استخدم بريدك الإلكتروني لاستعادة بياناتك على هاتف جديد.';

  @override
  String get syncSignInTitle => 'تسجيل الدخول إلى حساب موجود';

  @override
  String get syncSignInSubtitle =>
      'استخدم البيانات المحفوظة مسبقًا ببريدك الإلكتروني.';

  @override
  String syncLinkedAs(String email) {
    return 'مرتبط بـ $email';
  }

  @override
  String get syncConflictsSectionTitle => 'تحتاج إلى مراجعتك';

  @override
  String syncConflictItemSubtitle(String date) {
    return 'تم التعديل على جهازين · $date';
  }

  @override
  String get syncFailedSectionTitle => 'تعذّرت المزامنة';

  @override
  String get syncRetryButton => 'إعادة المحاولة';

  @override
  String get syncKindPerson => 'شخص';

  @override
  String get syncKindTransaction => 'معاملة';

  @override
  String get syncKindTransactionHistory => 'سجل المعاملة';

  @override
  String get syncKindFinanceCategory => 'فئة';

  @override
  String get syncKindFinanceEntry => 'قيد مالي';

  @override
  String get syncKindExchangeRate => 'سعر صرف';

  @override
  String get syncKindPrimaryCurrency => 'العملة الأساسية';

  @override
  String get syncKindConflictResolution => 'اختيار تعارض';

  @override
  String get syncKindOccasion => 'مناسبة';

  @override
  String get syncKindBudget => 'ميزانية';

  @override
  String get syncKindBudgetAllocation => 'فئة في الميزانية';

  @override
  String get syncFailedReasonPersonHasTransactions =>
      'لهذا الشخص معاملات على جهاز آخر.';

  @override
  String get syncFailedReasonCategoryTypeMismatch =>
      'نوع هذه الفئة لا يطابق قيودها.';

  @override
  String get syncFailedReasonInvalid => 'تعذّر على السحابة قبول هذا التغيير.';

  @override
  String get syncFailedReasonOther => 'تعذّر إرسال هذا التغيير.';

  @override
  String get syncEmailLinkTitle => 'ربط بريدك الإلكتروني';

  @override
  String get syncEmailSignInTitle => 'تسجيل الدخول بالبريد الإلكتروني';

  @override
  String get syncEmailLinkMessage =>
      'سنرسل رمزًا إلى بريدك الإلكتروني. تبقى بياناتك كما هي.';

  @override
  String get syncEmailSignInMessage =>
      'سنرسل رمزًا إلى بريدك الإلكتروني. ستُضاف البيانات الموجودة على هذا الهاتف إلى ذلك الحساب.';

  @override
  String get syncEmailFieldLabel => 'البريد الإلكتروني';

  @override
  String get syncEmailSendCode => 'إرسال الرمز';

  @override
  String syncEmailCodeSent(String email) {
    return 'أرسلنا رمزًا إلى $email.';
  }

  @override
  String get syncEmailCodeFieldLabel => 'الرمز';

  @override
  String get syncEmailConfirm => 'تأكيد';

  @override
  String get syncEmailLinkSuccess => 'تم ربط البريد الإلكتروني';

  @override
  String get syncEmailSignInSuccess =>
      'تم تسجيل الدخول. ستتم مزامنة بياناتك الآن.';

  @override
  String get syncEmailErrorInvalidCode => 'الرمز غير صحيح أو انتهت صلاحيته.';

  @override
  String get syncEmailErrorInvalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا.';

  @override
  String get syncEmailErrorEmailInUse =>
      'لهذا البريد حساب بالفعل. استخدم \"تسجيل الدخول إلى حساب موجود\" بدلًا من ذلك.';

  @override
  String get syncEmailErrorAccountNotFound =>
      'لا يوجد حساب بهذا البريد الإلكتروني.';

  @override
  String get syncEmailErrorRateLimited =>
      'محاولات كثيرة. انتظر دقيقة ثم حاول مرة أخرى.';

  @override
  String get syncNoticeTitle => 'يمكنك الآن نسخ بياناتك احتياطيًا';

  @override
  String get syncNoticeMessage =>
      'يحتفظ دفتري الآن بنسخة خاصة من سجلاتك في السحابة، لتتمكن من استعادتها على هاتف جديد. يمكنك إيقاف ذلك في أي وقت من الإعدادات.';

  @override
  String get syncNoticeOpenSettings => 'إعدادات المزامنة';

  @override
  String get syncNoticeDismiss => 'حسنًا';

  @override
  String get appLockLockTitle => 'دفتري مقفل';

  @override
  String get appLockLockPrompt => 'أدخل رمز PIN للمتابعة';

  @override
  String get appLockLockBiometricReason => 'افتح دفتري لعرض بياناتك المالية';

  @override
  String get appLockLockUseBiometric => 'الفتح بالبصمة';

  @override
  String get appLockLockBiometricInProgress =>
      'بانتظار التحقق بالبصمة. يمكنك أيضًا إدخال رمز PIN.';

  @override
  String get appLockLockVerifying => 'جارٍ التحقق من رمز PIN…';

  @override
  String get appLockLockIncorrectPin => 'رمز PIN غير صحيح. حاول مرة أخرى.';

  @override
  String get appLockLockBiometricFailed =>
      'لم ينجح الفتح بالبصمة. حاول مرة أخرى أو أدخل رمز PIN.';

  @override
  String get appLockLockBiometricUnavailable =>
      'الفتح بالبصمة غير متاح على هذا الجهاز حاليًا. أدخل رمز PIN بدلًا من ذلك.';

  @override
  String get appLockLockUnexpectedError => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get appLockLockCooldownTitle => 'محاولات خاطئة كثيرة';

  @override
  String appLockLockCooldownMessage(String time) {
    return 'تم إيقاف إدخال رمز PIN مؤقتًا. حاول مرة أخرى بعد $time.';
  }

  @override
  String get appLockLockCooldownBiometricHint =>
      'لا يزال بإمكانك الفتح بالبصمة.';

  @override
  String get appLockPinPadDelete => 'حذف آخر رقم';

  @override
  String get appLockPinPadSubmit => 'تأكيد رمز PIN';

  @override
  String appLockPinPadDigitsEntered(int count) {
    return 'عدد الأرقام المُدخلة: $count';
  }

  @override
  String get appLockPinSetupTitle => 'تعيين رمز PIN';

  @override
  String get appLockPinChangeTitle => 'تغيير رمز PIN';

  @override
  String get appLockPinResetTitle => 'تعيين رمز PIN جديد';

  @override
  String get appLockPinVerifyCurrentPrompt => 'أدخل رمز PIN الحالي';

  @override
  String get appLockPinVerifyCurrentHint => 'لتغيير رمز PIN، أكّد هويتك أولًا.';

  @override
  String get appLockPinEnterNewPrompt => 'اختر رمز PIN';

  @override
  String get appLockPinEnterNewHint =>
      'استخدم من 4 إلى 6 أرقام. لا يغادر رمز PIN هذا الجهاز أبدًا.';

  @override
  String get appLockPinConfirmNewPrompt => 'أدخل رمز PIN نفسه مرة أخرى';

  @override
  String get appLockPinConfirmNewHint => 'للتأكد من أنك كتبت الرمز الذي تقصده.';

  @override
  String get appLockPinMismatch =>
      'الرمزان غير متطابقين. أدخل رمز التأكيد مرة أخرى.';

  @override
  String get appLockPinInvalid => 'يجب أن يتكون رمز PIN من 4 إلى 6 أرقام.';

  @override
  String get appLockPinIncorrectCurrent =>
      'هذا ليس رمز PIN الحالي. حاول مرة أخرى.';

  @override
  String get appLockPinBiometricFailed =>
      'لم ينجح التحقق بالبصمة. حاول مرة أخرى أو أدخل رمز PIN الحالي.';

  @override
  String get appLockPinBiometricUnavailable =>
      'البصمة غير متاحة حاليًا. أدخل رمز PIN الحالي بدلًا من ذلك.';

  @override
  String get appLockPinUnexpectedError => 'تعذّر حفظ رمز PIN. حاول مرة أخرى.';

  @override
  String get appLockPinStartOver => 'البدء من جديد';

  @override
  String get appLockPinUseBiometric => 'استخدام البصمة بدلًا من ذلك';

  @override
  String get appLockPinBiometricReason => 'أكّد هويتك لتغيير رمز PIN';

  @override
  String get appLockPinSaving => 'جارٍ حفظ رمز PIN…';

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
  String get commonRestore => 'استعادة';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonSearch => 'بحث';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get commonError => 'حدث خطأ ما';

  @override
  String get onboardingAiAssistantTitle => 'احصل على مساعدة لفهم كل شيء';

  @override
  String get onboardingAiAssistantDescription =>
      'يمكن لمساعد الذكاء الاصطناعي مساعدتك في مراجعة وتنظيم ما سجّلته — وهو لا يقدّم استشارات مالية ولا يضمن أي نتائج.';

  @override
  String get financeTitle => 'الدخل والمصروفات';

  @override
  String get financeUndoAction => 'تراجع';

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

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get homeFinancialSnapshotTitle => 'لمحة مالية';

  @override
  String get homeFinanceThisMonthTitle => 'هذا الشهر';

  @override
  String get homeFinanceIncome => 'الدخل';

  @override
  String get homeFinanceExpenses => 'المصروفات';

  @override
  String get homeFinanceNet => 'الصافي';

  @override
  String get homeQuickActionsTitle => 'إجراءات سريعة';

  @override
  String get homeQuickAddExpense => 'إضافة مصروف';

  @override
  String get homeQuickAddIncome => 'إضافة دخل';

  @override
  String get homeQuickAddPerson => 'إضافة شخص';

  @override
  String get homeQuickMoneyReceived => 'مبلغ استلمته';

  @override
  String get homeQuickMoneyGiven => 'مبلغ أعطيته';

  @override
  String get homeQuickAddOccasion => 'إضافة مناسبة';

  @override
  String get homeQuickScanPaper => 'مسح ورقة';

  @override
  String get homeSectionsTitle => 'الأقسام';

  @override
  String get homeInsightsTitle => 'رؤى';

  @override
  String get homeInsightsPlaceholder =>
      'ستظهر الرؤى هنا بعد إعداد المساعد الذكي.';

  @override
  String get homeUpcomingTitle => 'القادم';

  @override
  String get homeUpcomingPlaceholder =>
      'ستظهر هنا الفواتير القادمة ومحطات أهداف الادخار بعد توفر التذكيرات وأهداف الادخار.';

  @override
  String get homeOverviewLoadError => 'تعذر تحميل الأرصدة.';

  @override
  String get homeFinanceLoadError => 'تعذر تحميل دخل ومصروفات هذا الشهر.';

  @override
  String get homeFullErrorMessage =>
      'تعذر تحميل لوحتك الرئيسية. حاول مرة أخرى.';

  @override
  String get homeEmptyTitle => 'مرحبًا بك في دفتري';

  @override
  String get homeEmptyMessage =>
      'تابع من عليه مال لك، وما عليك، وأين تذهب أموالك كل شهر — وكل ذلك على جهازك.';

  @override
  String get homeEmptyAction => 'أضف أول شخص';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get reportsOpenAction => 'التقارير';

  @override
  String get reportsTrendTitle => 'الاتجاه الشهري';

  @override
  String reportsTrendSubtitle(int months) {
    return 'الدخل والمصروفات خلال آخر $months أشهر';
  }

  @override
  String get reportsBreakdownTitle => 'الإنفاق حسب الفئة';

  @override
  String get reportsIncome => 'الدخل';

  @override
  String get reportsExpenses => 'المصروفات';

  @override
  String get reportsNet => 'الصافي';

  @override
  String get reportsPeriodThisMonth => 'هذا الشهر';

  @override
  String get reportsPeriodLastMonth => 'الشهر الماضي';

  @override
  String get reportsPeriodLast3Months => 'آخر 3 أشهر';

  @override
  String get reportsPeriodLast6Months => 'آخر 6 أشهر';

  @override
  String get reportsBreakdownEmpty => 'لا توجد مصروفات مسجلة في هذه الفترة.';

  @override
  String get reportsEmptyTitle => 'لا توجد تقارير بعد';

  @override
  String get reportsEmptyMessage =>
      'سجّل أول دخل أو مصروف لتبدأ في رؤية الاتجاهات وتوزيع الفئات.';

  @override
  String get reportsEmptyAction => 'أضف قيدًا';

  @override
  String get reportsLoadError => 'تعذر تحميل تقاريرك. حاول مرة أخرى.';

  @override
  String get reportsExportAction => 'تصدير بياناتي';

  @override
  String reportsCategoryShare(String percent) {
    return '$percent٪';
  }

  @override
  String get exportTitle => 'تصدير بياناتي';

  @override
  String get exportDescription =>
      'أنشئ ملف CSV واحدًا يحتوي على نسخة كاملة من بياناتك: الأشخاص والمعاملات وقيود الدخل والمصروفات والفئات والإعدادات. يُنشأ الملف على جهازك وأنت من يختار أين يرسله.';

  @override
  String get exportGenerateAction => 'إنشاء ملف التصدير';

  @override
  String get exportGenerating => 'جارٍ تجهيز ملف التصدير…';

  @override
  String get exportReadyTitle => 'ملف التصدير جاهز';

  @override
  String exportReadyMessage(int count) {
    return 'تم تضمين $count سجلًا.';
  }

  @override
  String get exportShareAction => 'مشاركة الملف';

  @override
  String get exportRegenerateAction => 'إنشاء ملف تصدير جديد';

  @override
  String get exportError =>
      'تعذر إنشاء ملف التصدير. لم يُحفظ أي ملف ناقص. حاول مرة أخرى.';

  @override
  String get exportShareError => 'تعذر فتح قائمة المشاركة. حاول مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get settingsDataSectionTitle => 'بياناتك';

  @override
  String get settingsExportTile => 'تصدير بياناتي';

  @override
  String get settingsDangerZoneTitle => 'منطقة الخطر';

  @override
  String get settingsDeleteDataTile => 'حذف بياناتي';

  @override
  String get settingsDeleteDataSubtitle =>
      'امسح كل ما هو محفوظ في دفتري نهائيًا';

  @override
  String get securitySettingsTitle => 'الأمان';

  @override
  String get securitySettingsTileSubtitle =>
      'قفل التطبيق والرمز السري والحماية من لقطات الشاشة';

  @override
  String get appLockSettingsSectionTitle => 'قفل التطبيق';

  @override
  String get appLockSettingsToggleTitle => 'قفل دفتري';

  @override
  String get appLockSettingsToggleSubtitle =>
      'اطلب رمزك السري في كل مرة تفتح فيها التطبيق';

  @override
  String get appLockSettingsBiometricTitle => 'الفتح بالبصمة أو بالوجه';

  @override
  String get appLockSettingsBiometricSubtitle => 'يبقى رمزك السري متاحًا أيضًا';

  @override
  String get appLockSettingsBiometricUnavailable =>
      'غير متاح على هذا الجهاز. فعّل البصمة أو التعرّف على الوجه من إعدادات جهازك أولًا.';

  @override
  String get appLockSettingsChangePinTile => 'تغيير الرمز السري';

  @override
  String get appLockSettingsTimeoutTitle => 'القفل بعد مغادرة التطبيق';

  @override
  String get appLockSettingsTimeoutImmediately => 'فورًا';

  @override
  String get appLockSettingsTimeout30Seconds => 'بعد 30 ثانية';

  @override
  String get appLockSettingsTimeout1Minute => 'بعد دقيقة واحدة';

  @override
  String get appLockSettingsTimeout5Minutes => 'بعد 5 دقائق';

  @override
  String get appLockSettingsScreenshotProtectionTitle =>
      'الحماية من لقطات الشاشة';

  @override
  String get appLockSettingsScreenshotProtectionStatus => 'مفعّلة دائمًا';

  @override
  String get appLockSettingsScreenshotProtectionBody =>
      'لا يمكن للقطات الشاشة أو تسجيلها التقاط بياناتك، وتعرض قائمة التطبيقات الأخيرة غطاءً بدلًا منها. تبقى المشاركة والتصدير متاحتين.';

  @override
  String get appLockSettingsDisableTitle => 'إيقاف قفل التطبيق؟';

  @override
  String get appLockSettingsDisableMessage =>
      'سيفتح دفتري دون رمز سري. سيُحذف رمزك السري، لذا ستحتاج إلى اختيار رمز جديد عند تفعيل القفل مرة أخرى. تبقى الحماية من لقطات الشاشة مفعّلة.';

  @override
  String get appLockSettingsDisableConfirm => 'إيقاف';

  @override
  String get appLockSettingsBiometricReason => 'أكّد هويتك لإيقاف قفل التطبيق';

  @override
  String get appLockSettingsReauthTitle => 'أدخل رمزك السري';

  @override
  String get appLockSettingsReauthMessage => 'أكّد هويتك لإيقاف قفل التطبيق.';

  @override
  String get appLockSettingsReauthPinLabel => 'الرمز السري الحالي';

  @override
  String get appLockSettingsReauthConfirm => 'تأكيد';

  @override
  String get appLockSettingsReauthIncorrect =>
      'الرمز السري غير صحيح. حاول مرة أخرى.';

  @override
  String appLockSettingsReauthLockedOut(String duration) {
    return 'محاولات خاطئة كثيرة. حاول مرة أخرى بعد $duration.';
  }

  @override
  String get appLockSettingsReauthFailed =>
      'تعذّر التحقق من رمزك السري. حاول مرة أخرى.';

  @override
  String get appLockSettingsEnabledMessage => 'تم تفعيل قفل التطبيق';

  @override
  String get appLockSettingsDisabledMessage => 'تم إيقاف قفل التطبيق';

  @override
  String get appLockSettingsPinChangedMessage => 'تم تغيير الرمز السري';

  @override
  String get appLockSettingsSaveFailed =>
      'تعذّر حفظ هذا التغيير. حاول مرة أخرى.';

  @override
  String get appLockSettingsLoadFailed => 'تعذّر تحميل إعدادات الأمان.';

  @override
  String get deleteDataTitle => 'حذف بياناتي';

  @override
  String get deleteDataWarningTitle => 'هذا الإجراء نهائي';

  @override
  String get deleteDataWarningMessage =>
      'سيؤدي هذا إلى حذف جميع الأشخاص والمعاملات والمناسبات والمسوحات وقيود الدخل والمصروفات والفئات والميزانيات والإعدادات من هذا الجهاز نهائيًا — ومن نسختك الاحتياطية السحابية أيضًا إن كنت تستخدمها. لا يمكن التراجع عن ذلك. يُنصح بتصدير بياناتك أولًا.';

  @override
  String get deleteDataExportFirstAction => 'صدّر بياناتي أولًا';

  @override
  String get deleteDataConfirmPhrase => 'حذف';

  @override
  String deleteDataConfirmLabel(String phrase) {
    return 'اكتب $phrase للتأكيد';
  }

  @override
  String deleteDataConfirmHint(String phrase) {
    return '$phrase';
  }

  @override
  String get deleteDataConfirmAction => 'احذف كل شيء';

  @override
  String get deleteDataCancelAction => 'إلغاء';

  @override
  String get deleteDataInProgress => 'جارٍ حذف بياناتك…';

  @override
  String get deleteDataError =>
      'تعذر حذف بياناتك. لم يُحذف أي شيء — جميع بياناتك ما زالت سليمة. حاول مرة أخرى.';

  @override
  String get deleteDataCloudUnreachableError =>
      'تعذر الوصول إلى نسختك الاحتياطية السحابية، لذلك لم يُحذف أي شيء — جميع بياناتك ما زالت سليمة. اتصل بالإنترنت وحاول مرة أخرى.';

  @override
  String get appLockForgotTitle => 'نسيت رمز PIN';

  @override
  String get appLockForgotBiometricTitle => 'تحقّق من هويتك';

  @override
  String get appLockForgotBiometricMessage =>
      'أكّد هويتك بالقياسات الحيوية، ثم اختر رمز PIN جديدًا. لن يُمسّ أي شيء من بياناتك.';

  @override
  String get appLockForgotBiometricAction => 'التحقق بالقياسات الحيوية';

  @override
  String get appLockForgotBiometricReason =>
      'تحقّق من هويتك لتعيين رمز PIN جديد لدفتري';

  @override
  String get appLockForgotBiometricFailed =>
      'لم ينجح التحقق بالقياسات الحيوية. يمكنك المحاولة مرة أخرى.';

  @override
  String get appLockForgotBiometricRetry => 'حاول مرة أخرى';

  @override
  String get appLockForgotChooseWipeAction => 'مسح جميع البيانات بدلًا من ذلك';

  @override
  String get appLockForgotWipeTitle => 'الطريقة الوحيدة للعودة';

  @override
  String get appLockForgotWipeMessage =>
      'لا يمكن إعادة تعيين رمز PIN. من دون رمز PIN أو القياسات الحيوية، الطريقة الوحيدة لاستخدام التطبيق مجددًا هي مسح جميع بياناته من هذا الجهاز والبدء من جديد. إذا ربطت النسخ الاحتياطي السحابي ببريدك الإلكتروني، فستبقى نسختك الاحتياطية ويمكنك استعادتها بعد ذلك بتسجيل الدخول بهذا البريد.';

  @override
  String get appLockForgotWipeContinueAction => 'متابعة لمسح البيانات';

  @override
  String get appLockForgotBackAction => 'العودة إلى شاشة القفل';

  @override
  String get appLockWipeTitle => 'مسح جميع البيانات';

  @override
  String get appLockWipeWarningTitle => 'هذا الإجراء نهائي';

  @override
  String get appLockWipeWarningMessage =>
      'سيؤدي هذا إلى مسح جميع الأشخاص والمعاملات والمناسبات والمسوحات وقيود الدخل والمصروفات والفئات والميزانيات والإعدادات ورمز PIN لقفل التطبيق من هذا الجهاز نهائيًا. لا يمكن التراجع عن ذلك، ولا يستطيع دفتري استعادتها.';

  @override
  String get appLockWipeConfirmAction => 'مسح كل شيء';

  @override
  String get appLockWipeCancelAction => 'إلغاء';

  @override
  String get appLockWipeInProgress => 'جارٍ مسح بياناتك…';

  @override
  String get appLockWipeError =>
      'تعذّر مسح بياناتك. لم يُحذف أي شيء — بياناتك ورمز PIN كما هي. حاول مرة أخرى.';

  @override
  String get aiAssistantTitle => 'المساعد الذكي';

  @override
  String get aiAssistantHomeEntrySubtitle =>
      'اسأل عن أموالك أنت. متوقف حتى تقوم بإعداده.';

  @override
  String get aiSettingsTitle => 'إعدادات المساعد الذكي';

  @override
  String get aiSettingsIntroTitle => 'المساعد متوقف';

  @override
  String get aiSettingsIntroMessage =>
      'لتشغيله، اختر مزوّد الذكاء الاصطناعي، وأدخل مفتاح API الخاص بك، وراجع بالضبط ما الذي ستتم مشاركته. لا يأتي دفتري بأي مفتاح خاص به.';

  @override
  String get aiSettingsProviderSectionTitle => 'المزوّد';

  @override
  String get aiSettingsProviderCustom => 'مزوّد مخصص';

  @override
  String get aiSettingsCustomProviderHint =>
      'أي مزوّد يوفّر واجهة محادثة متوافقة مع OpenAI وتدعم استدعاء الأدوات.';

  @override
  String get aiSettingsCustomBaseUrlLabel => 'عنوان API الأساسي (https://…)';

  @override
  String get aiSettingsCustomModelLabel => 'اسم النموذج';

  @override
  String get aiSettingsApiKeySectionTitle => 'مفتاح API';

  @override
  String get aiSettingsApiKeyLabel => 'مفتاح API الخاص بك';

  @override
  String get aiSettingsApiKeyNote =>
      'يُحفظ فقط في التخزين الآمن لهذا الجهاز ولا يُرسل إلا إلى المزوّد الذي اخترته. لن يُعرض مرة أخرى بعد حفظه.';

  @override
  String get aiSettingsProviderRequired => 'اختر مزوّدًا';

  @override
  String get aiSettingsCustomBaseUrlInvalid =>
      'أدخل عنوانًا كاملًا يبدأ بـ https://';

  @override
  String get aiSettingsCustomModelRequired => 'أدخل اسم النموذج';

  @override
  String get aiSettingsApiKeyRequired => 'أدخل مفتاح API';

  @override
  String get aiSettingsApiKeyMalformed => 'لا يبدو هذا مفتاح API كاملًا';

  @override
  String get aiSettingsContinueAction => 'متابعة';

  @override
  String get aiSettingsEnabledTitle => 'المساعد يعمل';

  @override
  String aiSettingsEnabledProvider(String provider) {
    return 'المزوّد: $provider';
  }

  @override
  String get aiSettingsApiKeySaved => 'مفتاح API: محفوظ بأمان (مخفي)';

  @override
  String aiSettingsConsentAcceptedOn(String date) {
    return 'تمت الموافقة على إفصاح مشاركة البيانات في $date';
  }

  @override
  String get aiSettingsChangeCredentialsAction => 'تغيير المزوّد أو المفتاح';

  @override
  String get aiSettingsChangeCredentialsTitle => 'تغيير المزوّد أو المفتاح';

  @override
  String get aiSettingsChangeCredentialsMessage =>
      'أدخل المفتاح الجديد. سيتم التخلص من المفتاح المحفوظ حاليًا بمجرد حفظ المفتاح الجديد.';

  @override
  String get aiSettingsSaveCredentialsAction => 'حفظ المفتاح الجديد';

  @override
  String get aiSettingsCancelAction => 'إلغاء';

  @override
  String get aiSettingsDisableAction => 'إيقاف المساعد';

  @override
  String get aiSettingsDisableConfirmTitle => 'إيقاف المساعد؟';

  @override
  String get aiSettingsDisableConfirmMessage =>
      'لن يُرسل أي شيء آخر إلى مزوّد الذكاء الاصطناعي. سيُحذف مفتاح API المحفوظ من هذا الجهاز، لذا فإن إعادة تشغيل المساعد تتطلب إدخال مفتاح والموافقة على إفصاح مشاركة البيانات من جديد. سيُحتفظ بسجل المحادثة.';

  @override
  String get aiSettingsDisableConfirmAction => 'إيقاف';

  @override
  String get aiSettingsEnabledMessage => 'تم تشغيل المساعد الذكي';

  @override
  String get aiSettingsCredentialsUpdatedMessage =>
      'تم تحديث المزوّد والمفتاح. تم التخلص من المفتاح السابق.';

  @override
  String get aiSettingsDisabledMessage =>
      'تم إيقاف المساعد الذكي. حُذف مفتاح API من هذا الجهاز.';

  @override
  String get aiSettingsSaveFailed =>
      'تعذر حفظ إعدادات المساعد الذكي. لم يتغير شيء. حاول مرة أخرى.';

  @override
  String get aiSettingsLoadFailed => 'تعذر تحميل إعدادات المساعد الذكي.';

  @override
  String aiSettingsCustomProviderName(String host) {
    return 'مزوّدك المخصص ($host)';
  }

  @override
  String get aiConsentTitle => 'قبل تشغيل المساعد';

  @override
  String get aiConsentIntro =>
      'إليك بالضبط ما يحدث عندما تطرح سؤالًا على المساعد:';

  @override
  String get aiConsentPointMinimal =>
      'تُرسل فقط المعلومة الصغيرة اللازمة للإجابة عن ذلك السؤال تحديدًا — مثل إجمالي فئة واحدة لشهر واحد. لا تُرسل أبدًا نسخة كاملة من سجلاتك.';

  @override
  String aiConsentPointProviderOnly(String provider) {
    return 'تذهب فقط إلى $provider باستخدام مفتاحك أنت. لا تذهب أبدًا إلى دفتري ولا إلى أي جهة أخرى.';
  }

  @override
  String get aiConsentPointOnDemand => 'لا يُرسل أي شيء حتى تطرح سؤالًا.';

  @override
  String get aiConsentPointReadOnly =>
      'يستطيع المساعد فقط قراءة أرقامك وشرحها. لا يمكنه أبدًا إضافة أي شيء أو تعديله أو حذفه.';

  @override
  String get aiConsentPointCost => 'قد يحاسبك المزوّد على كل سؤال.';

  @override
  String get aiConsentPointDisable =>
      'يمكنك إيقاف المساعد في أي وقت. يوقف ذلك فورًا إرسال أي شيء آخر ويحذف مفتاحك من هذا الجهاز.';

  @override
  String get aiConsentAcceptAction => 'أوافق، شغّله';

  @override
  String get aiConsentDeclineAction => 'ليس الآن';

  @override
  String get aiChatTitle => 'المساعد الذكي';

  @override
  String get aiChatInputHint => 'اسأل عن مصروفاتك أو ميزانياتك أو أرصدتك…';

  @override
  String get aiChatSendAction => 'إرسال السؤال';

  @override
  String get aiChatEmptyTitle => 'اسأل عن أموالك أنت';

  @override
  String get aiChatEmptyMessage =>
      'مثلًا: \"كم صرفت على الأكل هذا الشهر؟\" الإجابات مبنية على سجلاتك في دفتري فقط.';

  @override
  String get aiChatClearAction => 'مسح المحادثة';

  @override
  String get aiChatClearConfirmTitle => 'هل تريد مسح هذه المحادثة؟';

  @override
  String get aiChatClearConfirmMessage =>
      'ستُحذف كل الأسئلة والإجابات من هذا الجهاز. لن تتأثر سجلاتك المالية.';

  @override
  String get aiChatClearConfirmAction => 'مسح';

  @override
  String get aiChatClearedMessage => 'تم مسح المحادثة';

  @override
  String get aiChatClearFailed => 'تعذّر مسح المحادثة. حاول مرة أخرى.';

  @override
  String get aiChatLoadEarlierAction => 'عرض الرسائل الأقدم';

  @override
  String get aiChatLoadFailed => 'تعذّر تحميل المحادثة.';

  @override
  String get aiChatTypingLabel => 'المساعد يجهّز الإجابة';

  @override
  String get aiChatYouLabel => 'أنت';

  @override
  String get aiChatAssistantLabel => 'المساعد';

  @override
  String get aiChatMessageFailedLabel => 'لم تتم الإجابة';

  @override
  String get aiChatInterruptedLabel =>
      'لم تتم الإجابة: أُوقف المساعد قبل وصول الرد';

  @override
  String get aiChatDisabledTitle => 'المساعد متوقف';

  @override
  String get aiChatDisabledMessage =>
      'شغّله من إعدادات المساعد لتبدأ في طرح أسئلة عن أموالك.';

  @override
  String get aiChatOpenSettingsAction => 'فتح الإعدادات';

  @override
  String get aiChatSettingsAction => 'إعدادات المساعد';

  @override
  String get aiChatReadOnlyNotice =>
      'المساعد يستطيع فقط قراءة أرقامك وشرحها، ولا يمكنه إضافة أو تعديل أو حذف أي شيء، لذلك لم يتغيّر شيء. يمكنك فعل ذلك بنفسك من داخل التطبيق.';

  @override
  String get aiChatNothingChangedLabel => 'لم يتغيّر أي شيء في سجلاتك';

  @override
  String get aiFailureInvalidApiKeyTitle => 'المفتاح غير مقبول';

  @override
  String get aiFailureInvalidApiKeyMessage =>
      'رفض المزوّد مفتاح API الخاص بك. قد يكون خاطئًا أو منتهي الصلاحية أو ملغى. حدّثه لتواصل طرح الأسئلة.';

  @override
  String get aiFailureRateLimitedTitle => 'طلبات كثيرة جدًا';

  @override
  String get aiFailureRateLimitedMessage =>
      'المزوّد يحدّ من عدد الطلبات حاليًا. انتظر دقيقة أو اثنتين ثم حاول مرة أخرى.';

  @override
  String get aiFailureNetworkTitle => 'لا يوجد اتصال بالإنترنت';

  @override
  String get aiFailureNetworkMessage =>
      'يحتاج المساعد إلى اتصال بالإنترنت. أما باقي دفتري فيعمل كالمعتاد بدون إنترنت.';

  @override
  String get aiFailureProviderErrorTitle => 'المزوّد غير متاح';

  @override
  String get aiFailureProviderErrorMessage =>
      'يواجه مزوّد الذكاء الاصطناعي مشكلة من جهته. حاول مرة أخرى بعد قليل.';

  @override
  String get aiFailureUnrecognizedTitle => 'رد غير متوقع';

  @override
  String get aiFailureUnrecognizedMessage =>
      'تعذّر فهم رد المساعد. حاول طرح السؤال مرة أخرى.';

  @override
  String get aiFailureLocalTitle => 'تعذّر الحفظ';

  @override
  String get aiFailureLocalMessage =>
      'تعذّر حفظ سؤالك على هذا الجهاز. حاول مرة أخرى.';

  @override
  String get aiFailureRetryAction => 'حاول مرة أخرى';

  @override
  String get aiFailureUpdateKeyAction => 'تحديث مفتاح API';

  @override
  String get aiObservationLabel => 'ملاحظة';

  @override
  String get aiObservationSemanticLabel => 'ملاحظة من المساعد مبنية على سجلاتك';
}
