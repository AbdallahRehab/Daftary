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
  String get syncKindOccasion => 'Occasion';

  @override
  String get syncKindBudget => 'Budget';

  @override
  String get syncKindBudgetAllocation => 'Budget category';

  @override
  String get syncKindSavingsGoal => 'Savings goal';

  @override
  String get syncKindSavingsContribution => 'Savings entry';

  @override
  String get syncKindSavingsContributionHistory => 'Savings entry history';

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

  @override
  String get appLockLockTitle => 'Daftary is locked';

  @override
  String get appLockLockPrompt => 'Enter your PIN to continue';

  @override
  String get appLockLockBiometricReason =>
      'Unlock Daftary to see your finances';

  @override
  String get appLockLockUseBiometric => 'Unlock with biometrics';

  @override
  String get appLockLockBiometricInProgress =>
      'Waiting for biometric confirmation. You can also enter your PIN.';

  @override
  String get appLockLockVerifying => 'Checking your PIN…';

  @override
  String get appLockLockIncorrectPin => 'Incorrect PIN. Please try again.';

  @override
  String get appLockLockBiometricFailed =>
      'Biometric unlock didn\'t work. Try again or enter your PIN.';

  @override
  String get appLockLockBiometricUnavailable =>
      'Biometric unlock isn\'t available on this device right now. Enter your PIN instead.';

  @override
  String get appLockLockUnexpectedError =>
      'Something went wrong. Please try again.';

  @override
  String get appLockLockCooldownTitle => 'Too many incorrect attempts';

  @override
  String appLockLockCooldownMessage(String time) {
    return 'PIN entry is paused. Try again in $time.';
  }

  @override
  String get appLockLockCooldownBiometricHint =>
      'You can still unlock with biometrics.';

  @override
  String get appLockPinPadDelete => 'Delete last digit';

  @override
  String get appLockPinPadSubmit => 'Confirm PIN';

  @override
  String appLockPinPadDigitsEntered(int count) {
    return 'PIN digits entered: $count';
  }

  @override
  String get appLockPinSetupTitle => 'Set a PIN';

  @override
  String get appLockPinChangeTitle => 'Change PIN';

  @override
  String get appLockPinResetTitle => 'Set a new PIN';

  @override
  String get appLockPinVerifyCurrentPrompt => 'Enter your current PIN';

  @override
  String get appLockPinVerifyCurrentHint =>
      'To change your PIN, first confirm it\'s you.';

  @override
  String get appLockPinEnterNewPrompt => 'Choose a PIN';

  @override
  String get appLockPinEnterNewHint =>
      'Use 4 to 6 digits. Your PIN never leaves this device.';

  @override
  String get appLockPinConfirmNewPrompt => 'Enter the same PIN again';

  @override
  String get appLockPinConfirmNewHint =>
      'This makes sure you typed the PIN you meant.';

  @override
  String get appLockPinMismatch =>
      'The PINs don\'t match. Enter the confirmation again.';

  @override
  String get appLockPinInvalid => 'Your PIN must be 4 to 6 digits.';

  @override
  String get appLockPinIncorrectCurrent =>
      'That\'s not your current PIN. Please try again.';

  @override
  String get appLockPinBiometricFailed =>
      'Biometric check didn\'t work. Try again or enter your current PIN.';

  @override
  String get appLockPinBiometricUnavailable =>
      'Biometrics aren\'t available right now. Enter your current PIN instead.';

  @override
  String get appLockPinUnexpectedError =>
      'Couldn\'t save your PIN. Please try again.';

  @override
  String get appLockPinStartOver => 'Start over';

  @override
  String get appLockPinUseBiometric => 'Use biometrics instead';

  @override
  String get appLockPinBiometricReason =>
      'Confirm it\'s you to change your PIN';

  @override
  String get appLockPinSaving => 'Saving your PIN…';

  @override
  String get budgetMonthNavPrevious => 'Previous month';

  @override
  String get budgetMonthNavNext => 'Next month';

  @override
  String budgetMonthNavCurrentLabel(String month) {
    return 'Budget month: $month';
  }

  @override
  String budgetCopyFromMonthAction(String month) {
    return 'Copy $month\'s budget';
  }

  @override
  String budgetCopyFromMonthMessage(String month) {
    return 'Start from the plan you made for $month. You can adjust it afterwards without changing $month.';
  }

  @override
  String get budgetCopyInProgress => 'Copying…';

  @override
  String budgetCopySuccess(String month) {
    return 'Budget copied from $month';
  }

  @override
  String get budgetCopyFailed => 'Couldn\'t copy the budget. Please try again.';

  @override
  String get budgetCopyAlreadyExists => 'This month already has a budget.';

  @override
  String get budgetTrendTitle => 'Spending trends';

  @override
  String get budgetTrendSubtitle => 'Planned vs. actual, last 6 months';

  @override
  String get budgetTrendOverall => 'Overall';

  @override
  String get budgetTrendCategoryLabel => 'Category';

  @override
  String get budgetTrendPlanned => 'Planned';

  @override
  String get budgetTrendActual => 'Actual';

  @override
  String get budgetTrendOverPlan => 'Over plan';

  @override
  String get budgetTrendNoBudget => 'No budget';

  @override
  String get budgetTrendInsufficientTitle => 'Not enough history yet';

  @override
  String get budgetTrendInsufficientMessage =>
      'Trends need a budget in at least 2 months. Keep budgeting and check back next month.';

  @override
  String budgetTrendMonthSummary(String month, String planned, String actual) {
    return '$month: planned $planned, actual $actual';
  }

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonOk => 'OK';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get onboardingAiAssistantTitle => 'Get help making sense of it all';

  @override
  String get onboardingAiAssistantDescription =>
      'An AI assistant can help you review and organize what you\'ve recorded — it does not give financial advice or guarantee outcomes.';

  @override
  String get financeTitle => 'Income & expenses';

  @override
  String get financeUndoAction => 'Undo';

  @override
  String get occasionsTitle => 'Occasions';

  @override
  String get occasionsEmptyTitle => 'No occasions yet';

  @override
  String get occasionsEmptyMessage =>
      'Weddings, engagements, birthdays, sebou celebrations, condolences — create an occasion to record who gave or received money at it.';

  @override
  String get occasionAddAction => 'New occasion';

  @override
  String get occasionAddFirstAction => 'Create your first occasion';

  @override
  String get occasionSearchHint => 'Search occasions';

  @override
  String get occasionFilterTypeLabel => 'Type';

  @override
  String get occasionFilterAllTypes => 'All types';

  @override
  String get occasionFilterDateRangeLabel => 'Date range';

  @override
  String get occasionFilterDateFromLabel => 'From';

  @override
  String get occasionFilterDateToLabel => 'To';

  @override
  String get occasionFilterAllDates => 'Any date';

  @override
  String get occasionClearFiltersAction => 'Clear filters';

  @override
  String get occasionNoMatchTitle => 'No matching occasions';

  @override
  String get occasionNoMatchMessage =>
      'No occasions match your search or filters. Try a different name, type, or date range.';

  @override
  String get occasionArchivedAction => 'Archived occasions';

  @override
  String get occasionArchivedTitle => 'Archived occasions';

  @override
  String get occasionArchivedEmptyTitle => 'No archived occasions';

  @override
  String get occasionArchivedEmptyMessage =>
      'Occasions you archive will appear here, with their contributions and balances intact.';

  @override
  String get occasionArchivedLabel => 'Archived';

  @override
  String get occasionUpcomingLabel => 'Upcoming';

  @override
  String get occasionTypeWedding => 'Wedding';

  @override
  String get occasionTypeEngagement => 'Engagement';

  @override
  String get occasionTypeBirthday => 'Birthday';

  @override
  String get occasionTypeNewbornSebou => 'Newborn (Sebou)';

  @override
  String get occasionTypeCondolence => 'Condolence';

  @override
  String get occasionTypeCelebration => 'Celebration';

  @override
  String get occasionTypeOther => 'Other';

  @override
  String get occasionTypeCustomLabel => 'Custom type';

  @override
  String get occasionTypeCustomHint => 'Write your own type, e.g. graduation';

  @override
  String get occasionFormCreateTitle => 'New occasion';

  @override
  String get occasionFormEditTitle => 'Edit occasion';

  @override
  String get occasionNameLabel => 'Occasion name';

  @override
  String get occasionNameHint => 'e.g. Ahmed\'s wedding';

  @override
  String get occasionNameRequiredError => 'Occasion name is required';

  @override
  String get occasionDateLabel => 'Date';

  @override
  String get occasionTypeLabel => 'Type';

  @override
  String get occasionTypeRequiredError => 'Choose an occasion type';

  @override
  String get occasionNotesLabel => 'Notes (optional)';

  @override
  String get occasionCreateAction => 'Create occasion';

  @override
  String get occasionUpdateAction => 'Save changes';

  @override
  String get occasionEditAction => 'Edit occasion';

  @override
  String get occasionDeleteAction => 'Delete occasion';

  @override
  String get occasionArchiveAction => 'Archive occasion';

  @override
  String get occasionRestoreAction => 'Restore occasion';

  @override
  String get occasionParticipantFormAddTitle => 'Add participant';

  @override
  String get occasionParticipantFormEditTitle => 'Edit contribution';

  @override
  String get occasionParticipantPersonLabel => 'Person';

  @override
  String get occasionParticipantAmountLabel => 'Amount (EGP)';

  @override
  String get occasionParticipantAmountInvalidError =>
      'Enter a valid amount greater than zero';

  @override
  String get occasionParticipantDirectionLabel => 'Direction';

  @override
  String get occasionParticipantDirectionReceived => 'I received from them';

  @override
  String get occasionParticipantDirectionGiven => 'I gave them';

  @override
  String get occasionParticipantNoteLabel => 'Note (optional)';

  @override
  String get occasionParticipantCountsTowardBalanceLabel =>
      'Counts toward their balance';

  @override
  String get occasionParticipantCountsTowardBalanceHint =>
      'Condolence money isn\'t expected to be paid back, so it stays out of the balance by default. Turn this on to count it like any other exchange.';

  @override
  String get occasionParticipantSaveAction => 'Save participant';

  @override
  String get occasionParticipantUpdateAction => 'Save changes';

  @override
  String get occasionDetailTotalReceived => 'Total received';

  @override
  String get occasionDetailTotalGiven => 'Total given';

  @override
  String get occasionDetailNet => 'Net';

  @override
  String get occasionSettlementSettled => 'Settled';

  @override
  String occasionSettlementMoreReceived(String amount) {
    return '$amount more received than given';
  }

  @override
  String occasionSettlementMoreGiven(String amount) {
    return '$amount more given than received';
  }

  @override
  String get occasionParticipantsHeader => 'Participants';

  @override
  String get occasionParticipantsEmptyTitle => 'No participants yet';

  @override
  String get occasionParticipantsEmptyMessage =>
      'Add the first person who gave or received money at this occasion.';

  @override
  String get occasionAddParticipantAction => 'Add participant';

  @override
  String get occasionEditParticipantAction => 'Edit contribution';

  @override
  String get occasionRemoveParticipantAction => 'Remove contribution';

  @override
  String get occasionContributionBadge => 'Occasion';

  @override
  String get occasionRemoveParticipantConfirmTitle =>
      'Remove this contribution?';

  @override
  String get occasionRemoveParticipantConfirmMessage =>
      'It will also disappear from this person\'s history and balance. This can\'t be undone.';

  @override
  String get occasionDeleteConfirmTitle => 'Delete this occasion?';

  @override
  String occasionDeleteConfirmMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This also removes $count contributions and updates the balance of everyone who took part. This can\'t be undone.',
      one:
          'This also removes 1 contribution and updates that person\'s balance. This can\'t be undone.',
      zero:
          'This occasion has no contributions recorded yet. This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get occasionArchiveConfirmTitle => 'Archive this occasion?';

  @override
  String get occasionArchiveConfirmMessage =>
      'It moves to archived occasions. Its contributions stay in everyone\'s history and balances, and you can restore it any time.';

  @override
  String get occasionRestoreConfirmTitle => 'Restore this occasion?';

  @override
  String get occasionRestoreConfirmMessage =>
      'It will appear in your occasions list again.';

  @override
  String get occasionAttachmentsHeader => 'Photos';

  @override
  String get occasionAttachPhotoAction => 'Attach photo';

  @override
  String get occasionAttachFromCameraAction => 'Take a photo';

  @override
  String get occasionAttachFromGalleryAction => 'Choose from gallery';

  @override
  String get occasionAttachmentsEmptyTitle => 'No photos yet';

  @override
  String get occasionAttachmentsEmptyMessage =>
      'Attach a photo of the envelope list, the invitation, or the occasion itself to keep it with this record.';

  @override
  String get occasionRemoveAttachmentAction => 'Remove photo';

  @override
  String get occasionRemoveAttachmentConfirmTitle => 'Remove this photo?';

  @override
  String get occasionRemoveAttachmentConfirmMessage =>
      'The photo will be deleted from this occasion. This can\'t be undone.';

  @override
  String get occasionCameraPermissionDeniedTitle =>
      'Camera access is turned off';

  @override
  String get occasionCameraPermissionDeniedMessage =>
      'Daftary needs your camera to take a photo for this occasion. Open your device settings and allow camera access for Daftary, or choose a photo from your gallery instead.';

  @override
  String get occasionPhotoLibraryPermissionDeniedTitle =>
      'Photo access is turned off';

  @override
  String get occasionPhotoLibraryPermissionDeniedMessage =>
      'Daftary needs access to your photos to attach one to this occasion. Open your device settings and allow photo access for Daftary, or take a new photo with the camera instead.';

  @override
  String get occasionOpenSettingsAction => 'Open settings';

  @override
  String get ocrCaptureTitle => 'Scan paper';

  @override
  String get ocrCaptureHeadline => 'Turn a paper list into entries';

  @override
  String get ocrCaptureMessage =>
      'Photograph a list of names and amounts. Everything is read on this device, and nothing is saved until you review it.';

  @override
  String get ocrCaptureTakePhoto => 'Take a photo';

  @override
  String get ocrCaptureChooseFromGallery => 'Choose from gallery';

  @override
  String get ocrCaptureUnsupportedTitle =>
      'Scanning isn\'t available on this device';

  @override
  String get ocrCaptureUnsupportedMessage =>
      'This device can\'t run on-device text recognition, so scanning a paper won\'t work here. You can still add transactions manually.';

  @override
  String get ocrCaptureEnterManually => 'Enter manually';

  @override
  String get ocrPrepTitle => 'Prepare the image';

  @override
  String get ocrPrepHint =>
      'Crop to just the list of names and amounts, then even out the lighting for the best reading.';

  @override
  String get ocrPrepCropRotate => 'Crop and rotate';

  @override
  String get ocrPrepRecrop => 'Redo the crop';

  @override
  String get ocrPrepEnhance => 'Enhance';

  @override
  String get ocrPrepEnhanceAgain => 'Enhance again';

  @override
  String get ocrPrepProcess => 'Read the paper';

  @override
  String get ocrPrepProcessingTitle => 'Reading your paper';

  @override
  String get ocrPrepProcessingMessage =>
      'Text recognition is running on this device. Nothing is uploaded anywhere.';

  @override
  String get ocrPrepCancel => 'Cancel';

  @override
  String get ocrPrepInterruptedTitle => 'That didn\'t finish';

  @override
  String get ocrPrepInterruptedMessage =>
      'Reading stopped before it finished, probably because the app was interrupted. Nothing was saved, so you can try again.';

  @override
  String get ocrPrepRetry => 'Try again';

  @override
  String get ocrPrepDefaultDirectionLabel => 'Default direction for this list';

  @override
  String get ocrPrepDefaultDirectionHint =>
      'Applied to every entry whose direction can\'t be read from the paper. You can change any entry while reviewing.';

  @override
  String get ocrPrepDirectionReceived => 'Money received';

  @override
  String get ocrPrepDirectionGiven => 'Money given';

  @override
  String get ocrFailureNoTextTitle => 'No text found';

  @override
  String get ocrFailureNoTextMessage =>
      'No readable text was found in this photo. A sharper, better lit, straight-on shot usually fixes it.';

  @override
  String get ocrFailureNoCandidatesTitle => 'No entries could be made';

  @override
  String get ocrFailureNoCandidatesMessage =>
      'Text was found, but no line looked like a name and an amount. Try cropping to just the list, or enter the entries manually.';

  @override
  String get ocrFailurePermissionTitle => 'Permission needed';

  @override
  String get ocrFailurePermissionMessage =>
      'Scanning needs access to your camera or photos to read the paper. Grant access from the app\'s settings, then try again.';

  @override
  String get ocrFailureUnsupportedTitle =>
      'Scanning isn\'t available on this device';

  @override
  String get ocrFailureUnsupportedMessage =>
      'This device can\'t run on-device text recognition. Manual entry works exactly the same way.';

  @override
  String get ocrFailureGenericTitle => 'The scan didn\'t work';

  @override
  String get ocrFailureGenericMessage =>
      'Something went wrong while reading the paper. Nothing was saved, so you can try again or enter the entries manually.';

  @override
  String get ocrFailureRetakePhoto => 'Retake the photo';

  @override
  String get ocrFailureRecrop => 'Adjust the crop and retry';

  @override
  String get ocrFailureManualEntry => 'Enter manually';

  @override
  String get ocrFailureOpenSettings => 'Open settings';

  @override
  String get ocrConfidenceLow => 'Low confidence';

  @override
  String get ocrConfidenceMedium => 'Medium confidence';

  @override
  String get ocrConfidenceHigh => 'High confidence';

  @override
  String get ocrConfidenceInferred => 'Inferred, not read';

  @override
  String get ocrReviewTitle => 'Review entries';

  @override
  String get ocrReviewBatchSectionTitle => 'Applies to the whole batch';

  @override
  String get ocrReviewBatchSectionMessage =>
      'These choices apply to every entry that does not have its own. Nothing is saved until you confirm.';

  @override
  String get ocrReviewBatchDirectionLabel => 'Default direction';

  @override
  String get ocrReviewDirectionLabel => 'Direction';

  @override
  String get ocrReviewDirectionReceived => 'Received';

  @override
  String get ocrReviewDirectionGiven => 'Given';

  @override
  String get ocrReviewDirectionRequired =>
      'Choose a direction for this entry, or set a default for the batch.';

  @override
  String get ocrReviewPersonLabel => 'Person';

  @override
  String get ocrReviewPersonRequired => 'Enter the person\'s name.';

  @override
  String get ocrReviewDuplicateWarningAction => 'Similar names already saved';

  @override
  String get ocrReviewAmountLabel => 'Amount';

  @override
  String get ocrReviewAmountRequired => 'Enter an amount greater than zero.';

  @override
  String get ocrReviewAmountInvalid =>
      'Enter a valid amount, for example 150.50';

  @override
  String get ocrReviewDateLabel => 'Date';

  @override
  String get ocrReviewNotesLabel => 'Notes';

  @override
  String get ocrReviewRawTextAction => 'Original text';

  @override
  String get ocrReviewRawTextLabel => 'Read from the page';

  @override
  String get ocrReviewEditedBadge => 'Edited';

  @override
  String get ocrReviewDiscardAction => 'Discard this entry';

  @override
  String get ocrReviewIncompleteTitle => 'Not ready to save';

  @override
  String get ocrReviewIncompleteBatchMessage =>
      'Some entries are still missing required details. Nothing was saved.';

  @override
  String get ocrReviewConfirmAction => 'Confirm and save';

  @override
  String get ocrReviewConfirmBlockedHint =>
      'Complete or discard the highlighted entries before saving.';

  @override
  String get ocrReviewNothingToConfirm =>
      'There is nothing left to save in this scan.';

  @override
  String get ocrReviewCancelAction => 'Cancel scan';

  @override
  String get ocrReviewCancelPromptTitle => 'Discard your corrections?';

  @override
  String get ocrReviewCancelPromptMessage =>
      'You have corrected some entries. Cancelling this scan discards that work and saves nothing.';

  @override
  String get ocrReviewCancelPromptConfirm => 'Discard and cancel';

  @override
  String get ocrReviewCancelPromptKeep => 'Keep reviewing';

  @override
  String get ocrReviewEmptyTitle => 'No entries left';

  @override
  String get ocrReviewEmptyMessage =>
      'You discarded every entry from this scan. Cancel the scan, or go back and photograph the page again.';

  @override
  String get ocrReviewLoadErrorTitle => 'Could not open this scan';

  @override
  String get ocrReviewLoadErrorMessage =>
      'The scan and its entries could not be loaded. Nothing was saved.';

  @override
  String get ocrReviewRetryAction => 'Try again';

  @override
  String get ocrReviewSaveErrorMessage =>
      'The entries could not be saved. Nothing was recorded, so you can try again safely.';

  @override
  String get ocrReviewOccasionLabel => 'Occasion';

  @override
  String get ocrReviewOccasionNone => 'No occasion';

  @override
  String get ocrReviewOccasionClear => 'Remove the occasion tag';

  @override
  String get ocrReviewOccasionPickerTitle => 'Tag this batch to an occasion';

  @override
  String get ocrReviewOccasionEmpty =>
      'You have no occasions yet. Create one from the Occasions screen first.';

  @override
  String get ocrHistoryTitle => 'Scan history';

  @override
  String get ocrHistoryEmptyTitle => 'No scans yet';

  @override
  String get ocrHistoryEmptyMessage =>
      'Once you scan a paper list, every scan you keep shows up here with its photo and what came of it.';

  @override
  String get ocrHistoryErrorTitle => 'Couldn\'t load your scans';

  @override
  String get ocrHistoryErrorMessage =>
      'Something went wrong while reading your scan history. Try again.';

  @override
  String get ocrHistoryStatusProcessing => 'Processing';

  @override
  String get ocrHistoryStatusNeedsReview => 'Waiting for review';

  @override
  String get ocrHistoryStatusConfirmed => 'Confirmed';

  @override
  String get ocrHistoryStatusDiscarded => 'Produced nothing';

  @override
  String get ocrHistoryStatusFailed => 'Nothing could be read';

  @override
  String ocrHistoryConfirmedEntries(Object count) {
    return '$count entries confirmed';
  }

  @override
  String get ocrHistoryDeleteAction => 'Delete scan';

  @override
  String get ocrHistoryDeleteTitle => 'Delete this scan?';

  @override
  String get ocrHistoryDeleteMessage =>
      'This deletes the scan and its photo from your device. The transactions it created are not deleted and stay in your records.';

  @override
  String get ocrHistoryDeleteConfirm => 'Delete scan';

  @override
  String get ocrScanDetailTitle => 'Scan details';

  @override
  String get ocrScanDetailImageMissing =>
      'The photo for this scan is no longer on your device.';

  @override
  String get ocrScanDetailEntriesTitle => 'Entries read from the paper';

  @override
  String get ocrScanDetailNoEntries => 'No entries were read from this scan.';

  @override
  String get ocrScanDetailUnknownPerson => 'No name read';

  @override
  String get ocrScanDetailNoAmount => 'No amount read';

  @override
  String get ocrScanDetailEntryStatusPending => 'Not reviewed';

  @override
  String get ocrScanDetailEntryStatusConfirmed => 'Confirmed';

  @override
  String get ocrScanDetailEntryStatusDiscarded => 'Discarded';

  @override
  String get ocrScanDetailTransactionsTitle => 'Transactions created';

  @override
  String get ocrScanDetailNoTransactionsMessage =>
      'This scan created no transactions.';

  @override
  String get ocrScanDetailTransactionsKeptNote =>
      'These are real transactions in your records. Deleting this scan does not delete them.';

  @override
  String get ocrScanDetailDeleteAction => 'Delete scan';

  @override
  String get ocrScanDetailDeleteTitle => 'Delete this scan?';

  @override
  String ocrScanDetailDeleteMessage(Object count) {
    return 'This deletes the scan and its photo from your device. The $count transactions it created are not deleted and stay in your records — you just lose the link back to the original photo.';
  }

  @override
  String get ocrScanDetailDeleteConfirm => 'Delete scan';

  @override
  String get ocrScanDetailDeletedMessage =>
      'Scan deleted. Its transactions were kept.';

  @override
  String get ocrScanDetailErrorTitle => 'Couldn\'t load this scan';

  @override
  String get ocrScanDetailErrorMessage =>
      'Something went wrong while reading this scan.';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsOverviewEntrySubtitle =>
      'Plan this month\'s spending by category';

  @override
  String get budgetFormCreateTitle => 'New budget';

  @override
  String get budgetFormEditTitle => 'Edit budget';

  @override
  String get budgetFormMonthLabel => 'Month';

  @override
  String get budgetExpectedIncomeLabel => 'Expected income (optional)';

  @override
  String get budgetExpectedIncomeHelp =>
      'For reference only — it never changes how spending is tracked.';

  @override
  String get budgetAllocationsHeader => 'Planned spending by category';

  @override
  String get budgetAllocationsEmpty =>
      'No categories yet. Pick an expense category below to start planning.';

  @override
  String get budgetAddCategoryHeader => 'Add a category';

  @override
  String get budgetAllCategoriesAdded =>
      'Every active expense category is already in this budget.';

  @override
  String get budgetPlannedAmountLabel => 'Planned amount';

  @override
  String get budgetRemoveAllocationAction => 'Remove from budget';

  @override
  String get budgetAmountRequiredError =>
      'Enter a planned amount (0 is allowed)';

  @override
  String get budgetAmountInvalidError => 'Enter a valid amount';

  @override
  String get budgetAmountNegativeError => 'The amount can\'t be negative';

  @override
  String get budgetTotalPlannedLabel => 'Total planned';

  @override
  String budgetExceedsIncomeWarning(String amount) {
    return 'Planned spending exceeds expected income by $amount';
  }

  @override
  String get budgetExceedsIncomeSaveNote => 'You can still save this budget.';

  @override
  String get budgetDeleteAction => 'Delete budget';

  @override
  String get budgetDeleteConfirmTitle => 'Delete this budget?';

  @override
  String budgetDeleteConfirmMessage(String month) {
    return 'The plan for $month will be removed. Your recorded expenses are not affected.';
  }

  @override
  String get budgetDeletedConfirmation => 'Budget deleted';

  @override
  String get budgetAlreadyExistsError =>
      'This month already has a budget. Open it to make changes.';

  @override
  String get budgetDuplicateCategoryError =>
      'This category is already in the budget.';

  @override
  String get budgetNotFoundError => 'This budget no longer exists.';

  @override
  String budgetEmptyTitle(String month) {
    return 'No budget for $month';
  }

  @override
  String get budgetEmptyMessage =>
      'Plan how much you intend to spend in each category, then track it against your real expenses.';

  @override
  String get budgetCreateAction => 'Create budget';

  @override
  String get budgetLoadErrorTitle => 'Couldn\'t load this budget';

  @override
  String get budgetOverallTitle => 'Overall';

  @override
  String get budgetPlannedLabel => 'Planned';

  @override
  String get budgetActualLabel => 'Spent';

  @override
  String get budgetRemainingLabel => 'Remaining';

  @override
  String get budgetOverByLabel => 'Over by';

  @override
  String budgetSpentOfPlanned(String actual, String planned) {
    return '$actual of $planned';
  }

  @override
  String budgetRemainingAmount(String amount) {
    return '$amount left';
  }

  @override
  String budgetOverByAmount(String amount) {
    return '$amount over';
  }

  @override
  String budgetPercentUsed(int percent) {
    return '$percent% used';
  }

  @override
  String get budgetPercentNotApplicable => 'Nothing planned';

  @override
  String get budgetStatusOnTrack => 'On track';

  @override
  String get budgetStatusNearFull => 'Near limit';

  @override
  String get budgetStatusOverBudget => 'Over budget';

  @override
  String get budgetCategoryArchivedTag => 'Archived';

  @override
  String get budgetCategoryMissingName => 'Deleted category';

  @override
  String get budgetCategoriesHeader => 'Categories';

  @override
  String get budgetNoAllocationsMessage =>
      'This budget has no categories yet. Edit it to add planned amounts.';

  @override
  String get budgetExpectedIncomeDisplay => 'Expected income';

  @override
  String get budgetUnbudgetedTitle => 'Unbudgeted spending';

  @override
  String get budgetUnbudgetedMessage =>
      'Spent this month in categories that aren\'t in your budget.';

  @override
  String get budgetUnbudgetedTotalLabel => 'Total unbudgeted';

  @override
  String get budgetRateNeededBadge => 'Rate needed';

  @override
  String budgetPlannedAmount(String amount) {
    return '$amount planned';
  }

  @override
  String budgetLineNeedsRate(String currencies) {
    return 'Spending needs an exchange rate for $currencies';
  }

  @override
  String budgetOverallNeedsRate(String currencies) {
    return 'Spent and remaining need an exchange rate for $currencies';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String get homeFinancialSnapshotTitle => 'Financial snapshot';

  @override
  String get homeFinanceThisMonthTitle => 'This month';

  @override
  String get homeFinanceIncome => 'Income';

  @override
  String get homeFinanceExpenses => 'Expenses';

  @override
  String get homeFinanceNet => 'Net';

  @override
  String get homeQuickActionsTitle => 'Quick actions';

  @override
  String get homeQuickAddExpense => 'Add expense';

  @override
  String get homeQuickAddIncome => 'Add income';

  @override
  String get homeQuickAddPerson => 'Add person';

  @override
  String get homeQuickMoneyReceived => 'Money received';

  @override
  String get homeQuickMoneyGiven => 'Money given';

  @override
  String get homeQuickAddOccasion => 'Add occasion';

  @override
  String get homeQuickScanPaper => 'Scan paper';

  @override
  String get homeSectionsTitle => 'Sections';

  @override
  String get homeInsightsTitle => 'Insights';

  @override
  String get homeInsightsPlaceholder =>
      'Insights will appear here once the AI Assistant is set up.';

  @override
  String get homeUpcomingTitle => 'Upcoming';

  @override
  String get homeUpcomingPlaceholder =>
      'Savings goals with a target date will appear here. Upcoming bills will follow once reminders are available.';

  @override
  String get homeSavingsTitle => 'Savings goals';

  @override
  String get homeSavingsEntrySubtitle =>
      'Plan and track what you\'re saving for';

  @override
  String homeSavingsUpcomingTargetDate(String date) {
    return 'Target date $date';
  }

  @override
  String homeSavingsUpcomingProgress(String current, String target) {
    return '$current of $target';
  }

  @override
  String get homeOverviewLoadError => 'Couldn\'t load your balances.';

  @override
  String get homeFinanceLoadError =>
      'Couldn\'t load this month\'s income and expenses.';

  @override
  String get homeFullErrorMessage =>
      'Your dashboard couldn\'t be loaded. Please try again.';

  @override
  String get homeEmptyTitle => 'Welcome to Daftary';

  @override
  String get homeEmptyMessage =>
      'Keep track of who owes you, what you owe, and where your money goes each month — all on your device.';

  @override
  String get homeEmptyAction => 'Add your first person';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsOpenAction => 'Reports';

  @override
  String get reportsTrendTitle => 'Monthly trend';

  @override
  String reportsTrendSubtitle(int months) {
    return 'Income and expenses over the last $months months';
  }

  @override
  String get reportsBreakdownTitle => 'Spending by category';

  @override
  String get reportsIncome => 'Income';

  @override
  String get reportsExpenses => 'Expenses';

  @override
  String get reportsNet => 'Net';

  @override
  String get reportsPeriodThisMonth => 'This month';

  @override
  String get reportsPeriodLastMonth => 'Last month';

  @override
  String get reportsPeriodLast3Months => 'Last 3 months';

  @override
  String get reportsPeriodLast6Months => 'Last 6 months';

  @override
  String get reportsBreakdownEmpty => 'No expenses recorded for this period.';

  @override
  String get reportsEmptyTitle => 'No reports yet';

  @override
  String get reportsEmptyMessage =>
      'Record your first income or expense to start seeing trends and category breakdowns.';

  @override
  String get reportsEmptyAction => 'Add an entry';

  @override
  String get reportsLoadError =>
      'Your reports couldn\'t be loaded. Please try again.';

  @override
  String get reportsExportAction => 'Export my data';

  @override
  String reportsCategoryShare(String percent) {
    return '$percent%';
  }

  @override
  String get exportTitle => 'Export my data';

  @override
  String get exportDescription =>
      'Create one CSV file containing a complete copy of your data: people, transactions, income and expense entries, categories, and settings. The file is created on your device and you choose where to send it.';

  @override
  String get exportGenerateAction => 'Create export file';

  @override
  String get exportGenerating => 'Preparing your export…';

  @override
  String get exportReadyTitle => 'Your export is ready';

  @override
  String exportReadyMessage(int count) {
    return '$count records were included.';
  }

  @override
  String get exportShareAction => 'Share file';

  @override
  String get exportRegenerateAction => 'Create a new export';

  @override
  String get exportError =>
      'Your export couldn\'t be created. No partial file was saved. Please try again.';

  @override
  String get exportShareError =>
      'The share sheet couldn\'t be opened. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get settingsDataSectionTitle => 'Your data';

  @override
  String get settingsExportTile => 'Export my data';

  @override
  String get settingsDangerZoneTitle => 'Danger zone';

  @override
  String get settingsDeleteDataTile => 'Delete my data';

  @override
  String get settingsDeleteDataSubtitle =>
      'Permanently erase everything stored in Daftary';

  @override
  String get securitySettingsTitle => 'Security';

  @override
  String get securitySettingsTileSubtitle =>
      'App lock, PIN and screenshot protection';

  @override
  String get appLockSettingsSectionTitle => 'App lock';

  @override
  String get appLockSettingsToggleTitle => 'Lock Daftary';

  @override
  String get appLockSettingsToggleSubtitle =>
      'Ask for your PIN whenever you open the app';

  @override
  String get appLockSettingsBiometricTitle => 'Unlock with fingerprint or face';

  @override
  String get appLockSettingsBiometricSubtitle => 'Your PIN still works too';

  @override
  String get appLockSettingsBiometricUnavailable =>
      'Not available on this device. Set up fingerprint or face unlock in your device settings first.';

  @override
  String get appLockSettingsChangePinTile => 'Change PIN';

  @override
  String get appLockSettingsTimeoutTitle => 'Lock after leaving the app';

  @override
  String get appLockSettingsTimeoutImmediately => 'Immediately';

  @override
  String get appLockSettingsTimeout30Seconds => 'After 30 seconds';

  @override
  String get appLockSettingsTimeout1Minute => 'After 1 minute';

  @override
  String get appLockSettingsTimeout5Minutes => 'After 5 minutes';

  @override
  String get appLockSettingsScreenshotProtectionTitle =>
      'Screenshot protection';

  @override
  String get appLockSettingsScreenshotProtectionStatus => 'Always on';

  @override
  String get appLockSettingsScreenshotProtectionBody =>
      'Screenshots and screen recordings can\'t capture your data, and the recent-apps view shows a placeholder instead. Sharing and exporting still work.';

  @override
  String get appLockSettingsDisableTitle => 'Turn off app lock?';

  @override
  String get appLockSettingsDisableMessage =>
      'Daftary will open without a PIN. Your PIN will be deleted, so turning app lock on again means choosing a new one. Screenshot protection stays on.';

  @override
  String get appLockSettingsDisableConfirm => 'Turn off';

  @override
  String get appLockSettingsBiometricReason =>
      'Confirm it\'s you to turn off app lock';

  @override
  String get appLockSettingsReauthTitle => 'Enter your PIN';

  @override
  String get appLockSettingsReauthMessage =>
      'Confirm it\'s you to turn off app lock.';

  @override
  String get appLockSettingsReauthPinLabel => 'Current PIN';

  @override
  String get appLockSettingsReauthConfirm => 'Confirm';

  @override
  String get appLockSettingsReauthIncorrect =>
      'That PIN isn\'t right. Try again.';

  @override
  String appLockSettingsReauthLockedOut(String duration) {
    return 'Too many wrong attempts. Try again in $duration.';
  }

  @override
  String get appLockSettingsReauthFailed =>
      'Couldn\'t check your PIN. Try again.';

  @override
  String get appLockSettingsEnabledMessage => 'App lock is on';

  @override
  String get appLockSettingsDisabledMessage => 'App lock is off';

  @override
  String get appLockSettingsPinChangedMessage => 'PIN changed';

  @override
  String get appLockSettingsSaveFailed =>
      'Couldn\'t save this change. Try again.';

  @override
  String get appLockSettingsLoadFailed =>
      'Couldn\'t load your security settings.';

  @override
  String get deleteDataTitle => 'Delete my data';

  @override
  String get deleteDataWarningTitle => 'This is permanent';

  @override
  String get deleteDataWarningMessage =>
      'This will permanently delete all of your people, transactions, occasions, scans, income and expense entries, categories, budgets, and settings from this device — and your cloud backup, if you use one. This cannot be undone. Consider exporting your data first.';

  @override
  String get deleteDataExportFirstAction => 'Export my data first';

  @override
  String get deleteDataConfirmPhrase => 'DELETE';

  @override
  String deleteDataConfirmLabel(String phrase) {
    return 'Type $phrase to confirm';
  }

  @override
  String deleteDataConfirmHint(String phrase) {
    return '$phrase';
  }

  @override
  String get deleteDataConfirmAction => 'Delete everything';

  @override
  String get deleteDataCancelAction => 'Cancel';

  @override
  String get deleteDataInProgress => 'Deleting your data…';

  @override
  String get deleteDataError =>
      'Your data couldn\'t be deleted. Nothing was removed — all your data is still intact. Please try again.';

  @override
  String get deleteDataCloudUnreachableError =>
      'Your cloud backup couldn\'t be reached, so nothing was deleted — all your data is still intact. Connect to the internet and try again.';

  @override
  String get appLockForgotTitle => 'Forgot PIN';

  @override
  String get appLockForgotBiometricTitle => 'Verify it\'s you';

  @override
  String get appLockForgotBiometricMessage =>
      'Confirm it\'s you with biometrics, then choose a new PIN. None of your data will be touched.';

  @override
  String get appLockForgotBiometricAction => 'Verify with biometrics';

  @override
  String get appLockForgotBiometricReason =>
      'Verify your identity to set a new Daftary PIN';

  @override
  String get appLockForgotBiometricFailed =>
      'Biometric verification didn\'t succeed. You can try again.';

  @override
  String get appLockForgotBiometricRetry => 'Try again';

  @override
  String get appLockForgotChooseWipeAction => 'Erase all data instead';

  @override
  String get appLockForgotWipeTitle => 'The only way back in';

  @override
  String get appLockForgotWipeMessage =>
      'Your PIN can\'t be reset. Without your PIN or biometrics, the only way to use the app again is to erase all of its data from this device and start fresh. If you linked cloud backup to your email, your backup is kept, and you can restore it afterwards by signing in with that email.';

  @override
  String get appLockForgotWipeContinueAction => 'Continue to erase data';

  @override
  String get appLockForgotBackAction => 'Back to lock screen';

  @override
  String get appLockWipeTitle => 'Erase all data';

  @override
  String get appLockWipeWarningTitle => 'This is permanent';

  @override
  String get appLockWipeWarningMessage =>
      'This will permanently erase all of your people, transactions, occasions, scans, income and expense entries, categories, budgets, settings, and your App Lock PIN from this device. It cannot be undone, and Daftary cannot recover it.';

  @override
  String get appLockWipeConfirmAction => 'Erase everything';

  @override
  String get appLockWipeCancelAction => 'Cancel';

  @override
  String get appLockWipeInProgress => 'Erasing your data…';

  @override
  String get appLockWipeError =>
      'Your data couldn\'t be erased. Nothing was removed — your data and PIN are unchanged. Please try again.';

  @override
  String get aiAssistantTitle => 'AI Assistant';

  @override
  String get aiAssistantHomeEntrySubtitle =>
      'Ask questions about your own money. Off until you set it up.';

  @override
  String get aiSettingsTitle => 'AI Assistant settings';

  @override
  String get aiSettingsIntroTitle => 'The assistant is off';

  @override
  String get aiSettingsIntroMessage =>
      'To turn it on, choose your AI provider, enter your own API key, and review exactly what will be shared. Daftary never ships with a key of its own.';

  @override
  String get aiSettingsProviderSectionTitle => 'Provider';

  @override
  String get aiSettingsProviderCustom => 'Custom provider';

  @override
  String get aiSettingsCustomProviderHint =>
      'Any provider with an OpenAI-compatible chat API that supports tool calling.';

  @override
  String get aiSettingsCustomBaseUrlLabel => 'API base URL (https://…)';

  @override
  String get aiSettingsCustomModelLabel => 'Model name';

  @override
  String get aiSettingsApiKeySectionTitle => 'API key';

  @override
  String get aiSettingsApiKeyLabel => 'Your API key';

  @override
  String get aiSettingsApiKeyNote =>
      'Stored only in this device\'s secure storage and sent only to the provider you chose. It is never shown again after you save it.';

  @override
  String get aiSettingsProviderRequired => 'Choose a provider';

  @override
  String get aiSettingsCustomBaseUrlInvalid =>
      'Enter a full address starting with https://';

  @override
  String get aiSettingsCustomModelRequired => 'Enter the model name';

  @override
  String get aiSettingsApiKeyRequired => 'Enter your API key';

  @override
  String get aiSettingsApiKeyMalformed =>
      'This doesn\'t look like a complete API key';

  @override
  String get aiSettingsContinueAction => 'Continue';

  @override
  String get aiSettingsEnabledTitle => 'The assistant is on';

  @override
  String aiSettingsEnabledProvider(String provider) {
    return 'Provider: $provider';
  }

  @override
  String get aiSettingsApiKeySaved => 'API key: saved securely (hidden)';

  @override
  String aiSettingsConsentAcceptedOn(String date) {
    return 'Data-sharing disclosure accepted on $date';
  }

  @override
  String get aiSettingsChangeCredentialsAction => 'Change provider or key';

  @override
  String get aiSettingsChangeCredentialsTitle => 'Change provider or key';

  @override
  String get aiSettingsChangeCredentialsMessage =>
      'Enter the new key. The key saved now will be discarded once the new one is saved.';

  @override
  String get aiSettingsSaveCredentialsAction => 'Save new key';

  @override
  String get aiSettingsCancelAction => 'Cancel';

  @override
  String get aiSettingsDisableAction => 'Turn off assistant';

  @override
  String get aiSettingsDisableConfirmTitle => 'Turn off the assistant?';

  @override
  String get aiSettingsDisableConfirmMessage =>
      'Nothing more will be sent to your AI provider. Your saved API key will be deleted from this device, so turning the assistant back on means entering a key and accepting the data-sharing disclosure again. Your conversation history is kept.';

  @override
  String get aiSettingsDisableConfirmAction => 'Turn off';

  @override
  String get aiSettingsEnabledMessage => 'AI assistant turned on';

  @override
  String get aiSettingsCredentialsUpdatedMessage =>
      'Provider and key updated. The previous key was discarded.';

  @override
  String get aiSettingsDisabledMessage =>
      'AI assistant turned off. Your API key was deleted from this device.';

  @override
  String get aiSettingsSaveFailed =>
      'Your AI assistant settings couldn\'t be saved. Nothing was changed. Please try again.';

  @override
  String get aiSettingsLoadFailed =>
      'AI assistant settings couldn\'t be loaded.';

  @override
  String aiSettingsCustomProviderName(String host) {
    return 'your custom provider ($host)';
  }

  @override
  String get aiConsentTitle => 'Before you turn on the assistant';

  @override
  String get aiConsentIntro =>
      'Here is exactly what happens when you ask the assistant a question:';

  @override
  String get aiConsentPointMinimal =>
      'Only the small piece of data needed to answer that one question is sent — for example, one category\'s total for one month. Never a full copy of your records.';

  @override
  String aiConsentPointProviderOnly(String provider) {
    return 'It goes only to $provider, using your own key. Never to Daftary, and never to anyone else.';
  }

  @override
  String get aiConsentPointOnDemand =>
      'Nothing is sent until you ask a question.';

  @override
  String get aiConsentPointReadOnly =>
      'The assistant can only read and explain your figures. It can never add, change, or delete anything.';

  @override
  String get aiConsentPointCost =>
      'Your provider may charge your account for each question.';

  @override
  String get aiConsentPointDisable =>
      'You can turn the assistant off at any time. That immediately stops anything more from being sent and deletes your key from this device.';

  @override
  String get aiConsentAcceptAction => 'I agree, turn it on';

  @override
  String get aiConsentDeclineAction => 'Not now';

  @override
  String get aiChatTitle => 'AI Assistant';

  @override
  String get aiChatInputHint =>
      'Ask about your spending, budgets, or balances…';

  @override
  String get aiChatSendAction => 'Send question';

  @override
  String get aiChatEmptyTitle => 'Ask about your own money';

  @override
  String get aiChatEmptyMessage =>
      'For example: \"How much did I spend on food this month?\" Answers come only from your own records in Daftary.';

  @override
  String get aiChatClearAction => 'Clear conversation';

  @override
  String get aiChatClearConfirmTitle => 'Clear this conversation?';

  @override
  String get aiChatClearConfirmMessage =>
      'All questions and answers will be deleted from this device. Your financial records won\'t be affected.';

  @override
  String get aiChatClearConfirmAction => 'Clear';

  @override
  String get aiChatClearedMessage => 'Conversation cleared';

  @override
  String get aiChatClearFailed =>
      'The conversation couldn\'t be cleared. Please try again.';

  @override
  String get aiChatLoadEarlierAction => 'Show earlier messages';

  @override
  String get aiChatLoadFailed => 'Your conversation couldn\'t be loaded.';

  @override
  String get aiChatTypingLabel => 'The assistant is preparing an answer';

  @override
  String get aiChatYouLabel => 'You';

  @override
  String get aiChatAssistantLabel => 'Assistant';

  @override
  String get aiChatMessageFailedLabel => 'Not answered';

  @override
  String get aiChatInterruptedLabel =>
      'Not answered: the assistant was turned off before a reply arrived';

  @override
  String get aiChatDisabledTitle => 'The assistant is off';

  @override
  String get aiChatDisabledMessage =>
      'Turn it on in the assistant settings to start asking questions about your money.';

  @override
  String get aiChatOpenSettingsAction => 'Open settings';

  @override
  String get aiChatSettingsAction => 'Assistant settings';

  @override
  String get aiChatReadOnlyNotice =>
      'The assistant can only read and explain your figures. It can\'t add, change, or delete anything, so nothing was changed. You can do that yourself from the app.';

  @override
  String get aiChatNothingChangedLabel => 'Nothing in your records was changed';

  @override
  String get aiFailureInvalidApiKeyTitle => 'API key not accepted';

  @override
  String get aiFailureInvalidApiKeyMessage =>
      'Your provider rejected your API key. It may be wrong, expired, or revoked. Update it to keep asking questions.';

  @override
  String get aiFailureRateLimitedTitle => 'Too many requests';

  @override
  String get aiFailureRateLimitedMessage =>
      'Your provider is limiting requests right now. Wait a minute or two, then try again.';

  @override
  String get aiFailureNetworkTitle => 'No internet connection';

  @override
  String get aiFailureNetworkMessage =>
      'The assistant needs an internet connection. Everything else in Daftary keeps working offline.';

  @override
  String get aiFailureProviderErrorTitle => 'Provider unavailable';

  @override
  String get aiFailureProviderErrorMessage =>
      'Your AI provider is having a problem on its side. Please try again in a little while.';

  @override
  String get aiFailureUnrecognizedTitle => 'Unexpected reply';

  @override
  String get aiFailureUnrecognizedMessage =>
      'The assistant\'s reply couldn\'t be understood. Please try asking again.';

  @override
  String get aiFailureLocalTitle => 'Couldn\'t save';

  @override
  String get aiFailureLocalMessage =>
      'Your question couldn\'t be saved on this device. Please try again.';

  @override
  String get aiFailureRetryAction => 'Try again';

  @override
  String get aiFailureUpdateKeyAction => 'Update API key';

  @override
  String get aiObservationLabel => 'Observation';

  @override
  String get aiObservationSemanticLabel =>
      'Observation from the assistant, based on your own records';

  @override
  String get savingsGoalNotFoundError => 'This savings goal no longer exists.';

  @override
  String get savingsWithdrawalExceedsBalanceError =>
      'You can\'t withdraw more than this goal has saved.';

  @override
  String get savingsGoalHasHistoryError =>
      'This goal has saved amounts, so it can\'t be deleted. You can archive it instead.';

  @override
  String get savingsInvalidTargetDateError =>
      'Choose a target date after today.';

  @override
  String get savingsGoalArchivedError =>
      'This goal is archived. Restore it to add new amounts.';

  @override
  String get savingsGoalFormCreateTitle => 'New savings goal';

  @override
  String get savingsGoalFormEditTitle => 'Edit goal';

  @override
  String get savingsGoalEditAction => 'Edit goal';

  @override
  String get savingsGoalNameLabel => 'Goal name';

  @override
  String get savingsGoalNameRequiredError => 'Give the goal a name.';

  @override
  String get savingsGoalTypeLabel => 'Type (optional)';

  @override
  String get savingsGoalTypeNone => 'No type';

  @override
  String get savingsGoalTypeEmergencyFund => 'Emergency fund';

  @override
  String get savingsGoalTypeNewCar => 'New car';

  @override
  String get savingsGoalTypeWedding => 'Wedding';

  @override
  String get savingsGoalTypeVacation => 'Vacation';

  @override
  String get savingsGoalTypeNewPhone => 'New phone';

  @override
  String get savingsGoalTypeHomeFurniture => 'Home furniture';

  @override
  String get savingsGoalTypeEducation => 'Education';

  @override
  String get savingsGoalTypeOther => 'Other';

  @override
  String get savingsGoalCurrencyLabel => 'Goal currency';

  @override
  String savingsGoalCurrencyFixedHint(String currency) {
    return 'Every amount of this goal is in $currency. The currency can\'t be changed after the goal is created.';
  }

  @override
  String get savingsGoalTargetLabel => 'Target amount';

  @override
  String get savingsGoalTargetInvalidError =>
      'Enter a target amount greater than zero.';

  @override
  String get savingsGoalStartingLabel => 'Already saved (optional)';

  @override
  String get savingsGoalStartingHint =>
      'Money you had already set aside before tracking it here.';

  @override
  String get savingsGoalStartingInvalidError =>
      'Enter zero or a positive amount.';

  @override
  String get savingsGoalMonthlyLabel => 'Monthly contribution (optional)';

  @override
  String get savingsGoalMonthlyInvalidError =>
      'Enter a monthly amount greater than zero, or leave it empty.';

  @override
  String get savingsGoalTargetDateLabel => 'Target date (optional)';

  @override
  String get savingsGoalTargetDateNotSet => 'Not set';

  @override
  String get savingsGoalTargetDateClear => 'Clear target date';

  @override
  String get savingsGoalCreateAction => 'Create goal';

  @override
  String get savingsGoalUpdateAction => 'Save changes';

  @override
  String get savingsGoalPreviewTitle => 'Your plan';

  @override
  String get savingsProgressSavedLabel => 'Saved';

  @override
  String get savingsProgressRemainingLabel => 'Remaining';

  @override
  String get savingsProgressTargetLabel => 'Target';

  @override
  String savingsProgressPercent(String percent) {
    return '$percent% saved';
  }

  @override
  String savingsEstimateByContribution(
    String amount,
    String duration,
    String date,
  ) {
    return 'At $amount a month, you\'ll reach it in $duration, around $date.';
  }

  @override
  String savingsEstimateByContributionUndated(String amount, String duration) {
    return 'At $amount a month, you\'ll reach it in $duration.';
  }

  @override
  String savingsEstimateRequired(String date, String amount) {
    return 'To reach it by $date, save $amount a month.';
  }

  @override
  String savingsEstimateShortfall(String duration) {
    return 'At this rate, you\'ll reach this $duration after your target date.';
  }

  @override
  String get savingsNoEstimatePrompt =>
      'Set a monthly contribution or a target date to see when you\'ll reach this goal.';

  @override
  String savingsDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String savingsDurationYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String savingsDurationYearsAndMonths(String years, String months) {
    return '$years and $months';
  }

  @override
  String get savingsGoalAchievedBadge => 'Goal reached!';

  @override
  String get savingsGoalAchievedMessage =>
      'You\'ve saved everything you planned for this goal. Well done!';

  @override
  String get savingsGoalHistoryHeader => 'History';

  @override
  String get savingsGoalHistoryEmptyTitle => 'Nothing logged yet';

  @override
  String get savingsGoalHistoryEmptyMessage =>
      'Add what you put toward this goal to track your real progress.';

  @override
  String get savingsLogContributionAction => 'Add money';

  @override
  String get savingsLogWithdrawalAction => 'Withdraw';

  @override
  String get savingsGoalArchivedNotice =>
      'This goal is archived. You can still correct past entries; restore it to add new ones.';

  @override
  String get savingsGoalLoadErrorTitle => 'Couldn\'t open this goal';

  @override
  String get savingsRetryAction => 'Try again';

  @override
  String get savingsEntryContribution => 'Contribution';

  @override
  String get savingsEntryWithdrawal => 'Withdrawal';

  @override
  String get savingsEntryStartingAmount => 'Starting amount';

  @override
  String savingsEntryConvertedAmount(String amount) {
    return 'Counted as $amount';
  }

  @override
  String get savingsEntryEditedLabel => 'Edited';

  @override
  String get savingsEntryEditAction => 'Edit';

  @override
  String get savingsEntryDeleteAction => 'Delete';

  @override
  String get savingsEntryActionsTooltip => 'Entry options';

  @override
  String get savingsEntryDeleteConfirmTitle => 'Delete this entry?';

  @override
  String get savingsEntryDeleteConfirmMessage =>
      'The goal\'s figures will be recalculated. A record of the entry\'s values is kept.';

  @override
  String get savingsContributionFormAddTitle => 'Add money';

  @override
  String get savingsContributionFormWithdrawTitle => 'Withdraw money';

  @override
  String get savingsContributionFormEditTitle => 'Edit entry';

  @override
  String get savingsContributionAmountLabel => 'Amount';

  @override
  String get savingsContributionAmountInvalidError =>
      'Enter an amount greater than zero.';

  @override
  String get savingsContributionDateLabel => 'Date';

  @override
  String get savingsContributionNoteLabel => 'Note (optional)';

  @override
  String get savingsContributionSaveAction => 'Save';

  @override
  String savingsContributionConversionHint(String currency) {
    return 'This will be converted to $currency at the current rate when you save.';
  }

  @override
  String get savingsOverviewTitle => 'Savings goals';

  @override
  String get savingsOverviewNewGoalAction => 'New goal';

  @override
  String get savingsOverviewArchivedAction => 'Archived goals';

  @override
  String get savingsOverviewEmptyTitle => 'Start saving toward something';

  @override
  String get savingsOverviewEmptyMessage =>
      'Set a goal — an emergency fund, a trip, a new phone — and track every amount you put aside until you reach it.';

  @override
  String get savingsOverviewEmptyAction => 'Create your first goal';

  @override
  String get savingsOverviewTotalLabel => 'Total saved';

  @override
  String savingsOverviewGoalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Across $count goals',
      one: 'Across 1 goal',
    );
    return '$_temp0';
  }

  @override
  String get savingsOverviewIncompleteTitle => 'Total incomplete';

  @override
  String savingsOverviewIncompleteMessage(String currencies) {
    return 'It leaves out goals in $currencies. Add an exchange rate for $currencies to count them.';
  }

  @override
  String savingsOverviewNotInTotal(String currency) {
    return 'Not in the total — needs a $currency rate';
  }

  @override
  String savingsOverviewGoalProgress(String saved, String target) {
    return '$saved of $target';
  }

  @override
  String get savingsOverviewGoalsHeader => 'Your goals';

  @override
  String get savingsOverviewLoadErrorTitle => 'Couldn\'t load your goals';

  @override
  String get savingsOverviewGoalActionsTooltip => 'Goal options';

  @override
  String get savingsArchiveAction => 'Archive';

  @override
  String get savingsArchiveRestoreAction => 'Restore';

  @override
  String get savingsArchiveDoneMessage => 'Goal archived';

  @override
  String get savingsArchiveRestoredMessage => 'Goal restored';

  @override
  String get savingsArchiveUndoAction => 'Undo';

  @override
  String get savingsArchiveTitle => 'Archived goals';

  @override
  String get savingsArchiveEmptyTitle => 'No archived goals';

  @override
  String get savingsArchiveEmptyMessage =>
      'Goals you archive are kept here with their full history, ready to restore.';

  @override
  String get savingsDeleteAction => 'Delete goal';

  @override
  String savingsDeleteConfirmTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get savingsDeleteConfirmMessage =>
      'This goal will be removed for good.';

  @override
  String get savingsDeleteBlockedTitle => 'This goal has history';

  @override
  String get savingsDeleteBlockedMessage =>
      'Amounts have been logged to this goal, so it can\'t be deleted. Archive it instead to hide it while keeping its full history.';

  @override
  String get savingsDeleteBlockedArchiveAction => 'Archive instead';

  @override
  String get savingsDeleteDoneMessage => 'Goal deleted';

  @override
  String savingsWithdrawalAvailableHint(String amount) {
    return 'Available to withdraw: $amount';
  }

  @override
  String get savingsWhatIfAction => 'What if?';

  @override
  String get savingsWhatIfTitle => 'What if?';

  @override
  String get savingsWhatIfModeMonthly => 'Save a different amount';

  @override
  String get savingsWhatIfModeDate => 'Finish by a date';

  @override
  String get savingsWhatIfCurrentPlanTitle => 'Your plan now';

  @override
  String savingsWhatIfCurrentRemaining(String amount) {
    return '$amount left to save';
  }

  @override
  String savingsWhatIfCurrentMonthly(String amount) {
    return 'Saving $amount a month';
  }

  @override
  String get savingsWhatIfCurrentNoMonthly => 'No monthly contribution set';

  @override
  String savingsWhatIfCurrentTargetDate(String date) {
    return 'Target date: $date';
  }

  @override
  String get savingsWhatIfMonthlyLabel => 'Monthly amount to try';

  @override
  String get savingsWhatIfMonthlyInvalidError =>
      'Enter a monthly amount greater than zero.';

  @override
  String get savingsWhatIfTargetDateLabel => 'Finish by';

  @override
  String get savingsWhatIfTargetDateNotSet => 'Pick a date';

  @override
  String get savingsWhatIfCalculateAction => 'Calculate';

  @override
  String get savingsWhatIfResultTitle => 'If you did this';

  @override
  String savingsWhatIfResultByMonthly(
    String amount,
    String duration,
    String date,
  ) {
    return 'Saving $amount a month, you\'d reach your goal in $duration, around $date.';
  }

  @override
  String savingsWhatIfResultByMonthlyUndated(String amount, String duration) {
    return 'Saving $amount a month, you\'d reach your goal in $duration.';
  }

  @override
  String savingsWhatIfResultByDate(String date, String amount) {
    return 'To finish by $date, you\'d need to save $amount a month.';
  }

  @override
  String savingsWhatIfCompareSooner(String duration) {
    return '$duration sooner than your current plan';
  }

  @override
  String savingsWhatIfCompareLater(String duration) {
    return '$duration later than your current plan';
  }

  @override
  String get savingsWhatIfCompareSame =>
      'The same timeline as your current plan';

  @override
  String savingsWhatIfCompareMore(String amount) {
    return '$amount a month more than you save now';
  }

  @override
  String savingsWhatIfCompareLess(String amount) {
    return '$amount a month less than you save now';
  }

  @override
  String get savingsWhatIfPreviewNotice =>
      'This is only a preview. Your goal stays as it is unless you apply it.';

  @override
  String savingsWhatIfApplyExplainMonthly(String amount) {
    return 'Applying sets your monthly contribution to $amount. Your target date stays as it is.';
  }

  @override
  String savingsWhatIfApplyExplainDate(String date, String amount) {
    return 'Applying sets your target date to $date and your monthly contribution to $amount.';
  }

  @override
  String get savingsWhatIfApplyAction => 'Apply to my goal';

  @override
  String get savingsWhatIfCancelAction => 'Cancel';

  @override
  String get savingsWhatIfAppliedMessage => 'Your goal\'s plan was updated.';

  @override
  String get savingsWhatIfAchievedTitle => 'Goal achieved';

  @override
  String get savingsWhatIfAchievedMessage =>
      'You\'ve already reached this goal, so there\'s nothing left to plan for.';

  @override
  String get savingsWhatIfBackAction => 'Back to goal';
}
