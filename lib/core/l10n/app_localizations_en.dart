// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get finEduCalcCompoundTitle => 'Compound growth calculator';

  @override
  String get finEduCalcCompoundIntro =>
      'See how a fixed monthly amount could grow over time at a rate you choose, compounded monthly.';

  @override
  String get finEduCalcDoublingTitle => 'Doubling time calculator';

  @override
  String get finEduCalcDoublingIntro =>
      'Estimate roughly how many years it takes for money to double at a constant annual rate you choose.';

  @override
  String get finEduCalcSavingsRateTitle => 'Savings rate calculator';

  @override
  String get finEduCalcSavingsRateIntro =>
      'Work out what share of an income is set aside, using figures you enter yourself.';

  @override
  String get finEduCalcMonthlyContributionLabel => 'Monthly amount (EGP)';

  @override
  String get finEduCalcAnnualRateLabel => 'Annual growth rate (%)';

  @override
  String get finEduCalcYearsLabel => 'Duration (years)';

  @override
  String get finEduCalcIncomeLabel => 'Income (EGP)';

  @override
  String get finEduCalcSavingsAmountLabel => 'Amount saved (EGP)';

  @override
  String get finEduCalcCalculate => 'Calculate';

  @override
  String get finEduCalcPrefillFromSavingsGoal =>
      'Start from my savings goal\'s amount';

  @override
  String get finEduCalcPrefillHint =>
      'Only fills in the amount as a starting point — you can change it freely.';

  @override
  String get finEduCalcErrorRequired => 'Enter a value';

  @override
  String get finEduCalcErrorInvalidNumber => 'Enter a valid number';

  @override
  String get finEduCalcErrorWholeYears => 'Enter a whole number of years';

  @override
  String get finEduCalcErrorAmountPositive =>
      'Enter an amount greater than zero';

  @override
  String get finEduCalcErrorRateNegative => 'The rate can\'t be negative';

  @override
  String get finEduCalcErrorRatePositive =>
      'Enter a rate greater than zero — a doubling time isn\'t defined at 0%';

  @override
  String get finEduCalcErrorYearsPositive =>
      'Enter a duration of at least 1 year';

  @override
  String get finEduCalcErrorIncomePositive =>
      'Enter an income greater than zero';

  @override
  String get finEduCalcErrorSavingsNegative =>
      'The amount saved can\'t be negative';

  @override
  String get finEduCalcErrorResultTooLarge =>
      'These inputs produce a figure too large to show. Try a smaller amount, rate, or duration.';

  @override
  String get finEduCalcResultTitle => 'Result';

  @override
  String get finEduCalcResultFutureValue => 'Projected total';

  @override
  String get finEduCalcResultTotalContributed => 'Total contributed';

  @override
  String get finEduCalcResultTotalGrowth => 'Total growth';

  @override
  String get finEduCalcResultDoublingYears => 'Approximate doubling time';

  @override
  String get finEduCalcResultSavingsRate => 'Savings rate';

  @override
  String finEduCalcYearsValue(String years) {
    return '$years years';
  }

  @override
  String finEduCalcPercentValue(String percent) {
    return '$percent%';
  }

  @override
  String get finEduCalcIllustrativeNote =>
      'Illustrative only — assumes a constant rate; real returns vary and are not guaranteed';

  @override
  String get finEduCalcHighRateNote =>
      'This rate is unusually high. The result is purely illustrative — sustained returns this high are rare.';

  @override
  String get finEduCalcRuleOf72Note =>
      'An approximation using the rule of 72 (72 ÷ annual rate), not an exact figure.';

  @override
  String get finEduCalcSavingsAboveIncomeNote =>
      'The amount saved is higher than the income entered, so the rate is above 100%.';

  @override
  String get finEduCalcSavingsRateNote =>
      'Calculated only from the two figures you entered.';

  @override
  String get finEduTitle => 'Financial Education';

  @override
  String get finEduSettingsSectionTitle => 'Learn';

  @override
  String get finEduSettingsEntrySubtitle =>
      'Articles and illustrative calculators';

  @override
  String get finEduDisclaimer =>
      'For general educational purposes only. This is not personalized financial or investment advice.';

  @override
  String get finEduTopicsSectionTitle => 'Topics';

  @override
  String get finEduToolsSectionTitle => 'Calculators';

  @override
  String get finEduCompoundGrowthTileTitle => 'Compound growth';

  @override
  String get finEduCompoundGrowthTileSubtitle =>
      'See how a regular monthly amount could grow over time';

  @override
  String get finEduDoublingTimeTileTitle => 'Doubling time';

  @override
  String get finEduDoublingTimeTileSubtitle =>
      'Estimate how long money takes to double with the rule of 72';

  @override
  String get finEduSavingsRateTileTitle => 'Savings rate';

  @override
  String get finEduSavingsRateTileSubtitle =>
      'Work out what share of income is being saved';

  @override
  String get finEduLoadErrorTitle => 'Couldn\'t load this content';

  @override
  String get finEduLoadErrorMessage =>
      'Something went wrong while opening the bundled content. Please try again.';

  @override
  String get finEduRetry => 'Try again';

  @override
  String get finEduEmptyCategoryTitle => 'No articles yet';

  @override
  String get finEduEmptyCategoryMessage =>
      'Articles for this topic will appear here.';

  @override
  String get appTitle => 'Daftary';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonArchive => 'Archive';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonOk => 'OK';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get errorCache => 'A local storage error occurred. Please try again.';

  @override
  String get errorNotFound => 'This item could not be found.';

  @override
  String get errorValidation => 'Please check your input and try again.';

  @override
  String get errorUnknown => 'An unexpected error occurred. Please try again.';

  @override
  String get peopleListTitle => 'People';

  @override
  String get searchPeopleHint => 'Search people';

  @override
  String get filterAll => 'All';

  @override
  String get filterTheyOweYou => 'They owe you';

  @override
  String get filterYouOweThem => 'You owe them';

  @override
  String get filterSettled => 'Settled';

  @override
  String get emptyPeopleTitle => 'No people yet';

  @override
  String get emptyPeopleMessage =>
      'Add a person to start tracking money you give or receive with them.';

  @override
  String get archivedPeopleAction => 'Archived people';

  @override
  String get addPersonAction => 'Add person';

  @override
  String get personFormCreateTitle => 'New person';

  @override
  String get personFormEditTitle => 'Edit person';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameRequiredError => 'Name is required';

  @override
  String get phoneLabel => 'Phone number (optional)';

  @override
  String get relationshipTagLabel => 'Relationship (optional)';

  @override
  String get notesLabel => 'Notes (optional)';

  @override
  String get deletePersonAction => 'Delete person';

  @override
  String get deleteBlockedTitle => 'Can\'t delete this person';

  @override
  String get deleteBlockedMessage =>
      'This person has recorded transactions. Archive them instead to keep their history.';

  @override
  String get archiveInsteadAction => 'Archive instead';

  @override
  String get relationshipFamily => 'Family';

  @override
  String get relationshipFriend => 'Friend';

  @override
  String get relationshipColleague => 'Colleague';

  @override
  String get relationshipCustomer => 'Customer';

  @override
  String get relationshipSupplier => 'Supplier';

  @override
  String get relationshipOther => 'Other';

  @override
  String get duplicateWarningTitle => 'Possible duplicate';

  @override
  String get duplicateWarningMessage =>
      'This name looks similar to someone you already know.';

  @override
  String get duplicateUseExisting => 'Use existing person';

  @override
  String get duplicateCreateNew => 'Create new person anyway';

  @override
  String get transactionFormCreateTitle => 'Record transaction';

  @override
  String get transactionFormEditTitle => 'Edit transaction';

  @override
  String get amountLabel => 'Amount (EGP)';

  @override
  String get amountInvalidError => 'Enter a valid amount greater than zero';

  @override
  String get directionGiven => 'I gave';

  @override
  String get directionReceived => 'I received';

  @override
  String get dateLabel => 'Date';

  @override
  String get noteLabel => 'Note (optional)';

  @override
  String get personLabel => 'Person';

  @override
  String get createPersonInlineAction => 'Create new person';

  @override
  String get savedConfirmation => 'Saved';

  @override
  String get editedLabel => 'Edited';

  @override
  String get repaymentLabel => 'Repayment';

  @override
  String get repaymentFormTitle => 'Record repayment';

  @override
  String get recordRepaymentAction => 'Record repayment';

  @override
  String personDetailTheyOweYou(String name, String amount) {
    return '$name owes you $amount';
  }

  @override
  String personDetailYouOweThem(String name, String amount) {
    return 'You owe $name $amount';
  }

  @override
  String get personDetailSettled => 'Settled';

  @override
  String get historyEmptyTitle => 'No transactions yet';

  @override
  String historyEmptyMessage(String name) {
    return 'Record a transaction with $name to start tracking your balance.';
  }

  @override
  String get recordTransactionAction => 'Record transaction';

  @override
  String get deleteTransactionConfirmTitle => 'Delete this transaction?';

  @override
  String get deleteTransactionConfirmMessage => 'This action cannot be undone.';

  @override
  String get overviewTitle => 'Overview';

  @override
  String get overviewTotalOwedToYou => 'Total owed to you';

  @override
  String get overviewTotalYouOwe => 'Total you owe';

  @override
  String get overviewSectionTheyOweYou => 'They owe you';

  @override
  String get overviewSectionYouOweThem => 'You owe them';

  @override
  String get overviewAllSettledTitle => 'Everything is settled';

  @override
  String get overviewAllSettledMessage =>
      'You have no outstanding balances with anyone right now.';

  @override
  String get archivedLabel => 'Archived';

  @override
  String get archivedPeopleTitle => 'Archived people';

  @override
  String get archivedEmptyTitle => 'No archived people';

  @override
  String get archivedEmptyMessage =>
      'People you archive will appear here, with their history intact.';

  @override
  String get restoreAction => 'Restore';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get settingsSaveFailed =>
      'Couldn\'t save your language choice. It\'s still active for this session — we\'ll keep trying.';

  @override
  String get themeSectionTitle => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemDefault => 'System Default';

  @override
  String get themeSaveFailed =>
      'Couldn\'t save your theme choice. It\'s still active for this session — we\'ll keep trying.';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingUnderstandingMoneyTitle =>
      'Understand your money at a glance';

  @override
  String get onboardingUnderstandingMoneyDescription =>
      'See who owes you, who you owe, and how things stand overall — all in one place.';

  @override
  String get onboardingMoneyBetweenPeopleTitle =>
      'Track money between you and people';

  @override
  String get onboardingMoneyBetweenPeopleDescription =>
      'Add someone, record what you gave or received, and Daftary keeps the running total for you.';

  @override
  String get onboardingSocialOccasionsTitle => 'Keep social exchanges straight';

  @override
  String get onboardingSocialOccasionsDescription =>
      'Lending a friend cash, splitting a gift, or covering someone at a gathering — jot it down so nothing gets forgotten.';

  @override
  String get onboardingScanningRecordsTitle => 'Look back whenever you need to';

  @override
  String get onboardingScanningRecordsDescription =>
      'Every entry is saved with its date, so you can scan your full history with any person at any time.';

  @override
  String get onboardingAiAssistantTitle => 'Get help making sense of it all';

  @override
  String get onboardingAiAssistantDescription =>
      'An AI assistant can help you review and organize what you\'ve recorded — it does not give financial advice or guarantee outcomes.';

  @override
  String get onboardingBackAction => 'Back';

  @override
  String get onboardingNextAction => 'Next';

  @override
  String get onboardingGetStartedAction => 'Get Started';

  @override
  String get onboardingSkipAction => 'Skip';

  @override
  String get financeTitle => 'Income & expenses';

  @override
  String get financeOverviewCardTitle => 'This month';

  @override
  String get financeAddExpenseAction => 'Add expense';

  @override
  String get financeAddIncomeAction => 'Add income';

  @override
  String get financeAddFirstEntryAction => 'Add your first entry';

  @override
  String get financeViewAllAction => 'View all';

  @override
  String get financeEntryFormExpenseTitle => 'Add expense';

  @override
  String get financeEntryFormIncomeTitle => 'Add income';

  @override
  String get financeEntryFormEditTitle => 'Edit entry';

  @override
  String get financeTypeExpense => 'Expense';

  @override
  String get financeTypeIncome => 'Income';

  @override
  String get financeCategoryLabel => 'Category';

  @override
  String get financeCategoryRequiredError => 'Choose a category';

  @override
  String get financeManageCategoriesAction => 'Manage categories';

  @override
  String get financeNoCategoriesTitle => 'No categories yet';

  @override
  String get financeNoCategoriesMessage =>
      'Create a category to start recording entries.';

  @override
  String get financeCategoryManagementTitle => 'Categories';

  @override
  String get financeCategoryFormCreateTitle => 'New category';

  @override
  String get financeCategoryFormEditTitle => 'Edit category';

  @override
  String get financeCategoryNameLabel => 'Category name';

  @override
  String get financeCategoryNameRequiredError => 'Category name is required';

  @override
  String get financeCategoryIconLabel => 'Icon';

  @override
  String get financeCategoryIconRequiredError => 'Choose an icon';

  @override
  String get financeCategoryTypeLabel => 'Type';

  @override
  String financeCategoryDuplicateError(String name) {
    return 'You already have a category named \"$name\".';
  }

  @override
  String get financeCategorySectionActive => 'Active';

  @override
  String get financeCategorySectionArchived => 'Archived';

  @override
  String get financeAddCategoryAction => 'Add category';

  @override
  String get financeRemoveCategoryAction => 'Remove category';

  @override
  String get financeRemoveCategoryConfirmTitle => 'Remove this category?';

  @override
  String get financeRemoveCategoryConfirmMessage =>
      'If any entries use this category, it will be archived so their history stays intact. Otherwise it will be deleted.';

  @override
  String get financeCategoryArchivedNotice =>
      'Archived — hidden from new entries, kept for existing ones.';

  @override
  String get financePeriodThisMonth => 'This month';

  @override
  String get financePeriodLastMonth => 'Last month';

  @override
  String get financePeriodCustom => 'Custom range';

  @override
  String get financePeriodStartLabel => 'From';

  @override
  String get financePeriodEndLabel => 'To';

  @override
  String get financeSummaryTotalIncome => 'Total income';

  @override
  String get financeSummaryTotalExpense => 'Total expenses';

  @override
  String get financeSummaryNet => 'Net';

  @override
  String get financeBreakdownTitle => 'By category';

  @override
  String financeBreakdownShare(String percent) {
    return '$percent% of total';
  }

  @override
  String get financeHistoryTitle => 'History';

  @override
  String get financeFilterTypeLabel => 'Type';

  @override
  String get financeFilterCategoryLabel => 'Category';

  @override
  String get financeClearFiltersAction => 'Clear filters';

  @override
  String get financeEmptyTitle => 'No entries yet';

  @override
  String get financeEmptyMessage =>
      'Record your income and spending to see where your money goes.';

  @override
  String get financeNoMatchTitle => 'No matching entries';

  @override
  String get financeNoMatchMessage =>
      'No entries match the filters you picked. Try a different period or category.';

  @override
  String get financeDeleteEntryConfirmTitle => 'Delete this entry?';

  @override
  String get financeDeleteEntryConfirmMessage =>
      'Your totals will update right away. You can undo this for a few seconds.';

  @override
  String get financeEntryDeletedMessage => 'Entry deleted';

  @override
  String get financeUndoAction => 'Undo';

  @override
  String get financeCategoryRent => 'Rent';

  @override
  String get financeCategoryElectricity => 'Electricity';

  @override
  String get financeCategoryWater => 'Water';

  @override
  String get financeCategoryInternet => 'Internet';

  @override
  String get financeCategoryPhone => 'Phone';

  @override
  String get financeCategoryGroceries => 'Groceries';

  @override
  String get financeCategoryTransportation => 'Transportation';

  @override
  String get financeCategoryFuel => 'Fuel';

  @override
  String get financeCategoryMedical => 'Medical';

  @override
  String get financeCategoryEducation => 'Education';

  @override
  String get financeCategoryEntertainment => 'Entertainment';

  @override
  String get financeCategoryShopping => 'Shopping';

  @override
  String get financeCategoryRestaurants => 'Restaurants';

  @override
  String get financeCategorySubscriptions => 'Subscriptions';

  @override
  String get financeCategoryFamily => 'Family';

  @override
  String get financeCategoryOther => 'Other';

  @override
  String get financeCategorySalary => 'Salary';

  @override
  String get financeCategoryFreelance => 'Freelance';

  @override
  String get financeCategoryBusiness => 'Business';

  @override
  String get financeCategoryBonus => 'Bonus';

  @override
  String get financeCategoryGift => 'Gift';

  @override
  String get financeCategoryOtherIncome => 'Other income';
}
