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
