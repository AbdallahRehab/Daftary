import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @budgetMonthNavPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get budgetMonthNavPrevious;

  /// No description provided for @budgetMonthNavNext.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get budgetMonthNavNext;

  /// No description provided for @budgetMonthNavCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget month: {month}'**
  String budgetMonthNavCurrentLabel(String month);

  /// No description provided for @budgetCopyFromMonthAction.
  ///
  /// In en, this message translates to:
  /// **'Copy {month}\'s budget'**
  String budgetCopyFromMonthAction(String month);

  /// No description provided for @budgetCopyFromMonthMessage.
  ///
  /// In en, this message translates to:
  /// **'Start from the plan you made for {month}. You can adjust it afterwards without changing {month}.'**
  String budgetCopyFromMonthMessage(String month);

  /// No description provided for @budgetCopyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Copying…'**
  String get budgetCopyInProgress;

  /// No description provided for @budgetCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Budget copied from {month}'**
  String budgetCopySuccess(String month);

  /// No description provided for @budgetCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy the budget. Please try again.'**
  String get budgetCopyFailed;

  /// No description provided for @budgetCopyAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This month already has a budget.'**
  String get budgetCopyAlreadyExists;

  /// No description provided for @budgetTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending trends'**
  String get budgetTrendTitle;

  /// No description provided for @budgetTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Planned vs. actual, last 6 months'**
  String get budgetTrendSubtitle;

  /// No description provided for @budgetTrendOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get budgetTrendOverall;

  /// No description provided for @budgetTrendCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetTrendCategoryLabel;

  /// No description provided for @budgetTrendPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get budgetTrendPlanned;

  /// No description provided for @budgetTrendActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get budgetTrendActual;

  /// No description provided for @budgetTrendOverPlan.
  ///
  /// In en, this message translates to:
  /// **'Over plan'**
  String get budgetTrendOverPlan;

  /// No description provided for @budgetTrendNoBudget.
  ///
  /// In en, this message translates to:
  /// **'No budget'**
  String get budgetTrendNoBudget;

  /// No description provided for @budgetTrendInsufficientTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough history yet'**
  String get budgetTrendInsufficientTitle;

  /// No description provided for @budgetTrendInsufficientMessage.
  ///
  /// In en, this message translates to:
  /// **'Trends need a budget in at least 2 months. Keep budgeting and check back next month.'**
  String get budgetTrendInsufficientMessage;

  /// No description provided for @budgetTrendMonthSummary.
  ///
  /// In en, this message translates to:
  /// **'{month}: planned {planned}, actual {actual}'**
  String budgetTrendMonthSummary(String month, String planned, String actual);

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Daftary'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get commonArchive;

  /// No description provided for @commonRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get commonRestore;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @errorCache.
  ///
  /// In en, this message translates to:
  /// **'A local storage error occurred. Please try again.'**
  String get errorCache;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item could not be found.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check your input and try again.'**
  String get errorValidation;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnknown;

  /// No description provided for @peopleListTitle.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleListTitle;

  /// No description provided for @searchPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Search people'**
  String get searchPeopleHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterTheyOweYou.
  ///
  /// In en, this message translates to:
  /// **'They owe you'**
  String get filterTheyOweYou;

  /// No description provided for @filterYouOweThem.
  ///
  /// In en, this message translates to:
  /// **'You owe them'**
  String get filterYouOweThem;

  /// No description provided for @filterSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get filterSettled;

  /// No description provided for @emptyPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'No people yet'**
  String get emptyPeopleTitle;

  /// No description provided for @emptyPeopleMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a person to start tracking money you give or receive with them.'**
  String get emptyPeopleMessage;

  /// No description provided for @archivedPeopleAction.
  ///
  /// In en, this message translates to:
  /// **'Archived people'**
  String get archivedPeopleAction;

  /// No description provided for @addPersonAction.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addPersonAction;

  /// No description provided for @personFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New person'**
  String get personFormCreateTitle;

  /// No description provided for @personFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit person'**
  String get personFormEditTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequiredError;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get phoneLabel;

  /// No description provided for @relationshipTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship (optional)'**
  String get relationshipTagLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesLabel;

  /// No description provided for @deletePersonAction.
  ///
  /// In en, this message translates to:
  /// **'Delete person'**
  String get deletePersonAction;

  /// No description provided for @deleteBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t delete this person'**
  String get deleteBlockedTitle;

  /// No description provided for @deleteBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This person has recorded transactions. Archive them instead to keep their history.'**
  String get deleteBlockedMessage;

  /// No description provided for @archiveInsteadAction.
  ///
  /// In en, this message translates to:
  /// **'Archive instead'**
  String get archiveInsteadAction;

  /// No description provided for @relationshipFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get relationshipFamily;

  /// No description provided for @relationshipFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get relationshipFriend;

  /// No description provided for @relationshipColleague.
  ///
  /// In en, this message translates to:
  /// **'Colleague'**
  String get relationshipColleague;

  /// No description provided for @relationshipCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get relationshipCustomer;

  /// No description provided for @relationshipSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get relationshipSupplier;

  /// No description provided for @relationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationshipOther;

  /// No description provided for @duplicateWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get duplicateWarningTitle;

  /// No description provided for @duplicateWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This name looks similar to someone you already know.'**
  String get duplicateWarningMessage;

  /// No description provided for @duplicateUseExisting.
  ///
  /// In en, this message translates to:
  /// **'Use existing person'**
  String get duplicateUseExisting;

  /// No description provided for @duplicateCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new person anyway'**
  String get duplicateCreateNew;

  /// No description provided for @transactionFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Record transaction'**
  String get transactionFormCreateTitle;

  /// No description provided for @transactionFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionFormEditTitle;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (EGP)'**
  String get amountLabel;

  /// No description provided for @amountInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero'**
  String get amountInvalidError;

  /// No description provided for @directionGiven.
  ///
  /// In en, this message translates to:
  /// **'I gave'**
  String get directionGiven;

  /// No description provided for @directionReceived.
  ///
  /// In en, this message translates to:
  /// **'I received'**
  String get directionReceived;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteLabel;

  /// No description provided for @personLabel.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get personLabel;

  /// No description provided for @createPersonInlineAction.
  ///
  /// In en, this message translates to:
  /// **'Create new person'**
  String get createPersonInlineAction;

  /// No description provided for @savedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedConfirmation;

  /// No description provided for @editedLabel.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get editedLabel;

  /// No description provided for @repaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get repaymentLabel;

  /// No description provided for @repaymentFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Record repayment'**
  String get repaymentFormTitle;

  /// No description provided for @recordRepaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Record repayment'**
  String get recordRepaymentAction;

  /// No description provided for @personDetailTheyOweYou.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you {amount}'**
  String personDetailTheyOweYou(String name, String amount);

  /// No description provided for @personDetailYouOweThem.
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String personDetailYouOweThem(String name, String amount);

  /// No description provided for @personDetailSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get personDetailSettled;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Record a transaction with {name} to start tracking your balance.'**
  String historyEmptyMessage(String name);

  /// No description provided for @recordTransactionAction.
  ///
  /// In en, this message translates to:
  /// **'Record transaction'**
  String get recordTransactionAction;

  /// No description provided for @deleteTransactionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get deleteTransactionConfirmTitle;

  /// No description provided for @deleteTransactionConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteTransactionConfirmMessage;

  /// No description provided for @overviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTitle;

  /// No description provided for @overviewTotalOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'Total owed to you'**
  String get overviewTotalOwedToYou;

  /// No description provided for @overviewTotalYouOwe.
  ///
  /// In en, this message translates to:
  /// **'Total you owe'**
  String get overviewTotalYouOwe;

  /// No description provided for @overviewSectionTheyOweYou.
  ///
  /// In en, this message translates to:
  /// **'They owe you'**
  String get overviewSectionTheyOweYou;

  /// No description provided for @overviewSectionYouOweThem.
  ///
  /// In en, this message translates to:
  /// **'You owe them'**
  String get overviewSectionYouOweThem;

  /// No description provided for @overviewAllSettledTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything is settled'**
  String get overviewAllSettledTitle;

  /// No description provided for @overviewAllSettledMessage.
  ///
  /// In en, this message translates to:
  /// **'You have no outstanding balances with anyone right now.'**
  String get overviewAllSettledMessage;

  /// No description provided for @archivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedLabel;

  /// No description provided for @archivedPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived people'**
  String get archivedPeopleTitle;

  /// No description provided for @archivedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No archived people'**
  String get archivedEmptyTitle;

  /// No description provided for @archivedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'People you archive will appear here, with their history intact.'**
  String get archivedEmptyMessage;

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your language choice. It\'s still active for this session — we\'ll keep trying.'**
  String get settingsSaveFailed;

  /// No description provided for @themeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSectionTitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystemDefault;

  /// No description provided for @themeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your theme choice. It\'s still active for this session — we\'ll keep trying.'**
  String get themeSaveFailed;

  /// No description provided for @onboardingStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepProgress(int current, int total);

  /// No description provided for @onboardingUnderstandingMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Understand your money at a glance'**
  String get onboardingUnderstandingMoneyTitle;

  /// No description provided for @onboardingUnderstandingMoneyDescription.
  ///
  /// In en, this message translates to:
  /// **'See who owes you, who you owe, and how things stand overall — all in one place.'**
  String get onboardingUnderstandingMoneyDescription;

  /// No description provided for @onboardingMoneyBetweenPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Track money between you and people'**
  String get onboardingMoneyBetweenPeopleTitle;

  /// No description provided for @onboardingMoneyBetweenPeopleDescription.
  ///
  /// In en, this message translates to:
  /// **'Add someone, record what you gave or received, and Daftary keeps the running total for you.'**
  String get onboardingMoneyBetweenPeopleDescription;

  /// No description provided for @onboardingSocialOccasionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep social exchanges straight'**
  String get onboardingSocialOccasionsTitle;

  /// No description provided for @onboardingSocialOccasionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Lending a friend cash, splitting a gift, or covering someone at a gathering — jot it down so nothing gets forgotten.'**
  String get onboardingSocialOccasionsDescription;

  /// No description provided for @onboardingScanningRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Look back whenever you need to'**
  String get onboardingScanningRecordsTitle;

  /// No description provided for @onboardingScanningRecordsDescription.
  ///
  /// In en, this message translates to:
  /// **'Every entry is saved with its date, so you can scan your full history with any person at any time.'**
  String get onboardingScanningRecordsDescription;

  /// No description provided for @onboardingAiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Get help making sense of it all'**
  String get onboardingAiAssistantTitle;

  /// No description provided for @onboardingAiAssistantDescription.
  ///
  /// In en, this message translates to:
  /// **'An AI assistant can help you review and organize what you\'ve recorded — it does not give financial advice or guarantee outcomes.'**
  String get onboardingAiAssistantDescription;

  /// No description provided for @onboardingBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBackAction;

  /// No description provided for @onboardingNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNextAction;

  /// No description provided for @onboardingGetStartedAction.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStartedAction;

  /// No description provided for @onboardingSkipAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkipAction;

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Income & expenses'**
  String get financeTitle;

  /// No description provided for @financeOverviewCardTitle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get financeOverviewCardTitle;

  /// No description provided for @financeAddExpenseAction.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get financeAddExpenseAction;

  /// No description provided for @financeAddIncomeAction.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get financeAddIncomeAction;

  /// No description provided for @financeAddFirstEntryAction.
  ///
  /// In en, this message translates to:
  /// **'Add your first entry'**
  String get financeAddFirstEntryAction;

  /// No description provided for @financeViewAllAction.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get financeViewAllAction;

  /// No description provided for @financeEntryFormExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get financeEntryFormExpenseTitle;

  /// No description provided for @financeEntryFormIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get financeEntryFormIncomeTitle;

  /// No description provided for @financeEntryFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get financeEntryFormEditTitle;

  /// No description provided for @financeTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get financeTypeExpense;

  /// No description provided for @financeTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get financeTypeIncome;

  /// No description provided for @financeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get financeCategoryLabel;

  /// No description provided for @financeCategoryRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get financeCategoryRequiredError;

  /// No description provided for @financeManageCategoriesAction.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get financeManageCategoriesAction;

  /// No description provided for @financeNoCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get financeNoCategoriesTitle;

  /// No description provided for @financeNoCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a category to start recording entries.'**
  String get financeNoCategoriesMessage;

  /// No description provided for @financeCategoryManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get financeCategoryManagementTitle;

  /// No description provided for @financeCategoryFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get financeCategoryFormCreateTitle;

  /// No description provided for @financeCategoryFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get financeCategoryFormEditTitle;

  /// No description provided for @financeCategoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get financeCategoryNameLabel;

  /// No description provided for @financeCategoryNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Category name is required'**
  String get financeCategoryNameRequiredError;

  /// No description provided for @financeCategoryIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get financeCategoryIconLabel;

  /// No description provided for @financeCategoryIconRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Choose an icon'**
  String get financeCategoryIconRequiredError;

  /// No description provided for @financeCategoryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get financeCategoryTypeLabel;

  /// No description provided for @financeCategoryDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'You already have a category named \"{name}\".'**
  String financeCategoryDuplicateError(String name);

  /// No description provided for @financeCategorySectionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get financeCategorySectionActive;

  /// No description provided for @financeCategorySectionArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get financeCategorySectionArchived;

  /// No description provided for @financeAddCategoryAction.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get financeAddCategoryAction;

  /// No description provided for @financeRemoveCategoryAction.
  ///
  /// In en, this message translates to:
  /// **'Remove category'**
  String get financeRemoveCategoryAction;

  /// No description provided for @financeRemoveCategoryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this category?'**
  String get financeRemoveCategoryConfirmTitle;

  /// No description provided for @financeRemoveCategoryConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'If any entries use this category, it will be archived so their history stays intact. Otherwise it will be deleted.'**
  String get financeRemoveCategoryConfirmMessage;

  /// No description provided for @financeCategoryArchivedNotice.
  ///
  /// In en, this message translates to:
  /// **'Archived — hidden from new entries, kept for existing ones.'**
  String get financeCategoryArchivedNotice;

  /// No description provided for @financePeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get financePeriodThisMonth;

  /// No description provided for @financePeriodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get financePeriodLastMonth;

  /// No description provided for @financePeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get financePeriodCustom;

  /// No description provided for @financePeriodStartLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get financePeriodStartLabel;

  /// No description provided for @financePeriodEndLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get financePeriodEndLabel;

  /// No description provided for @financeSummaryTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get financeSummaryTotalIncome;

  /// No description provided for @financeSummaryTotalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get financeSummaryTotalExpense;

  /// No description provided for @financeSummaryNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get financeSummaryNet;

  /// No description provided for @financeBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get financeBreakdownTitle;

  /// No description provided for @financeBreakdownShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of total'**
  String financeBreakdownShare(String percent);

  /// No description provided for @financeHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get financeHistoryTitle;

  /// No description provided for @financeFilterTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get financeFilterTypeLabel;

  /// No description provided for @financeFilterCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get financeFilterCategoryLabel;

  /// No description provided for @financeClearFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get financeClearFiltersAction;

  /// No description provided for @financeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get financeEmptyTitle;

  /// No description provided for @financeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Record your income and spending to see where your money goes.'**
  String get financeEmptyMessage;

  /// No description provided for @financeNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching entries'**
  String get financeNoMatchTitle;

  /// No description provided for @financeNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'No entries match the filters you picked. Try a different period or category.'**
  String get financeNoMatchMessage;

  /// No description provided for @financeDeleteEntryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get financeDeleteEntryConfirmTitle;

  /// No description provided for @financeDeleteEntryConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your totals will update right away. You can undo this for a few seconds.'**
  String get financeDeleteEntryConfirmMessage;

  /// No description provided for @financeEntryDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get financeEntryDeletedMessage;

  /// No description provided for @financeUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get financeUndoAction;

  /// No description provided for @financeCategoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get financeCategoryRent;

  /// No description provided for @financeCategoryElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get financeCategoryElectricity;

  /// No description provided for @financeCategoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get financeCategoryWater;

  /// No description provided for @financeCategoryInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get financeCategoryInternet;

  /// No description provided for @financeCategoryPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get financeCategoryPhone;

  /// No description provided for @financeCategoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get financeCategoryGroceries;

  /// No description provided for @financeCategoryTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get financeCategoryTransportation;

  /// No description provided for @financeCategoryFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get financeCategoryFuel;

  /// No description provided for @financeCategoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get financeCategoryMedical;

  /// No description provided for @financeCategoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get financeCategoryEducation;

  /// No description provided for @financeCategoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get financeCategoryEntertainment;

  /// No description provided for @financeCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get financeCategoryShopping;

  /// No description provided for @financeCategoryRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get financeCategoryRestaurants;

  /// No description provided for @financeCategorySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get financeCategorySubscriptions;

  /// No description provided for @financeCategoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get financeCategoryFamily;

  /// No description provided for @financeCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get financeCategoryOther;

  /// No description provided for @financeCategorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get financeCategorySalary;

  /// No description provided for @financeCategoryFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get financeCategoryFreelance;

  /// No description provided for @financeCategoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get financeCategoryBusiness;

  /// No description provided for @financeCategoryBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get financeCategoryBonus;

  /// No description provided for @financeCategoryGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get financeCategoryGift;

  /// No description provided for @financeCategoryOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get financeCategoryOtherIncome;

  /// No description provided for @occasionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Occasions'**
  String get occasionsTitle;

  /// No description provided for @occasionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No occasions yet'**
  String get occasionsEmptyTitle;

  /// No description provided for @occasionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Weddings, engagements, birthdays, sebou celebrations, condolences — create an occasion to record who gave or received money at it.'**
  String get occasionsEmptyMessage;

  /// No description provided for @occasionAddAction.
  ///
  /// In en, this message translates to:
  /// **'New occasion'**
  String get occasionAddAction;

  /// No description provided for @occasionAddFirstAction.
  ///
  /// In en, this message translates to:
  /// **'Create your first occasion'**
  String get occasionAddFirstAction;

  /// No description provided for @occasionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search occasions'**
  String get occasionSearchHint;

  /// No description provided for @occasionFilterTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get occasionFilterTypeLabel;

  /// No description provided for @occasionFilterAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get occasionFilterAllTypes;

  /// No description provided for @occasionFilterDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get occasionFilterDateRangeLabel;

  /// No description provided for @occasionFilterDateFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get occasionFilterDateFromLabel;

  /// No description provided for @occasionFilterDateToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get occasionFilterDateToLabel;

  /// No description provided for @occasionFilterAllDates.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get occasionFilterAllDates;

  /// No description provided for @occasionClearFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get occasionClearFiltersAction;

  /// No description provided for @occasionNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching occasions'**
  String get occasionNoMatchTitle;

  /// No description provided for @occasionNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'No occasions match your search or filters. Try a different name, type, or date range.'**
  String get occasionNoMatchMessage;

  /// No description provided for @occasionArchivedAction.
  ///
  /// In en, this message translates to:
  /// **'Archived occasions'**
  String get occasionArchivedAction;

  /// No description provided for @occasionArchivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived occasions'**
  String get occasionArchivedTitle;

  /// No description provided for @occasionArchivedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No archived occasions'**
  String get occasionArchivedEmptyTitle;

  /// No description provided for @occasionArchivedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Occasions you archive will appear here, with their contributions and balances intact.'**
  String get occasionArchivedEmptyMessage;

  /// No description provided for @occasionArchivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get occasionArchivedLabel;

  /// No description provided for @occasionUpcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get occasionUpcomingLabel;

  /// No description provided for @occasionTypeWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get occasionTypeWedding;

  /// No description provided for @occasionTypeEngagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get occasionTypeEngagement;

  /// No description provided for @occasionTypeBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get occasionTypeBirthday;

  /// No description provided for @occasionTypeNewbornSebou.
  ///
  /// In en, this message translates to:
  /// **'Newborn (Sebou)'**
  String get occasionTypeNewbornSebou;

  /// No description provided for @occasionTypeCondolence.
  ///
  /// In en, this message translates to:
  /// **'Condolence'**
  String get occasionTypeCondolence;

  /// No description provided for @occasionTypeCelebration.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get occasionTypeCelebration;

  /// No description provided for @occasionTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get occasionTypeOther;

  /// No description provided for @occasionTypeCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom type'**
  String get occasionTypeCustomLabel;

  /// No description provided for @occasionTypeCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Write your own type, e.g. graduation'**
  String get occasionTypeCustomHint;

  /// No description provided for @occasionFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New occasion'**
  String get occasionFormCreateTitle;

  /// No description provided for @occasionFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit occasion'**
  String get occasionFormEditTitle;

  /// No description provided for @occasionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Occasion name'**
  String get occasionNameLabel;

  /// No description provided for @occasionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed\'s wedding'**
  String get occasionNameHint;

  /// No description provided for @occasionNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Occasion name is required'**
  String get occasionNameRequiredError;

  /// No description provided for @occasionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get occasionDateLabel;

  /// No description provided for @occasionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get occasionTypeLabel;

  /// No description provided for @occasionTypeRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Choose an occasion type'**
  String get occasionTypeRequiredError;

  /// No description provided for @occasionNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get occasionNotesLabel;

  /// No description provided for @occasionCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create occasion'**
  String get occasionCreateAction;

  /// No description provided for @occasionUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get occasionUpdateAction;

  /// No description provided for @occasionEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit occasion'**
  String get occasionEditAction;

  /// No description provided for @occasionDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete occasion'**
  String get occasionDeleteAction;

  /// No description provided for @occasionArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive occasion'**
  String get occasionArchiveAction;

  /// No description provided for @occasionRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore occasion'**
  String get occasionRestoreAction;

  /// No description provided for @occasionParticipantFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get occasionParticipantFormAddTitle;

  /// No description provided for @occasionParticipantFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit contribution'**
  String get occasionParticipantFormEditTitle;

  /// No description provided for @occasionParticipantPersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get occasionParticipantPersonLabel;

  /// No description provided for @occasionParticipantAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (EGP)'**
  String get occasionParticipantAmountLabel;

  /// No description provided for @occasionParticipantAmountInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero'**
  String get occasionParticipantAmountInvalidError;

  /// No description provided for @occasionParticipantDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get occasionParticipantDirectionLabel;

  /// No description provided for @occasionParticipantDirectionReceived.
  ///
  /// In en, this message translates to:
  /// **'I received from them'**
  String get occasionParticipantDirectionReceived;

  /// No description provided for @occasionParticipantDirectionGiven.
  ///
  /// In en, this message translates to:
  /// **'I gave them'**
  String get occasionParticipantDirectionGiven;

  /// No description provided for @occasionParticipantNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get occasionParticipantNoteLabel;

  /// No description provided for @occasionParticipantCountsTowardBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Counts toward their balance'**
  String get occasionParticipantCountsTowardBalanceLabel;

  /// No description provided for @occasionParticipantCountsTowardBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Condolence money isn\'t expected to be paid back, so it stays out of the balance by default. Turn this on to count it like any other exchange.'**
  String get occasionParticipantCountsTowardBalanceHint;

  /// No description provided for @occasionParticipantSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save participant'**
  String get occasionParticipantSaveAction;

  /// No description provided for @occasionParticipantUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get occasionParticipantUpdateAction;

  /// No description provided for @occasionDetailTotalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total received'**
  String get occasionDetailTotalReceived;

  /// No description provided for @occasionDetailTotalGiven.
  ///
  /// In en, this message translates to:
  /// **'Total given'**
  String get occasionDetailTotalGiven;

  /// No description provided for @occasionDetailNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get occasionDetailNet;

  /// No description provided for @occasionSettlementSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get occasionSettlementSettled;

  /// No description provided for @occasionSettlementMoreReceived.
  ///
  /// In en, this message translates to:
  /// **'{amount} more received than given'**
  String occasionSettlementMoreReceived(String amount);

  /// No description provided for @occasionSettlementMoreGiven.
  ///
  /// In en, this message translates to:
  /// **'{amount} more given than received'**
  String occasionSettlementMoreGiven(String amount);

  /// No description provided for @occasionParticipantsHeader.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get occasionParticipantsHeader;

  /// No description provided for @occasionParticipantsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get occasionParticipantsEmptyTitle;

  /// No description provided for @occasionParticipantsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the first person who gave or received money at this occasion.'**
  String get occasionParticipantsEmptyMessage;

  /// No description provided for @occasionAddParticipantAction.
  ///
  /// In en, this message translates to:
  /// **'Add participant'**
  String get occasionAddParticipantAction;

  /// No description provided for @occasionEditParticipantAction.
  ///
  /// In en, this message translates to:
  /// **'Edit contribution'**
  String get occasionEditParticipantAction;

  /// No description provided for @occasionRemoveParticipantAction.
  ///
  /// In en, this message translates to:
  /// **'Remove contribution'**
  String get occasionRemoveParticipantAction;

  /// No description provided for @occasionContributionBadge.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get occasionContributionBadge;

  /// No description provided for @occasionRemoveParticipantConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this contribution?'**
  String get occasionRemoveParticipantConfirmTitle;

  /// No description provided for @occasionRemoveParticipantConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'It will also disappear from this person\'s history and balance. This can\'t be undone.'**
  String get occasionRemoveParticipantConfirmMessage;

  /// No description provided for @occasionDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this occasion?'**
  String get occasionDeleteConfirmTitle;

  /// No description provided for @occasionDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{This occasion has no contributions recorded yet. This can\'t be undone.} =1{This also removes 1 contribution and updates that person\'s balance. This can\'t be undone.} other{This also removes {count} contributions and updates the balance of everyone who took part. This can\'t be undone.}}'**
  String occasionDeleteConfirmMessage(int count);

  /// No description provided for @occasionArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this occasion?'**
  String get occasionArchiveConfirmTitle;

  /// No description provided for @occasionArchiveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'It moves to archived occasions. Its contributions stay in everyone\'s history and balances, and you can restore it any time.'**
  String get occasionArchiveConfirmMessage;

  /// No description provided for @occasionRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this occasion?'**
  String get occasionRestoreConfirmTitle;

  /// No description provided for @occasionRestoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'It will appear in your occasions list again.'**
  String get occasionRestoreConfirmMessage;

  /// No description provided for @occasionAttachmentsHeader.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get occasionAttachmentsHeader;

  /// No description provided for @occasionAttachPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get occasionAttachPhotoAction;

  /// No description provided for @occasionAttachFromCameraAction.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get occasionAttachFromCameraAction;

  /// No description provided for @occasionAttachFromGalleryAction.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get occasionAttachFromGalleryAction;

  /// No description provided for @occasionAttachmentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get occasionAttachmentsEmptyTitle;

  /// No description provided for @occasionAttachmentsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Attach a photo of the envelope list, the invitation, or the occasion itself to keep it with this record.'**
  String get occasionAttachmentsEmptyMessage;

  /// No description provided for @occasionRemoveAttachmentAction.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get occasionRemoveAttachmentAction;

  /// No description provided for @occasionRemoveAttachmentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo?'**
  String get occasionRemoveAttachmentConfirmTitle;

  /// No description provided for @occasionRemoveAttachmentConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The photo will be deleted from this occasion. This can\'t be undone.'**
  String get occasionRemoveAttachmentConfirmMessage;

  /// No description provided for @occasionCameraPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off'**
  String get occasionCameraPermissionDeniedTitle;

  /// No description provided for @occasionCameraPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Daftary needs your camera to take a photo for this occasion. Open your device settings and allow camera access for Daftary, or choose a photo from your gallery instead.'**
  String get occasionCameraPermissionDeniedMessage;

  /// No description provided for @occasionPhotoLibraryPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo access is turned off'**
  String get occasionPhotoLibraryPermissionDeniedTitle;

  /// No description provided for @occasionPhotoLibraryPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Daftary needs access to your photos to attach one to this occasion. Open your device settings and allow photo access for Daftary, or take a new photo with the camera instead.'**
  String get occasionPhotoLibraryPermissionDeniedMessage;

  /// No description provided for @occasionOpenSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get occasionOpenSettingsAction;

  /// No description provided for @ocrCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan paper'**
  String get ocrCaptureTitle;

  /// No description provided for @ocrCaptureHeadline.
  ///
  /// In en, this message translates to:
  /// **'Turn a paper list into entries'**
  String get ocrCaptureHeadline;

  /// No description provided for @ocrCaptureMessage.
  ///
  /// In en, this message translates to:
  /// **'Photograph a list of names and amounts. Everything is read on this device, and nothing is saved until you review it.'**
  String get ocrCaptureMessage;

  /// No description provided for @ocrCaptureTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get ocrCaptureTakePhoto;

  /// No description provided for @ocrCaptureChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get ocrCaptureChooseFromGallery;

  /// No description provided for @ocrCaptureUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanning isn\'t available on this device'**
  String get ocrCaptureUnsupportedTitle;

  /// No description provided for @ocrCaptureUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t run on-device text recognition, so scanning a paper won\'t work here. You can still add transactions manually.'**
  String get ocrCaptureUnsupportedMessage;

  /// No description provided for @ocrCaptureEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get ocrCaptureEnterManually;

  /// No description provided for @ocrPrepTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare the image'**
  String get ocrPrepTitle;

  /// No description provided for @ocrPrepHint.
  ///
  /// In en, this message translates to:
  /// **'Crop to just the list of names and amounts, then even out the lighting for the best reading.'**
  String get ocrPrepHint;

  /// No description provided for @ocrPrepCropRotate.
  ///
  /// In en, this message translates to:
  /// **'Crop and rotate'**
  String get ocrPrepCropRotate;

  /// No description provided for @ocrPrepRecrop.
  ///
  /// In en, this message translates to:
  /// **'Redo the crop'**
  String get ocrPrepRecrop;

  /// No description provided for @ocrPrepEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get ocrPrepEnhance;

  /// No description provided for @ocrPrepEnhanceAgain.
  ///
  /// In en, this message translates to:
  /// **'Enhance again'**
  String get ocrPrepEnhanceAgain;

  /// No description provided for @ocrPrepProcess.
  ///
  /// In en, this message translates to:
  /// **'Read the paper'**
  String get ocrPrepProcess;

  /// No description provided for @ocrPrepProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading your paper'**
  String get ocrPrepProcessingTitle;

  /// No description provided for @ocrPrepProcessingMessage.
  ///
  /// In en, this message translates to:
  /// **'Text recognition is running on this device. Nothing is uploaded anywhere.'**
  String get ocrPrepProcessingMessage;

  /// No description provided for @ocrPrepCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ocrPrepCancel;

  /// No description provided for @ocrPrepInterruptedTitle.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t finish'**
  String get ocrPrepInterruptedTitle;

  /// No description provided for @ocrPrepInterruptedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reading stopped before it finished, probably because the app was interrupted. Nothing was saved, so you can try again.'**
  String get ocrPrepInterruptedMessage;

  /// No description provided for @ocrPrepRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get ocrPrepRetry;

  /// No description provided for @ocrPrepDefaultDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Default direction for this list'**
  String get ocrPrepDefaultDirectionLabel;

  /// No description provided for @ocrPrepDefaultDirectionHint.
  ///
  /// In en, this message translates to:
  /// **'Applied to every entry whose direction can\'t be read from the paper. You can change any entry while reviewing.'**
  String get ocrPrepDefaultDirectionHint;

  /// No description provided for @ocrPrepDirectionReceived.
  ///
  /// In en, this message translates to:
  /// **'Money received'**
  String get ocrPrepDirectionReceived;

  /// No description provided for @ocrPrepDirectionGiven.
  ///
  /// In en, this message translates to:
  /// **'Money given'**
  String get ocrPrepDirectionGiven;

  /// No description provided for @ocrFailureNoTextTitle.
  ///
  /// In en, this message translates to:
  /// **'No text found'**
  String get ocrFailureNoTextTitle;

  /// No description provided for @ocrFailureNoTextMessage.
  ///
  /// In en, this message translates to:
  /// **'No readable text was found in this photo. A sharper, better lit, straight-on shot usually fixes it.'**
  String get ocrFailureNoTextMessage;

  /// No description provided for @ocrFailureNoCandidatesTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries could be made'**
  String get ocrFailureNoCandidatesTitle;

  /// No description provided for @ocrFailureNoCandidatesMessage.
  ///
  /// In en, this message translates to:
  /// **'Text was found, but no line looked like a name and an amount. Try cropping to just the list, or enter the entries manually.'**
  String get ocrFailureNoCandidatesMessage;

  /// No description provided for @ocrFailurePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get ocrFailurePermissionTitle;

  /// No description provided for @ocrFailurePermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Scanning needs access to your camera or photos to read the paper. Grant access from the app\'s settings, then try again.'**
  String get ocrFailurePermissionMessage;

  /// No description provided for @ocrFailureUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanning isn\'t available on this device'**
  String get ocrFailureUnsupportedTitle;

  /// No description provided for @ocrFailureUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t run on-device text recognition. Manual entry works exactly the same way.'**
  String get ocrFailureUnsupportedMessage;

  /// No description provided for @ocrFailureGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'The scan didn\'t work'**
  String get ocrFailureGenericTitle;

  /// No description provided for @ocrFailureGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading the paper. Nothing was saved, so you can try again or enter the entries manually.'**
  String get ocrFailureGenericMessage;

  /// No description provided for @ocrFailureRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake the photo'**
  String get ocrFailureRetakePhoto;

  /// No description provided for @ocrFailureRecrop.
  ///
  /// In en, this message translates to:
  /// **'Adjust the crop and retry'**
  String get ocrFailureRecrop;

  /// No description provided for @ocrFailureManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get ocrFailureManualEntry;

  /// No description provided for @ocrFailureOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get ocrFailureOpenSettings;

  /// No description provided for @ocrConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get ocrConfidenceLow;

  /// No description provided for @ocrConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence'**
  String get ocrConfidenceMedium;

  /// No description provided for @ocrConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get ocrConfidenceHigh;

  /// No description provided for @ocrConfidenceInferred.
  ///
  /// In en, this message translates to:
  /// **'Inferred, not read'**
  String get ocrConfidenceInferred;

  /// No description provided for @ocrReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review entries'**
  String get ocrReviewTitle;

  /// No description provided for @ocrReviewBatchSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Applies to the whole batch'**
  String get ocrReviewBatchSectionTitle;

  /// No description provided for @ocrReviewBatchSectionMessage.
  ///
  /// In en, this message translates to:
  /// **'These choices apply to every entry that does not have its own. Nothing is saved until you confirm.'**
  String get ocrReviewBatchSectionMessage;

  /// No description provided for @ocrReviewBatchDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Default direction'**
  String get ocrReviewBatchDirectionLabel;

  /// No description provided for @ocrReviewDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get ocrReviewDirectionLabel;

  /// No description provided for @ocrReviewDirectionReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get ocrReviewDirectionReceived;

  /// No description provided for @ocrReviewDirectionGiven.
  ///
  /// In en, this message translates to:
  /// **'Given'**
  String get ocrReviewDirectionGiven;

  /// No description provided for @ocrReviewDirectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a direction for this entry, or set a default for the batch.'**
  String get ocrReviewDirectionRequired;

  /// No description provided for @ocrReviewPersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get ocrReviewPersonLabel;

  /// No description provided for @ocrReviewPersonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the person\'s name.'**
  String get ocrReviewPersonRequired;

  /// No description provided for @ocrReviewDuplicateWarningAction.
  ///
  /// In en, this message translates to:
  /// **'Similar names already saved'**
  String get ocrReviewDuplicateWarningAction;

  /// No description provided for @ocrReviewAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get ocrReviewAmountLabel;

  /// No description provided for @ocrReviewAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get ocrReviewAmountRequired;

  /// No description provided for @ocrReviewAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount, for example 150.50'**
  String get ocrReviewAmountInvalid;

  /// No description provided for @ocrReviewDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get ocrReviewDateLabel;

  /// No description provided for @ocrReviewNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ocrReviewNotesLabel;

  /// No description provided for @ocrReviewRawTextAction.
  ///
  /// In en, this message translates to:
  /// **'Original text'**
  String get ocrReviewRawTextAction;

  /// No description provided for @ocrReviewRawTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Read from the page'**
  String get ocrReviewRawTextLabel;

  /// No description provided for @ocrReviewEditedBadge.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get ocrReviewEditedBadge;

  /// No description provided for @ocrReviewDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard this entry'**
  String get ocrReviewDiscardAction;

  /// No description provided for @ocrReviewIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Not ready to save'**
  String get ocrReviewIncompleteTitle;

  /// No description provided for @ocrReviewIncompleteBatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Some entries are still missing required details. Nothing was saved.'**
  String get ocrReviewIncompleteBatchMessage;

  /// No description provided for @ocrReviewConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm and save'**
  String get ocrReviewConfirmAction;

  /// No description provided for @ocrReviewConfirmBlockedHint.
  ///
  /// In en, this message translates to:
  /// **'Complete or discard the highlighted entries before saving.'**
  String get ocrReviewConfirmBlockedHint;

  /// No description provided for @ocrReviewNothingToConfirm.
  ///
  /// In en, this message translates to:
  /// **'There is nothing left to save in this scan.'**
  String get ocrReviewNothingToConfirm;

  /// No description provided for @ocrReviewCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel scan'**
  String get ocrReviewCancelAction;

  /// No description provided for @ocrReviewCancelPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your corrections?'**
  String get ocrReviewCancelPromptTitle;

  /// No description provided for @ocrReviewCancelPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'You have corrected some entries. Cancelling this scan discards that work and saves nothing.'**
  String get ocrReviewCancelPromptMessage;

  /// No description provided for @ocrReviewCancelPromptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard and cancel'**
  String get ocrReviewCancelPromptConfirm;

  /// No description provided for @ocrReviewCancelPromptKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep reviewing'**
  String get ocrReviewCancelPromptKeep;

  /// No description provided for @ocrReviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries left'**
  String get ocrReviewEmptyTitle;

  /// No description provided for @ocrReviewEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You discarded every entry from this scan. Cancel the scan, or go back and photograph the page again.'**
  String get ocrReviewEmptyMessage;

  /// No description provided for @ocrReviewLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not open this scan'**
  String get ocrReviewLoadErrorTitle;

  /// No description provided for @ocrReviewLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'The scan and its entries could not be loaded. Nothing was saved.'**
  String get ocrReviewLoadErrorMessage;

  /// No description provided for @ocrReviewRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get ocrReviewRetryAction;

  /// No description provided for @ocrReviewSaveErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'The entries could not be saved. Nothing was recorded, so you can try again safely.'**
  String get ocrReviewSaveErrorMessage;

  /// No description provided for @ocrReviewOccasionLabel.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get ocrReviewOccasionLabel;

  /// No description provided for @ocrReviewOccasionNone.
  ///
  /// In en, this message translates to:
  /// **'No occasion'**
  String get ocrReviewOccasionNone;

  /// No description provided for @ocrReviewOccasionClear.
  ///
  /// In en, this message translates to:
  /// **'Remove the occasion tag'**
  String get ocrReviewOccasionClear;

  /// No description provided for @ocrReviewOccasionPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag this batch to an occasion'**
  String get ocrReviewOccasionPickerTitle;

  /// No description provided for @ocrReviewOccasionEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no occasions yet. Create one from the Occasions screen first.'**
  String get ocrReviewOccasionEmpty;

  /// No description provided for @ocrHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan history'**
  String get ocrHistoryTitle;

  /// No description provided for @ocrHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get ocrHistoryEmptyTitle;

  /// No description provided for @ocrHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Once you scan a paper list, every scan you keep shows up here with its photo and what came of it.'**
  String get ocrHistoryEmptyMessage;

  /// No description provided for @ocrHistoryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your scans'**
  String get ocrHistoryErrorTitle;

  /// No description provided for @ocrHistoryErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading your scan history. Try again.'**
  String get ocrHistoryErrorMessage;

  /// No description provided for @ocrHistoryStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get ocrHistoryStatusProcessing;

  /// No description provided for @ocrHistoryStatusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get ocrHistoryStatusNeedsReview;

  /// No description provided for @ocrHistoryStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ocrHistoryStatusConfirmed;

  /// No description provided for @ocrHistoryStatusDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Produced nothing'**
  String get ocrHistoryStatusDiscarded;

  /// No description provided for @ocrHistoryStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Nothing could be read'**
  String get ocrHistoryStatusFailed;

  /// No description provided for @ocrHistoryConfirmedEntries.
  ///
  /// In en, this message translates to:
  /// **'{count} entries confirmed'**
  String ocrHistoryConfirmedEntries(Object count);

  /// No description provided for @ocrHistoryDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete scan'**
  String get ocrHistoryDeleteAction;

  /// No description provided for @ocrHistoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this scan?'**
  String get ocrHistoryDeleteTitle;

  /// No description provided for @ocrHistoryDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletes the scan and its photo from your device. The transactions it created are not deleted and stay in your records.'**
  String get ocrHistoryDeleteMessage;

  /// No description provided for @ocrHistoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete scan'**
  String get ocrHistoryDeleteConfirm;

  /// No description provided for @ocrScanDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan details'**
  String get ocrScanDetailTitle;

  /// No description provided for @ocrScanDetailImageMissing.
  ///
  /// In en, this message translates to:
  /// **'The photo for this scan is no longer on your device.'**
  String get ocrScanDetailImageMissing;

  /// No description provided for @ocrScanDetailEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Entries read from the paper'**
  String get ocrScanDetailEntriesTitle;

  /// No description provided for @ocrScanDetailNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries were read from this scan.'**
  String get ocrScanDetailNoEntries;

  /// No description provided for @ocrScanDetailUnknownPerson.
  ///
  /// In en, this message translates to:
  /// **'No name read'**
  String get ocrScanDetailUnknownPerson;

  /// No description provided for @ocrScanDetailNoAmount.
  ///
  /// In en, this message translates to:
  /// **'No amount read'**
  String get ocrScanDetailNoAmount;

  /// No description provided for @ocrScanDetailEntryStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Not reviewed'**
  String get ocrScanDetailEntryStatusPending;

  /// No description provided for @ocrScanDetailEntryStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ocrScanDetailEntryStatusConfirmed;

  /// No description provided for @ocrScanDetailEntryStatusDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded'**
  String get ocrScanDetailEntryStatusDiscarded;

  /// No description provided for @ocrScanDetailTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions created'**
  String get ocrScanDetailTransactionsTitle;

  /// No description provided for @ocrScanDetailNoTransactionsMessage.
  ///
  /// In en, this message translates to:
  /// **'This scan created no transactions.'**
  String get ocrScanDetailNoTransactionsMessage;

  /// No description provided for @ocrScanDetailTransactionsKeptNote.
  ///
  /// In en, this message translates to:
  /// **'These are real transactions in your records. Deleting this scan does not delete them.'**
  String get ocrScanDetailTransactionsKeptNote;

  /// No description provided for @ocrScanDetailDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete scan'**
  String get ocrScanDetailDeleteAction;

  /// No description provided for @ocrScanDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this scan?'**
  String get ocrScanDetailDeleteTitle;

  /// No description provided for @ocrScanDetailDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletes the scan and its photo from your device. The {count} transactions it created are not deleted and stay in your records — you just lose the link back to the original photo.'**
  String ocrScanDetailDeleteMessage(Object count);

  /// No description provided for @ocrScanDetailDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete scan'**
  String get ocrScanDetailDeleteConfirm;

  /// No description provided for @ocrScanDetailDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan deleted. Its transactions were kept.'**
  String get ocrScanDetailDeletedMessage;

  /// No description provided for @ocrScanDetailErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this scan'**
  String get ocrScanDetailErrorTitle;

  /// No description provided for @ocrScanDetailErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading this scan.'**
  String get ocrScanDetailErrorMessage;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @budgetsOverviewEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan this month\'s spending by category'**
  String get budgetsOverviewEntrySubtitle;

  /// No description provided for @budgetFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetFormCreateTitle;

  /// No description provided for @budgetFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetFormEditTitle;

  /// No description provided for @budgetFormMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get budgetFormMonthLabel;

  /// No description provided for @budgetExpectedIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected income (optional)'**
  String get budgetExpectedIncomeLabel;

  /// No description provided for @budgetExpectedIncomeHelp.
  ///
  /// In en, this message translates to:
  /// **'For reference only — it never changes how spending is tracked.'**
  String get budgetExpectedIncomeHelp;

  /// No description provided for @budgetAllocationsHeader.
  ///
  /// In en, this message translates to:
  /// **'Planned spending by category'**
  String get budgetAllocationsHeader;

  /// No description provided for @budgetAllocationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Pick an expense category below to start planning.'**
  String get budgetAllocationsEmpty;

  /// No description provided for @budgetAddCategoryHeader.
  ///
  /// In en, this message translates to:
  /// **'Add a category'**
  String get budgetAddCategoryHeader;

  /// No description provided for @budgetAllCategoriesAdded.
  ///
  /// In en, this message translates to:
  /// **'Every active expense category is already in this budget.'**
  String get budgetAllCategoriesAdded;

  /// No description provided for @budgetPlannedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned amount'**
  String get budgetPlannedAmountLabel;

  /// No description provided for @budgetRemoveAllocationAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from budget'**
  String get budgetRemoveAllocationAction;

  /// No description provided for @budgetAmountRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter a planned amount (0 is allowed)'**
  String get budgetAmountRequiredError;

  /// No description provided for @budgetAmountInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get budgetAmountInvalidError;

  /// No description provided for @budgetAmountNegativeError.
  ///
  /// In en, this message translates to:
  /// **'The amount can\'t be negative'**
  String get budgetAmountNegativeError;

  /// No description provided for @budgetTotalPlannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Total planned'**
  String get budgetTotalPlannedLabel;

  /// No description provided for @budgetExceedsIncomeWarning.
  ///
  /// In en, this message translates to:
  /// **'Planned spending exceeds expected income by {amount}'**
  String budgetExceedsIncomeWarning(String amount);

  /// No description provided for @budgetExceedsIncomeSaveNote.
  ///
  /// In en, this message translates to:
  /// **'You can still save this budget.'**
  String get budgetExceedsIncomeSaveNote;

  /// No description provided for @budgetDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get budgetDeleteAction;

  /// No description provided for @budgetDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this budget?'**
  String get budgetDeleteConfirmTitle;

  /// No description provided for @budgetDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The plan for {month} will be removed. Your recorded expenses are not affected.'**
  String budgetDeleteConfirmMessage(String month);

  /// No description provided for @budgetDeletedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted'**
  String get budgetDeletedConfirmation;

  /// No description provided for @budgetAlreadyExistsError.
  ///
  /// In en, this message translates to:
  /// **'This month already has a budget. Open it to make changes.'**
  String get budgetAlreadyExistsError;

  /// No description provided for @budgetDuplicateCategoryError.
  ///
  /// In en, this message translates to:
  /// **'This category is already in the budget.'**
  String get budgetDuplicateCategoryError;

  /// No description provided for @budgetNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'This budget no longer exists.'**
  String get budgetNotFoundError;

  /// No description provided for @budgetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No budget for {month}'**
  String budgetEmptyTitle(String month);

  /// No description provided for @budgetEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Plan how much you intend to spend in each category, then track it against your real expenses.'**
  String get budgetEmptyMessage;

  /// No description provided for @budgetCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get budgetCreateAction;

  /// No description provided for @budgetLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this budget'**
  String get budgetLoadErrorTitle;

  /// No description provided for @budgetOverallTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get budgetOverallTitle;

  /// No description provided for @budgetPlannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get budgetPlannedLabel;

  /// No description provided for @budgetActualLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetActualLabel;

  /// No description provided for @budgetRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetRemainingLabel;

  /// No description provided for @budgetOverByLabel.
  ///
  /// In en, this message translates to:
  /// **'Over by'**
  String get budgetOverByLabel;

  /// No description provided for @budgetSpentOfPlanned.
  ///
  /// In en, this message translates to:
  /// **'{actual} of {planned}'**
  String budgetSpentOfPlanned(String actual, String planned);

  /// No description provided for @budgetRemainingAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String budgetRemainingAmount(String amount);

  /// No description provided for @budgetOverByAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String budgetOverByAmount(String amount);

  /// No description provided for @budgetPercentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String budgetPercentUsed(int percent);

  /// No description provided for @budgetPercentNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get budgetPercentNotApplicable;

  /// No description provided for @budgetStatusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get budgetStatusOnTrack;

  /// No description provided for @budgetStatusNearFull.
  ///
  /// In en, this message translates to:
  /// **'Near limit'**
  String get budgetStatusNearFull;

  /// No description provided for @budgetStatusOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get budgetStatusOverBudget;

  /// No description provided for @budgetCategoryArchivedTag.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get budgetCategoryArchivedTag;

  /// No description provided for @budgetCategoryMissingName.
  ///
  /// In en, this message translates to:
  /// **'Deleted category'**
  String get budgetCategoryMissingName;

  /// No description provided for @budgetCategoriesHeader.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get budgetCategoriesHeader;

  /// No description provided for @budgetNoAllocationsMessage.
  ///
  /// In en, this message translates to:
  /// **'This budget has no categories yet. Edit it to add planned amounts.'**
  String get budgetNoAllocationsMessage;

  /// No description provided for @budgetExpectedIncomeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Expected income'**
  String get budgetExpectedIncomeDisplay;

  /// No description provided for @budgetUnbudgetedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unbudgeted spending'**
  String get budgetUnbudgetedTitle;

  /// No description provided for @budgetUnbudgetedMessage.
  ///
  /// In en, this message translates to:
  /// **'Spent this month in categories that aren\'t in your budget.'**
  String get budgetUnbudgetedMessage;

  /// No description provided for @budgetUnbudgetedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total unbudgeted'**
  String get budgetUnbudgetedTotalLabel;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeFinancialSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial snapshot'**
  String get homeFinancialSnapshotTitle;

  /// No description provided for @homeFinanceThisMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get homeFinanceThisMonthTitle;

  /// No description provided for @homeFinanceIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get homeFinanceIncome;

  /// No description provided for @homeFinanceExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get homeFinanceExpenses;

  /// No description provided for @homeFinanceNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get homeFinanceNet;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActionsTitle;

  /// No description provided for @homeQuickAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get homeQuickAddExpense;

  /// No description provided for @homeQuickAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get homeQuickAddIncome;

  /// No description provided for @homeQuickAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get homeQuickAddPerson;

  /// No description provided for @homeQuickMoneyReceived.
  ///
  /// In en, this message translates to:
  /// **'Money received'**
  String get homeQuickMoneyReceived;

  /// No description provided for @homeQuickMoneyGiven.
  ///
  /// In en, this message translates to:
  /// **'Money given'**
  String get homeQuickMoneyGiven;

  /// No description provided for @homeQuickAddOccasion.
  ///
  /// In en, this message translates to:
  /// **'Add occasion'**
  String get homeQuickAddOccasion;

  /// No description provided for @homeQuickScanPaper.
  ///
  /// In en, this message translates to:
  /// **'Scan paper'**
  String get homeQuickScanPaper;

  /// No description provided for @homeSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get homeSectionsTitle;

  /// No description provided for @homeInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get homeInsightsTitle;

  /// No description provided for @homeInsightsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Insights will appear here once the AI Assistant is set up.'**
  String get homeInsightsPlaceholder;

  /// No description provided for @homeUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get homeUpcomingTitle;

  /// No description provided for @homeUpcomingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bills and savings-goal milestones will appear here once reminders and savings goals are available.'**
  String get homeUpcomingPlaceholder;

  /// No description provided for @homeOverviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your balances.'**
  String get homeOverviewLoadError;

  /// No description provided for @homeFinanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this month\'s income and expenses.'**
  String get homeFinanceLoadError;

  /// No description provided for @homeFullErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard couldn\'t be loaded. Please try again.'**
  String get homeFullErrorMessage;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Daftary'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep track of who owes you, what you owe, and where your money goes each month — all on your device.'**
  String get homeEmptyMessage;

  /// No description provided for @homeEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add your first person'**
  String get homeEmptyAction;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsOpenAction;

  /// No description provided for @reportsTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly trend'**
  String get reportsTrendTitle;

  /// No description provided for @reportsTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Income and expenses over the last {months} months'**
  String reportsTrendSubtitle(int months);

  /// No description provided for @reportsBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get reportsBreakdownTitle;

  /// No description provided for @reportsIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportsIncome;

  /// No description provided for @reportsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportsExpenses;

  /// No description provided for @reportsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get reportsNet;

  /// No description provided for @reportsPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reportsPeriodThisMonth;

  /// No description provided for @reportsPeriodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get reportsPeriodLastMonth;

  /// No description provided for @reportsPeriodLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get reportsPeriodLast3Months;

  /// No description provided for @reportsPeriodLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get reportsPeriodLast6Months;

  /// No description provided for @reportsBreakdownEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded for this period.'**
  String get reportsBreakdownEmpty;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Record your first income or expense to start seeing trends and category breakdowns.'**
  String get reportsEmptyMessage;

  /// No description provided for @reportsEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add an entry'**
  String get reportsEmptyAction;

  /// No description provided for @reportsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your reports couldn\'t be loaded. Please try again.'**
  String get reportsLoadError;

  /// No description provided for @reportsExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get reportsExportAction;

  /// No description provided for @reportsCategoryShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String reportsCategoryShare(String percent);

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportTitle;

  /// No description provided for @exportDescription.
  ///
  /// In en, this message translates to:
  /// **'Create one CSV file containing a complete copy of your data: people, transactions, income and expense entries, categories, and settings. The file is created on your device and you choose where to send it.'**
  String get exportDescription;

  /// No description provided for @exportGenerateAction.
  ///
  /// In en, this message translates to:
  /// **'Create export file'**
  String get exportGenerateAction;

  /// No description provided for @exportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Preparing your export…'**
  String get exportGenerating;

  /// No description provided for @exportReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your export is ready'**
  String get exportReadyTitle;

  /// No description provided for @exportReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} records were included.'**
  String exportReadyMessage(int count);

  /// No description provided for @exportShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share file'**
  String get exportShareAction;

  /// No description provided for @exportRegenerateAction.
  ///
  /// In en, this message translates to:
  /// **'Create a new export'**
  String get exportRegenerateAction;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Your export couldn\'t be created. No partial file was saved. Please try again.'**
  String get exportError;

  /// No description provided for @exportShareError.
  ///
  /// In en, this message translates to:
  /// **'The share sheet couldn\'t be opened. Please try again.'**
  String get exportShareError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settingsDataSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsDataSectionTitle;

  /// No description provided for @settingsExportTile.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get settingsExportTile;

  /// No description provided for @settingsDangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get settingsDangerZoneTitle;

  /// No description provided for @settingsDeleteDataTile.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get settingsDeleteDataTile;

  /// No description provided for @settingsDeleteDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase everything stored in Daftary'**
  String get settingsDeleteDataSubtitle;

  /// No description provided for @deleteDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get deleteDataTitle;

  /// No description provided for @deleteDataWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'This is permanent'**
  String get deleteDataWarningTitle;

  /// No description provided for @deleteDataWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all of your people, transactions, occasions, scans, income and expense entries, categories, budgets, and settings from this device. This cannot be undone. Consider exporting your data first.'**
  String get deleteDataWarningMessage;

  /// No description provided for @deleteDataExportFirstAction.
  ///
  /// In en, this message translates to:
  /// **'Export my data first'**
  String get deleteDataExportFirstAction;

  /// No description provided for @deleteDataConfirmPhrase.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteDataConfirmPhrase;

  /// No description provided for @deleteDataConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Type {phrase} to confirm'**
  String deleteDataConfirmLabel(String phrase);

  /// No description provided for @deleteDataConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'{phrase}'**
  String deleteDataConfirmHint(String phrase);

  /// No description provided for @deleteDataConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteDataConfirmAction;

  /// No description provided for @deleteDataCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteDataCancelAction;

  /// No description provided for @deleteDataInProgress.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data…'**
  String get deleteDataInProgress;

  /// No description provided for @deleteDataError.
  ///
  /// In en, this message translates to:
  /// **'Your data couldn\'t be deleted. Nothing was removed — all your data is still intact. Please try again.'**
  String get deleteDataError;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantHomeEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask questions about your own money. Off until you set it up.'**
  String get aiAssistantHomeEntrySubtitle;

  /// No description provided for @aiSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant settings'**
  String get aiSettingsTitle;

  /// No description provided for @aiSettingsIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'The assistant is off'**
  String get aiSettingsIntroTitle;

  /// No description provided for @aiSettingsIntroMessage.
  ///
  /// In en, this message translates to:
  /// **'To turn it on, choose your AI provider, enter your own API key, and review exactly what will be shared. Daftary never ships with a key of its own.'**
  String get aiSettingsIntroMessage;

  /// No description provided for @aiSettingsProviderSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiSettingsProviderSectionTitle;

  /// No description provided for @aiSettingsProviderCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom provider'**
  String get aiSettingsProviderCustom;

  /// No description provided for @aiSettingsCustomProviderHint.
  ///
  /// In en, this message translates to:
  /// **'Any provider with an OpenAI-compatible chat API that supports tool calling.'**
  String get aiSettingsCustomProviderHint;

  /// No description provided for @aiSettingsCustomBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'API base URL (https://…)'**
  String get aiSettingsCustomBaseUrlLabel;

  /// No description provided for @aiSettingsCustomModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get aiSettingsCustomModelLabel;

  /// No description provided for @aiSettingsApiKeySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get aiSettingsApiKeySectionTitle;

  /// No description provided for @aiSettingsApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Your API key'**
  String get aiSettingsApiKeyLabel;

  /// No description provided for @aiSettingsApiKeyNote.
  ///
  /// In en, this message translates to:
  /// **'Stored only in this device\'s secure storage and sent only to the provider you chose. It is never shown again after you save it.'**
  String get aiSettingsApiKeyNote;

  /// No description provided for @aiSettingsProviderRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider'**
  String get aiSettingsProviderRequired;

  /// No description provided for @aiSettingsCustomBaseUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a full address starting with https://'**
  String get aiSettingsCustomBaseUrlInvalid;

  /// No description provided for @aiSettingsCustomModelRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the model name'**
  String get aiSettingsCustomModelRequired;

  /// No description provided for @aiSettingsApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your API key'**
  String get aiSettingsApiKeyRequired;

  /// No description provided for @aiSettingsApiKeyMalformed.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like a complete API key'**
  String get aiSettingsApiKeyMalformed;

  /// No description provided for @aiSettingsContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get aiSettingsContinueAction;

  /// No description provided for @aiSettingsEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'The assistant is on'**
  String get aiSettingsEnabledTitle;

  /// No description provided for @aiSettingsEnabledProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}'**
  String aiSettingsEnabledProvider(String provider);

  /// No description provided for @aiSettingsApiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key: saved securely (hidden)'**
  String get aiSettingsApiKeySaved;

  /// No description provided for @aiSettingsConsentAcceptedOn.
  ///
  /// In en, this message translates to:
  /// **'Data-sharing disclosure accepted on {date}'**
  String aiSettingsConsentAcceptedOn(String date);

  /// No description provided for @aiSettingsChangeCredentialsAction.
  ///
  /// In en, this message translates to:
  /// **'Change provider or key'**
  String get aiSettingsChangeCredentialsAction;

  /// No description provided for @aiSettingsChangeCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Change provider or key'**
  String get aiSettingsChangeCredentialsTitle;

  /// No description provided for @aiSettingsChangeCredentialsMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the new key. The key saved now will be discarded once the new one is saved.'**
  String get aiSettingsChangeCredentialsMessage;

  /// No description provided for @aiSettingsSaveCredentialsAction.
  ///
  /// In en, this message translates to:
  /// **'Save new key'**
  String get aiSettingsSaveCredentialsAction;

  /// No description provided for @aiSettingsCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get aiSettingsCancelAction;

  /// No description provided for @aiSettingsDisableAction.
  ///
  /// In en, this message translates to:
  /// **'Turn off assistant'**
  String get aiSettingsDisableAction;

  /// No description provided for @aiSettingsDisableConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off the assistant?'**
  String get aiSettingsDisableConfirmTitle;

  /// No description provided for @aiSettingsDisableConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing more will be sent to your AI provider. Your saved API key will be deleted from this device, so turning the assistant back on means entering a key and accepting the data-sharing disclosure again. Your conversation history is kept.'**
  String get aiSettingsDisableConfirmMessage;

  /// No description provided for @aiSettingsDisableConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get aiSettingsDisableConfirmAction;

  /// No description provided for @aiSettingsEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'AI assistant turned on'**
  String get aiSettingsEnabledMessage;

  /// No description provided for @aiSettingsCredentialsUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Provider and key updated. The previous key was discarded.'**
  String get aiSettingsCredentialsUpdatedMessage;

  /// No description provided for @aiSettingsDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'AI assistant turned off. Your API key was deleted from this device.'**
  String get aiSettingsDisabledMessage;

  /// No description provided for @aiSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your AI assistant settings couldn\'t be saved. Nothing was changed. Please try again.'**
  String get aiSettingsSaveFailed;

  /// No description provided for @aiSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'AI assistant settings couldn\'t be loaded.'**
  String get aiSettingsLoadFailed;

  /// No description provided for @aiSettingsCustomProviderName.
  ///
  /// In en, this message translates to:
  /// **'your custom provider ({host})'**
  String aiSettingsCustomProviderName(String host);

  /// No description provided for @aiConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you turn on the assistant'**
  String get aiConsentTitle;

  /// No description provided for @aiConsentIntro.
  ///
  /// In en, this message translates to:
  /// **'Here is exactly what happens when you ask the assistant a question:'**
  String get aiConsentIntro;

  /// No description provided for @aiConsentPointMinimal.
  ///
  /// In en, this message translates to:
  /// **'Only the small piece of data needed to answer that one question is sent — for example, one category\'s total for one month. Never a full copy of your records.'**
  String get aiConsentPointMinimal;

  /// No description provided for @aiConsentPointProviderOnly.
  ///
  /// In en, this message translates to:
  /// **'It goes only to {provider}, using your own key. Never to Daftary, and never to anyone else.'**
  String aiConsentPointProviderOnly(String provider);

  /// No description provided for @aiConsentPointOnDemand.
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent until you ask a question.'**
  String get aiConsentPointOnDemand;

  /// No description provided for @aiConsentPointReadOnly.
  ///
  /// In en, this message translates to:
  /// **'The assistant can only read and explain your figures. It can never add, change, or delete anything.'**
  String get aiConsentPointReadOnly;

  /// No description provided for @aiConsentPointCost.
  ///
  /// In en, this message translates to:
  /// **'Your provider may charge your account for each question.'**
  String get aiConsentPointCost;

  /// No description provided for @aiConsentPointDisable.
  ///
  /// In en, this message translates to:
  /// **'You can turn the assistant off at any time. That immediately stops anything more from being sent and deletes your key from this device.'**
  String get aiConsentPointDisable;

  /// No description provided for @aiConsentAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'I agree, turn it on'**
  String get aiConsentAcceptAction;

  /// No description provided for @aiConsentDeclineAction.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get aiConsentDeclineAction;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiChatTitle;

  /// No description provided for @aiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your spending, budgets, or balances…'**
  String get aiChatInputHint;

  /// No description provided for @aiChatSendAction.
  ///
  /// In en, this message translates to:
  /// **'Send question'**
  String get aiChatSendAction;

  /// No description provided for @aiChatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about your own money'**
  String get aiChatEmptyTitle;

  /// No description provided for @aiChatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'For example: \"How much did I spend on food this month?\" Answers come only from your own records in Daftary.'**
  String get aiChatEmptyMessage;

  /// No description provided for @aiChatClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get aiChatClearAction;

  /// No description provided for @aiChatClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear this conversation?'**
  String get aiChatClearConfirmTitle;

  /// No description provided for @aiChatClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All questions and answers will be deleted from this device. Your financial records won\'t be affected.'**
  String get aiChatClearConfirmMessage;

  /// No description provided for @aiChatClearConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get aiChatClearConfirmAction;

  /// No description provided for @aiChatClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Conversation cleared'**
  String get aiChatClearedMessage;

  /// No description provided for @aiChatClearFailed.
  ///
  /// In en, this message translates to:
  /// **'The conversation couldn\'t be cleared. Please try again.'**
  String get aiChatClearFailed;

  /// No description provided for @aiChatLoadEarlierAction.
  ///
  /// In en, this message translates to:
  /// **'Show earlier messages'**
  String get aiChatLoadEarlierAction;

  /// No description provided for @aiChatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your conversation couldn\'t be loaded.'**
  String get aiChatLoadFailed;

  /// No description provided for @aiChatTypingLabel.
  ///
  /// In en, this message translates to:
  /// **'The assistant is preparing an answer'**
  String get aiChatTypingLabel;

  /// No description provided for @aiChatYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get aiChatYouLabel;

  /// No description provided for @aiChatAssistantLabel.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get aiChatAssistantLabel;

  /// No description provided for @aiChatMessageFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get aiChatMessageFailedLabel;

  /// No description provided for @aiChatInterruptedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not answered: the assistant was turned off before a reply arrived'**
  String get aiChatInterruptedLabel;

  /// No description provided for @aiChatDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'The assistant is off'**
  String get aiChatDisabledTitle;

  /// No description provided for @aiChatDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in the assistant settings to start asking questions about your money.'**
  String get aiChatDisabledMessage;

  /// No description provided for @aiChatOpenSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get aiChatOpenSettingsAction;

  /// No description provided for @aiChatSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Assistant settings'**
  String get aiChatSettingsAction;

  /// No description provided for @aiChatReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'The assistant can only read and explain your figures. It can\'t add, change, or delete anything, so nothing was changed. You can do that yourself from the app.'**
  String get aiChatReadOnlyNotice;

  /// No description provided for @aiChatNothingChangedLabel.
  ///
  /// In en, this message translates to:
  /// **'Nothing in your records was changed'**
  String get aiChatNothingChangedLabel;

  /// No description provided for @aiFailureInvalidApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'API key not accepted'**
  String get aiFailureInvalidApiKeyTitle;

  /// No description provided for @aiFailureInvalidApiKeyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your provider rejected your API key. It may be wrong, expired, or revoked. Update it to keep asking questions.'**
  String get aiFailureInvalidApiKeyMessage;

  /// No description provided for @aiFailureRateLimitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get aiFailureRateLimitedTitle;

  /// No description provided for @aiFailureRateLimitedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your provider is limiting requests right now. Wait a minute or two, then try again.'**
  String get aiFailureRateLimitedMessage;

  /// No description provided for @aiFailureNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get aiFailureNetworkTitle;

  /// No description provided for @aiFailureNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'The assistant needs an internet connection. Everything else in Daftary keeps working offline.'**
  String get aiFailureNetworkMessage;

  /// No description provided for @aiFailureProviderErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider unavailable'**
  String get aiFailureProviderErrorTitle;

  /// No description provided for @aiFailureProviderErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Your AI provider is having a problem on its side. Please try again in a little while.'**
  String get aiFailureProviderErrorMessage;

  /// No description provided for @aiFailureUnrecognizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unexpected reply'**
  String get aiFailureUnrecognizedTitle;

  /// No description provided for @aiFailureUnrecognizedMessage.
  ///
  /// In en, this message translates to:
  /// **'The assistant\'s reply couldn\'t be understood. Please try asking again.'**
  String get aiFailureUnrecognizedMessage;

  /// No description provided for @aiFailureLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save'**
  String get aiFailureLocalTitle;

  /// No description provided for @aiFailureLocalMessage.
  ///
  /// In en, this message translates to:
  /// **'Your question couldn\'t be saved on this device. Please try again.'**
  String get aiFailureLocalMessage;

  /// No description provided for @aiFailureRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get aiFailureRetryAction;

  /// No description provided for @aiFailureUpdateKeyAction.
  ///
  /// In en, this message translates to:
  /// **'Update API key'**
  String get aiFailureUpdateKeyAction;

  /// No description provided for @aiObservationLabel.
  ///
  /// In en, this message translates to:
  /// **'Observation'**
  String get aiObservationLabel;

  /// No description provided for @aiObservationSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Observation from the assistant, based on your own records'**
  String get aiObservationSemanticLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
