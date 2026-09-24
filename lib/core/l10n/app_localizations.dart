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

  /// No description provided for @finEduCalcCompoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Compound growth calculator'**
  String get finEduCalcCompoundTitle;

  /// No description provided for @finEduCalcCompoundIntro.
  ///
  /// In en, this message translates to:
  /// **'See how a fixed monthly amount could grow over time at a rate you choose, compounded monthly.'**
  String get finEduCalcCompoundIntro;

  /// No description provided for @finEduCalcDoublingTitle.
  ///
  /// In en, this message translates to:
  /// **'Doubling time calculator'**
  String get finEduCalcDoublingTitle;

  /// No description provided for @finEduCalcDoublingIntro.
  ///
  /// In en, this message translates to:
  /// **'Estimate roughly how many years it takes for money to double at a constant annual rate you choose.'**
  String get finEduCalcDoublingIntro;

  /// No description provided for @finEduCalcSavingsRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings rate calculator'**
  String get finEduCalcSavingsRateTitle;

  /// No description provided for @finEduCalcSavingsRateIntro.
  ///
  /// In en, this message translates to:
  /// **'Work out what share of an income is set aside, using figures you enter yourself.'**
  String get finEduCalcSavingsRateIntro;

  /// No description provided for @finEduCalcMonthlyContributionLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly amount (EGP)'**
  String get finEduCalcMonthlyContributionLabel;

  /// No description provided for @finEduCalcAnnualRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Annual growth rate (%)'**
  String get finEduCalcAnnualRateLabel;

  /// No description provided for @finEduCalcYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (years)'**
  String get finEduCalcYearsLabel;

  /// No description provided for @finEduCalcIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income (EGP)'**
  String get finEduCalcIncomeLabel;

  /// No description provided for @finEduCalcSavingsAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount saved (EGP)'**
  String get finEduCalcSavingsAmountLabel;

  /// No description provided for @finEduCalcCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get finEduCalcCalculate;

  /// No description provided for @finEduCalcPrefillFromSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Start from my savings goal\'s amount'**
  String get finEduCalcPrefillFromSavingsGoal;

  /// No description provided for @finEduCalcPrefillHint.
  ///
  /// In en, this message translates to:
  /// **'Only fills in the amount as a starting point — you can change it freely.'**
  String get finEduCalcPrefillHint;

  /// No description provided for @finEduCalcErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get finEduCalcErrorRequired;

  /// No description provided for @finEduCalcErrorInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get finEduCalcErrorInvalidNumber;

  /// No description provided for @finEduCalcErrorWholeYears.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of years'**
  String get finEduCalcErrorWholeYears;

  /// No description provided for @finEduCalcErrorAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get finEduCalcErrorAmountPositive;

  /// No description provided for @finEduCalcErrorRateNegative.
  ///
  /// In en, this message translates to:
  /// **'The rate can\'t be negative'**
  String get finEduCalcErrorRateNegative;

  /// No description provided for @finEduCalcErrorRatePositive.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate greater than zero — a doubling time isn\'t defined at 0%'**
  String get finEduCalcErrorRatePositive;

  /// No description provided for @finEduCalcErrorYearsPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter a duration of at least 1 year'**
  String get finEduCalcErrorYearsPositive;

  /// No description provided for @finEduCalcErrorIncomePositive.
  ///
  /// In en, this message translates to:
  /// **'Enter an income greater than zero'**
  String get finEduCalcErrorIncomePositive;

  /// No description provided for @finEduCalcErrorSavingsNegative.
  ///
  /// In en, this message translates to:
  /// **'The amount saved can\'t be negative'**
  String get finEduCalcErrorSavingsNegative;

  /// No description provided for @finEduCalcErrorResultTooLarge.
  ///
  /// In en, this message translates to:
  /// **'These inputs produce a figure too large to show. Try a smaller amount, rate, or duration.'**
  String get finEduCalcErrorResultTooLarge;

  /// No description provided for @finEduCalcResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get finEduCalcResultTitle;

  /// No description provided for @finEduCalcResultFutureValue.
  ///
  /// In en, this message translates to:
  /// **'Projected total'**
  String get finEduCalcResultFutureValue;

  /// No description provided for @finEduCalcResultTotalContributed.
  ///
  /// In en, this message translates to:
  /// **'Total contributed'**
  String get finEduCalcResultTotalContributed;

  /// No description provided for @finEduCalcResultTotalGrowth.
  ///
  /// In en, this message translates to:
  /// **'Total growth'**
  String get finEduCalcResultTotalGrowth;

  /// No description provided for @finEduCalcResultDoublingYears.
  ///
  /// In en, this message translates to:
  /// **'Approximate doubling time'**
  String get finEduCalcResultDoublingYears;

  /// No description provided for @finEduCalcResultSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get finEduCalcResultSavingsRate;

  /// No description provided for @finEduCalcYearsValue.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String finEduCalcYearsValue(String years);

  /// No description provided for @finEduCalcPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String finEduCalcPercentValue(String percent);

  /// No description provided for @finEduCalcIllustrativeNote.
  ///
  /// In en, this message translates to:
  /// **'Illustrative only — assumes a constant rate; real returns vary and are not guaranteed'**
  String get finEduCalcIllustrativeNote;

  /// No description provided for @finEduCalcHighRateNote.
  ///
  /// In en, this message translates to:
  /// **'This rate is unusually high. The result is purely illustrative — sustained returns this high are rare.'**
  String get finEduCalcHighRateNote;

  /// No description provided for @finEduCalcRuleOf72Note.
  ///
  /// In en, this message translates to:
  /// **'An approximation using the rule of 72 (72 ÷ annual rate), not an exact figure.'**
  String get finEduCalcRuleOf72Note;

  /// No description provided for @finEduCalcSavingsAboveIncomeNote.
  ///
  /// In en, this message translates to:
  /// **'The amount saved is higher than the income entered, so the rate is above 100%.'**
  String get finEduCalcSavingsAboveIncomeNote;

  /// No description provided for @finEduCalcSavingsRateNote.
  ///
  /// In en, this message translates to:
  /// **'Calculated only from the two figures you entered.'**
  String get finEduCalcSavingsRateNote;

  /// No description provided for @finEduTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Education'**
  String get finEduTitle;

  /// No description provided for @finEduSettingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get finEduSettingsSectionTitle;

  /// No description provided for @finEduSettingsEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Articles and illustrative calculators'**
  String get finEduSettingsEntrySubtitle;

  /// No description provided for @finEduDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'For general educational purposes only. This is not personalized financial or investment advice.'**
  String get finEduDisclaimer;

  /// No description provided for @finEduTopicsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get finEduTopicsSectionTitle;

  /// No description provided for @finEduToolsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get finEduToolsSectionTitle;

  /// No description provided for @finEduCompoundGrowthTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Compound growth'**
  String get finEduCompoundGrowthTileTitle;

  /// No description provided for @finEduCompoundGrowthTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See how a regular monthly amount could grow over time'**
  String get finEduCompoundGrowthTileSubtitle;

  /// No description provided for @finEduDoublingTimeTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Doubling time'**
  String get finEduDoublingTimeTileTitle;

  /// No description provided for @finEduDoublingTimeTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate how long money takes to double with the rule of 72'**
  String get finEduDoublingTimeTileSubtitle;

  /// No description provided for @finEduSavingsRateTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get finEduSavingsRateTileTitle;

  /// No description provided for @finEduSavingsRateTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Work out what share of income is being saved'**
  String get finEduSavingsRateTileSubtitle;

  /// No description provided for @finEduLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this content'**
  String get finEduLoadErrorTitle;

  /// No description provided for @finEduLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while opening the bundled content. Please try again.'**
  String get finEduLoadErrorMessage;

  /// No description provided for @finEduRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get finEduRetry;

  /// No description provided for @finEduEmptyCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles yet'**
  String get finEduEmptyCategoryTitle;

  /// No description provided for @finEduEmptyCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Articles for this topic will appear here.'**
  String get finEduEmptyCategoryMessage;

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
