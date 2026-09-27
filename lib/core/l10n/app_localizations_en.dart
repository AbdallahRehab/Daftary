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
  String get finEduTitle => 'Financial education';

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
  String get commonRetry => 'Try again';

  @override
  String get commonUndo => 'Undo';

  @override
  String get errorLoadTitle => 'Couldn\'t load this';

  @override
  String get errorCache =>
      'Couldn\'t read or save your data on this device. Please try again.';

  @override
  String get errorNotFound =>
      'This item no longer exists. It may have been deleted.';

  @override
  String get errorValidation =>
      'Some details aren\'t valid. Check them and try again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorSyncNetwork =>
      'No internet connection. Your data is saved on this device and will sync when you\'re back online.';

  @override
  String get errorSyncTimeout =>
      'The cloud took too long to respond. We\'ll try again shortly.';

  @override
  String get errorSyncServer =>
      'The cloud service is having trouble right now. We\'ll try again shortly.';

  @override
  String get errorSyncUnauthorized =>
      'Your cloud session has expired. Sign in again to keep syncing.';

  @override
  String get errorSyncForbidden =>
      'This change isn\'t allowed by your cloud account.';

  @override
  String get errorSyncRejected =>
      'The cloud couldn\'t accept this change. Review it and try again.';

  @override
  String get errorSyncConflict =>
      'This record was changed on another device. Choose which version to keep.';

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
  String archivePersonTooltip(String name) {
    return 'Archive $name';
  }

  @override
  String personArchivedMessage(String name) {
    return '$name archived. You can find them in Archived people.';
  }

  @override
  String get addPersonAction => 'Add person';

  @override
  String get personFormCreateTitle => 'New person';

  @override
  String get personFormEditTitle => 'Edit person';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameRequiredError => 'Enter a name';

  @override
  String get personRequiredError => 'Choose a person, or create a new one';

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
      'Someone with a similar name is already in your list. Is this the same person?';

  @override
  String get duplicateUseExisting => 'Use existing person';

  @override
  String get duplicateCreateNew => 'Create new person anyway';

  @override
  String get transactionFormCreateTitle => 'Record transaction';

  @override
  String get transactionFormEditTitle => 'Edit transaction';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountInvalidError =>
      'Enter an amount greater than zero, up to 12 digits';

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
  String get deleteTransactionConfirmMessage =>
      'It will be removed from this person\'s history and balance. This can\'t be undone.';

  @override
  String get deleteTransactionTooltip => 'Delete transaction';

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
      'Couldn\'t save your language choice. It\'s on for now but may reset when you reopen the app — try choosing it again.';

  @override
  String get themeSectionTitle => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemDefault => 'System default';

  @override
  String get themeSaveFailed =>
      'Couldn\'t save your theme choice. It\'s on for now but may reset when you reopen the app — try choosing it again.';

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
      'Lending a friend cash, splitting a gift, or covering someone at a gathering — record it with that person so nothing gets forgotten.';

  @override
  String get onboardingScanningRecordsTitle => 'Look back whenever you need to';

  @override
  String get onboardingScanningRecordsDescription =>
      'Every entry is saved with its date, so you can scan your full history with any person at any time.';

  @override
  String get onboardingIncomeExpenseTitle => 'See where your own money goes';

  @override
  String get onboardingIncomeExpenseDescription =>
      'Record your income and spending by category, and see each month\'s totals alongside what people owe you.';

  @override
  String get onboardingBackAction => 'Back';

  @override
  String get onboardingNextAction => 'Next';

  @override
  String get onboardingGetStartedAction => 'Get started';

  @override
  String get onboardingSkipAction => 'Skip';

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
  String get financeCategoryNameRequiredError => 'Enter a category name';

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

  @override
  String notificationBudgetNearLimitTitle(String category) {
    return '$category is close to its limit';
  }

  @override
  String notificationBudgetNearLimitBody(String category, String percent) {
    return 'You\'ve used $percent% of your $category budget this month.';
  }

  @override
  String notificationBudgetExceededTitle(String category) {
    return '$category is over budget';
  }

  @override
  String notificationBudgetExceededBody(String category, String percent) {
    return 'You\'ve spent $percent% of your $category budget this month.';
  }

  @override
  String notificationBudgetExceededNoPlanBody(String category) {
    return 'You\'ve spent on $category this month, but no amount was planned for it.';
  }

  @override
  String notificationSavingsBehindPaceTitle(String goal) {
    return '$goal is falling behind';
  }

  @override
  String notificationSavingsBehindPaceBody(String goal, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return 'At your current pace, you\'ll reach $goal $_temp0 later than planned.';
  }

  @override
  String notificationSavingsAheadOfPaceTitle(String goal) {
    return '$goal is ahead of schedule';
  }

  @override
  String notificationSavingsAheadOfPaceBody(String goal, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return 'Nice work — you\'re on track to reach $goal $_temp0 early.';
  }

  @override
  String notificationSavingsAchievedTitle(String goal) {
    return 'Goal reached: $goal';
  }

  @override
  String notificationSavingsAchievedBody(String goal) {
    return 'You\'ve saved the full amount for $goal. Well done!';
  }

  @override
  String get notificationSettingsTitle => 'Notifications';

  @override
  String get notificationSettingsEntrySubtitle =>
      'Budget warnings, savings check-ins and quiet hours';

  @override
  String get notificationSettingsMasterTitle => 'Budget & savings reminders';

  @override
  String get notificationSettingsMasterOffDescription =>
      'Off by default. Turn on to get a heads-up when a budget is nearly used up or a savings goal drifts from its plan. Everything is worked out on this device from your own data.';

  @override
  String get notificationSettingsMasterOnDescription =>
      'You\'ll only get a reminder when something about your budgets or goals actually changes.';

  @override
  String get notificationSettingsCategoriesHeader => 'What to notify me about';

  @override
  String get notificationBudgetWarningsTitle => 'Budget warnings';

  @override
  String get notificationBudgetWarningsSubtitle =>
      'When a category is close to or over its monthly limit';

  @override
  String get notificationSavingsCheckInsTitle => 'Savings goal check-ins';

  @override
  String get notificationSavingsCheckInsSubtitle =>
      'When a goal falls behind or gets ahead of its plan, or is reached';

  @override
  String get notificationQuietHoursTitle => 'Quiet hours';

  @override
  String get notificationQuietHoursSubtitle =>
      'Hold notifications during these hours and deliver them afterwards';

  @override
  String get notificationQuietHoursFrom => 'From';

  @override
  String get notificationQuietHoursTo => 'To';

  @override
  String get notificationQuietHoursNextDay => 'next day';

  @override
  String get notificationPermissionRationaleTitle => 'Allow notifications?';

  @override
  String get notificationPermissionRationaleMessage =>
      'Daftary needs your permission to show these reminders. They\'re only about your own budgets and savings goals, and nothing leaves your device.';

  @override
  String get notificationPermissionRationaleConfirm => 'Continue';

  @override
  String get notificationPermissionDeniedTitle => 'Notifications are blocked';

  @override
  String get notificationPermissionDeniedMessage =>
      'Your device isn\'t letting Daftary show notifications, so nothing will be delivered even though reminders are on. Allow notifications in your device settings to start receiving them.';

  @override
  String get notificationPermissionDeniedAction => 'Open device settings';

  @override
  String get notificationSettingsSaveFailed =>
      'Couldn\'t save your notification settings. Please try again.';

  @override
  String get notificationSettingsLoadFailed =>
      'Couldn\'t load your notification settings.';

  @override
  String get notificationBudgetNoLongerExists =>
      'That budget no longer exists.';

  @override
  String get notificationSavingsGoalNoLongerExists =>
      'That savings goal no longer exists.';

  @override
  String get currencyFieldLabel => 'Currency';

  @override
  String get rateNeededTitle => 'Total unavailable — exchange rate needed';

  @override
  String rateNeededMessage(String currencies) {
    return 'Add an exchange rate for $currencies to see this total. Your records are safe and unchanged.';
  }

  @override
  String get rateNeededAction => 'Set exchange rate';

  @override
  String get currencySettingsTitle => 'Currency';

  @override
  String get currencySettingsEntrySubtitle =>
      'Primary currency and exchange rates';

  @override
  String get primaryCurrencyLabel => 'Primary currency';

  @override
  String get primaryCurrencyDescription =>
      'All totals and balances are shown in this currency.';

  @override
  String get primaryCurrencyChange => 'Change';

  @override
  String get primaryCurrencyChanged => 'Primary currency updated';

  @override
  String get primaryCurrencySwitchRateTitle => 'Exchange rate needed';

  @override
  String primaryCurrencySwitchRateMessage(String previous, String next) {
    return 'You have records in $previous. Enter how many $next one $previous is worth so your totals stay correct.';
  }

  @override
  String get exchangeRatesTitle => 'Exchange rates';

  @override
  String get exchangeRatesManualDisclosure =>
      'Rates are entered by you and never fetched automatically. Update them whenever you like.';

  @override
  String get exchangeRatesEmpty => 'No exchange rates yet';

  @override
  String get exchangeRateAdd => 'Add rate';

  @override
  String get exchangeRateEditTitle => 'Exchange rate';

  @override
  String exchangeRateValueLabel(String from, String to) {
    return 'Value of 1 $from in $to';
  }

  @override
  String exchangeRateLastUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get exchangeRateInvalid => 'Enter a rate greater than zero';

  @override
  String get exchangeRateSave => 'Save';

  @override
  String get exchangeRateRemove => 'Remove rate';

  @override
  String get exchangeRateRemoveConfirm =>
      'Totals that need this rate will be unavailable until you add it again. Your records won\'t change.';

  @override
  String get exchangeRateSaveFailed =>
      'Couldn\'t save the exchange rate. Please try again.';

  @override
  String get currencySettingsLoadFailed =>
      'Couldn\'t load your currency settings.';

  @override
  String get primaryCurrencyChangeFailed =>
      'Couldn\'t change the primary currency. Please try again.';

  @override
  String get splashTagline => 'Every give and take, in one ledger';

  @override
  String get splashErrorMessage =>
      'Daftary couldn\'t finish opening. Please try again.';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get liquidGlassTitle => 'Liquid Glass';

  @override
  String get liquidGlassSubtitle => 'Frosted glass effect on bars and buttons';

  @override
  String get glassSaveFailed =>
      'Couldn\'t save your glass setting. It will apply until you close the app.';

  @override
  String get glassTransparencyTitle => 'Glass transparency';

  @override
  String get glassIntensityTitle => 'Glass intensity';

  @override
  String get glassLevelLow => 'Low';

  @override
  String get glassLevelMedium => 'Medium';

  @override
  String get glassLevelHigh => 'High';

  @override
  String get glassPreviewTitle => 'Preview';

  @override
  String get glassPreviewSemantics =>
      'Sample of the Liquid Glass effect with your current settings';

  @override
  String get syncConflictBadgeLabel => 'Conflict';

  @override
  String get syncConflictBadgeSemantics =>
      'Changed on another device. Choose which version to keep.';

  @override
  String get syncConflictSheetTitle => 'Changed on two devices';

  @override
  String get syncConflictSheetMessage =>
      'This record was edited on this device and on another one. Choose the version to keep. The other version is saved in the history.';

  @override
  String get syncConflictMineLabel => 'This device';

  @override
  String get syncConflictTheirsLabel => 'Other device';

  @override
  String get syncConflictKeepMine => 'Keep mine';

  @override
  String get syncConflictKeepTheirs => 'Keep theirs';

  @override
  String get syncConflictDeletedLabel => 'Deleted';

  @override
  String get syncConflictResolveFailed =>
      'Couldn\'t resolve the conflict. Try again.';

  @override
  String get syncSettingsTitle => 'Cloud backup & sync';

  @override
  String get syncStatusUpToDate => 'Up to date';

  @override
  String syncStatusPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusOffline =>
      'Offline. Changes are saved on this device and will sync later.';

  @override
  String get syncStatusRetrying =>
      'Couldn\'t reach the cloud. Trying again soon.';

  @override
  String get syncStatusFailed => 'Some changes couldn\'t sync';

  @override
  String get syncStatusConflict => 'Some records need your review';

  @override
  String get syncStatusAuthRequired =>
      'Your cloud session has ended. Sync will resume once you sign in again.';

  @override
  String get syncStatusOff => 'Sync is off. Your data stays on this device.';

  @override
  String get syncStatusUnavailable =>
      'Cloud backup isn\'t available in this version.';

  @override
  String get syncStatusUnreadable => 'Some cloud data couldn\'t be read';

  @override
  String get syncProblemUnreadableMessage =>
      'Some data from your other devices couldn\'t be read by this version of the app. Nothing was lost. Update the app and syncing will continue.';

  @override
  String syncLastSynced(String dateTime) {
    return 'Last synced $dateTime';
  }

  @override
  String get syncNeverSynced => 'Not synced yet';

  @override
  String get syncCountPending => 'Waiting';

  @override
  String get syncCountFailed => 'Failed';

  @override
  String get syncCountConflicts => 'Conflicts';

  @override
  String get syncNowButton => 'Sync now';

  @override
  String get syncEnabledTitle => 'Back up and sync';

  @override
  String get syncEnabledSubtitle =>
      'Keep a copy of your data in the cloud and on your other phones.';

  @override
  String get syncAccountSectionTitle => 'Account';

  @override
  String get syncLinkEmailTitle => 'Link email';

  @override
  String get syncLinkEmailSubtitle =>
      'Use your email to restore your data on a new phone.';

  @override
  String get syncSignInTitle => 'Sign in to existing account';

  @override
  String get syncSignInSubtitle =>
      'Use the data already backed up with your email.';

  @override
  String syncLinkedAs(String email) {
    return 'Linked to $email';
  }

  @override
  String get syncConflictsSectionTitle => 'Needs your review';

  @override
  String syncConflictItemSubtitle(String date) {
    return 'Changed on two devices · $date';
  }

  @override
  String get syncFailedSectionTitle => 'Couldn\'t sync';

  @override
  String get syncRetryButton => 'Retry';

  @override
  String get syncKindPerson => 'Person';

  @override
  String get syncKindTransaction => 'Transaction';

  @override
  String get syncKindTransactionHistory => 'Transaction history';

  @override
  String get syncKindFinanceCategory => 'Category';

  @override
  String get syncKindFinanceEntry => 'Finance entry';

  @override
  String get syncKindExchangeRate => 'Exchange rate';

  @override
  String get syncKindPrimaryCurrency => 'Primary currency';

  @override
  String get syncKindConflictResolution => 'Conflict choice';

  @override
  String get syncFailedReasonPersonHasTransactions =>
      'This person has transactions on another device.';

  @override
  String get syncFailedReasonCategoryTypeMismatch =>
      'This category\'s type doesn\'t match its entries.';

  @override
  String get syncFailedReasonInvalid =>
      'The cloud couldn\'t accept this change.';

  @override
  String get syncFailedReasonOther => 'This change couldn\'t be sent.';

  @override
  String get syncEmailLinkTitle => 'Link your email';

  @override
  String get syncEmailSignInTitle => 'Sign in with email';

  @override
  String get syncEmailLinkMessage =>
      'We\'ll send a code to your email. Your data stays as it is.';

  @override
  String get syncEmailSignInMessage =>
      'We\'ll send a code to your email. The data on this phone will be added to that account.';

  @override
  String get syncEmailFieldLabel => 'Email';

  @override
  String get syncEmailSendCode => 'Send code';

  @override
  String syncEmailCodeSent(String email) {
    return 'We sent a code to $email.';
  }

  @override
  String get syncEmailCodeFieldLabel => 'Code';

  @override
  String get syncEmailConfirm => 'Confirm';

  @override
  String get syncEmailLinkSuccess => 'Email linked';

  @override
  String get syncEmailSignInSuccess => 'Signed in. Your data will sync now.';

  @override
  String get syncEmailErrorInvalidCode => 'That code is wrong or has expired.';

  @override
  String get syncEmailErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get syncEmailErrorEmailInUse =>
      'This email already has an account. Use \"Sign in to existing account\" instead.';

  @override
  String get syncEmailErrorAccountNotFound => 'No account uses this email.';

  @override
  String get syncEmailErrorRateLimited =>
      'Too many attempts. Wait a minute and try again.';

  @override
  String get syncNoticeTitle => 'Your data can now be backed up';

  @override
  String get syncNoticeMessage =>
      'Daftary now keeps a private copy of your records in the cloud, so you can restore them on a new phone. You can turn this off anytime in Settings.';

  @override
  String get syncNoticeOpenSettings => 'Sync settings';

  @override
  String get syncNoticeDismiss => 'Got it';
}
