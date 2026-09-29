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
  /// **'Financial education'**
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

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @errorLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this'**
  String get errorLoadTitle;

  /// No description provided for @errorCache.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read or save your data on this device. Please try again.'**
  String get errorCache;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists. It may have been deleted.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Some details aren\'t valid. Check them and try again.'**
  String get errorValidation;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @errorSyncNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Your data is saved on this device and will sync when you\'re back online.'**
  String get errorSyncNetwork;

  /// No description provided for @errorSyncTimeout.
  ///
  /// In en, this message translates to:
  /// **'The cloud took too long to respond. We\'ll try again shortly.'**
  String get errorSyncTimeout;

  /// No description provided for @errorSyncServer.
  ///
  /// In en, this message translates to:
  /// **'The cloud service is having trouble right now. We\'ll try again shortly.'**
  String get errorSyncServer;

  /// No description provided for @errorSyncUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your cloud session has expired. Sign in again to keep syncing.'**
  String get errorSyncUnauthorized;

  /// No description provided for @errorSyncForbidden.
  ///
  /// In en, this message translates to:
  /// **'This change isn\'t allowed by your cloud account.'**
  String get errorSyncForbidden;

  /// No description provided for @errorSyncRejected.
  ///
  /// In en, this message translates to:
  /// **'The cloud couldn\'t accept this change. Review it and try again.'**
  String get errorSyncRejected;

  /// No description provided for @errorSyncConflict.
  ///
  /// In en, this message translates to:
  /// **'This record was changed on another device. Choose which version to keep.'**
  String get errorSyncConflict;

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

  /// No description provided for @archivePersonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}'**
  String archivePersonTooltip(String name);

  /// No description provided for @personArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} archived. You can find them in Archived people.'**
  String personArchivedMessage(String name);

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
  /// **'Enter a name'**
  String get nameRequiredError;

  /// No description provided for @personRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Choose a person, or create a new one'**
  String get personRequiredError;

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
  /// **'Someone with a similar name is already in your list. Is this the same person?'**
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
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero, up to 12 digits'**
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
  /// **'It will be removed from this person\'s history and balance. This can\'t be undone.'**
  String get deleteTransactionConfirmMessage;

  /// No description provided for @deleteTransactionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get deleteTransactionTooltip;

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
  /// **'Couldn\'t save your language choice. It\'s on for now but may reset when you reopen the app — try choosing it again.'**
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
  /// **'System default'**
  String get themeSystemDefault;

  /// No description provided for @themeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your theme choice. It\'s on for now but may reset when you reopen the app — try choosing it again.'**
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
  /// **'Lending a friend cash, splitting a gift, or covering someone at a gathering — record it with that person so nothing gets forgotten.'**
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

  /// No description provided for @onboardingIncomeExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'See where your own money goes'**
  String get onboardingIncomeExpenseTitle;

  /// No description provided for @onboardingIncomeExpenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Record your income and spending by category, and see each month\'s totals alongside what people owe you.'**
  String get onboardingIncomeExpenseDescription;

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
  /// **'Get started'**
  String get onboardingGetStartedAction;

  /// No description provided for @onboardingSkipAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkipAction;

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
  /// **'Enter a category name'**
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

  /// No description provided for @notificationBudgetNearLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} is close to its limit'**
  String notificationBudgetNearLimitTitle(String category);

  /// No description provided for @notificationBudgetNearLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {percent}% of your {category} budget this month.'**
  String notificationBudgetNearLimitBody(String category, String percent);

  /// No description provided for @notificationBudgetExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} is over budget'**
  String notificationBudgetExceededTitle(String category);

  /// No description provided for @notificationBudgetExceededBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve spent {percent}% of your {category} budget this month.'**
  String notificationBudgetExceededBody(String category, String percent);

  /// No description provided for @notificationBudgetExceededNoPlanBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve spent on {category} this month, but no amount was planned for it.'**
  String notificationBudgetExceededNoPlanBody(String category);

  /// No description provided for @notificationSavingsBehindPaceTitle.
  ///
  /// In en, this message translates to:
  /// **'{goal} is falling behind'**
  String notificationSavingsBehindPaceTitle(String goal);

  /// No description provided for @notificationSavingsBehindPaceBody.
  ///
  /// In en, this message translates to:
  /// **'At your current pace, you\'ll reach {goal} {months, plural, =1{1 month} other{{months} months}} later than planned.'**
  String notificationSavingsBehindPaceBody(String goal, int months);

  /// No description provided for @notificationSavingsAheadOfPaceTitle.
  ///
  /// In en, this message translates to:
  /// **'{goal} is ahead of schedule'**
  String notificationSavingsAheadOfPaceTitle(String goal);

  /// No description provided for @notificationSavingsAheadOfPaceBody.
  ///
  /// In en, this message translates to:
  /// **'Nice work — you\'re on track to reach {goal} {months, plural, =1{1 month} other{{months} months}} early.'**
  String notificationSavingsAheadOfPaceBody(String goal, int months);

  /// No description provided for @notificationSavingsAchievedTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal reached: {goal}'**
  String notificationSavingsAchievedTitle(String goal);

  /// No description provided for @notificationSavingsAchievedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve saved the full amount for {goal}. Well done!'**
  String notificationSavingsAchievedBody(String goal);

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Budget warnings, savings check-ins and quiet hours'**
  String get notificationSettingsEntrySubtitle;

  /// No description provided for @notificationSettingsMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget & savings reminders'**
  String get notificationSettingsMasterTitle;

  /// No description provided for @notificationSettingsMasterOffDescription.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Turn on to get a heads-up when a budget is nearly used up or a savings goal drifts from its plan. Everything is worked out on this device from your own data.'**
  String get notificationSettingsMasterOffDescription;

  /// No description provided for @notificationSettingsMasterOnDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'ll only get a reminder when something about your budgets or goals actually changes.'**
  String get notificationSettingsMasterOnDescription;

  /// No description provided for @notificationSettingsCategoriesHeader.
  ///
  /// In en, this message translates to:
  /// **'What to notify me about'**
  String get notificationSettingsCategoriesHeader;

  /// No description provided for @notificationBudgetWarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget warnings'**
  String get notificationBudgetWarningsTitle;

  /// No description provided for @notificationBudgetWarningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a category is close to or over its monthly limit'**
  String get notificationBudgetWarningsSubtitle;

  /// No description provided for @notificationSavingsCheckInsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings goal check-ins'**
  String get notificationSavingsCheckInsTitle;

  /// No description provided for @notificationSavingsCheckInsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a goal falls behind or gets ahead of its plan, or is reached'**
  String get notificationSavingsCheckInsSubtitle;

  /// No description provided for @notificationQuietHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notificationQuietHoursTitle;

  /// No description provided for @notificationQuietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold notifications during these hours and deliver them afterwards'**
  String get notificationQuietHoursSubtitle;

  /// No description provided for @notificationQuietHoursFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get notificationQuietHoursFrom;

  /// No description provided for @notificationQuietHoursTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get notificationQuietHoursTo;

  /// No description provided for @notificationQuietHoursNextDay.
  ///
  /// In en, this message translates to:
  /// **'next day'**
  String get notificationQuietHoursNextDay;

  /// No description provided for @notificationPermissionRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications?'**
  String get notificationPermissionRationaleTitle;

  /// No description provided for @notificationPermissionRationaleMessage.
  ///
  /// In en, this message translates to:
  /// **'Daftary needs your permission to show these reminders. They\'re only about your own budgets and savings goals, and nothing leaves your device.'**
  String get notificationPermissionRationaleMessage;

  /// No description provided for @notificationPermissionRationaleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get notificationPermissionRationaleConfirm;

  /// No description provided for @notificationPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get notificationPermissionDeniedTitle;

  /// No description provided for @notificationPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your device isn\'t letting Daftary show notifications, so nothing will be delivered even though reminders are on. Allow notifications in your device settings to start receiving them.'**
  String get notificationPermissionDeniedMessage;

  /// No description provided for @notificationPermissionDeniedAction.
  ///
  /// In en, this message translates to:
  /// **'Open device settings'**
  String get notificationPermissionDeniedAction;

  /// No description provided for @notificationSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your notification settings. Please try again.'**
  String get notificationSettingsSaveFailed;

  /// No description provided for @notificationSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your notification settings.'**
  String get notificationSettingsLoadFailed;

  /// Shown when the user taps a budget notification whose budget or category has since been deleted.
  ///
  /// In en, this message translates to:
  /// **'That budget no longer exists.'**
  String get notificationBudgetNoLongerExists;

  /// Shown when the user taps a savings-goal notification whose goal has since been deleted.
  ///
  /// In en, this message translates to:
  /// **'That savings goal no longer exists.'**
  String get notificationSavingsGoalNoLongerExists;

  /// No description provided for @currencyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyFieldLabel;

  /// No description provided for @rateNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Total unavailable — exchange rate needed'**
  String get rateNeededTitle;

  /// No description provided for @rateNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an exchange rate for {currencies} to see this total. Your records are safe and unchanged.'**
  String rateNeededMessage(String currencies);

  /// No description provided for @rateNeededAction.
  ///
  /// In en, this message translates to:
  /// **'Set exchange rate'**
  String get rateNeededAction;

  /// No description provided for @currencySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencySettingsTitle;

  /// No description provided for @currencySettingsEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Primary currency and exchange rates'**
  String get currencySettingsEntrySubtitle;

  /// No description provided for @primaryCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary currency'**
  String get primaryCurrencyLabel;

  /// No description provided for @primaryCurrencyDescription.
  ///
  /// In en, this message translates to:
  /// **'All totals and balances are shown in this currency.'**
  String get primaryCurrencyDescription;

  /// No description provided for @primaryCurrencyChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get primaryCurrencyChange;

  /// No description provided for @primaryCurrencyChanged.
  ///
  /// In en, this message translates to:
  /// **'Primary currency updated'**
  String get primaryCurrencyChanged;

  /// No description provided for @primaryCurrencySwitchRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate needed'**
  String get primaryCurrencySwitchRateTitle;

  /// No description provided for @primaryCurrencySwitchRateMessage.
  ///
  /// In en, this message translates to:
  /// **'You have records in {previous}. Enter how many {next} one {previous} is worth so your totals stay correct.'**
  String primaryCurrencySwitchRateMessage(String previous, String next);

  /// No description provided for @exchangeRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get exchangeRatesTitle;

  /// No description provided for @exchangeRatesManualDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Rates are entered by you and never fetched automatically. Update them whenever you like.'**
  String get exchangeRatesManualDisclosure;

  /// No description provided for @exchangeRatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exchange rates yet'**
  String get exchangeRatesEmpty;

  /// No description provided for @exchangeRateAdd.
  ///
  /// In en, this message translates to:
  /// **'Add rate'**
  String get exchangeRateAdd;

  /// No description provided for @exchangeRateEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get exchangeRateEditTitle;

  /// No description provided for @exchangeRateValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value of 1 {from} in {to}'**
  String exchangeRateValueLabel(String from, String to);

  /// No description provided for @exchangeRateLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String exchangeRateLastUpdated(String date);

  /// No description provided for @exchangeRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate greater than zero'**
  String get exchangeRateInvalid;

  /// No description provided for @exchangeRateSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get exchangeRateSave;

  /// No description provided for @exchangeRateRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove rate'**
  String get exchangeRateRemove;

  /// No description provided for @exchangeRateRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Totals that need this rate will be unavailable until you add it again. Your records won\'t change.'**
  String get exchangeRateRemoveConfirm;

  /// No description provided for @exchangeRateSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the exchange rate. Please try again.'**
  String get exchangeRateSaveFailed;

  /// No description provided for @currencySettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your currency settings.'**
  String get currencySettingsLoadFailed;

  /// No description provided for @primaryCurrencyChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the primary currency. Please try again.'**
  String get primaryCurrencyChangeFailed;

  /// Splash screen line under the app name, describing what Daftary does.
  ///
  /// In en, this message translates to:
  /// **'Every give and take, in one ledger'**
  String get splashTagline;

  /// Shown on the splash screen when startup fails or takes longer than 10 seconds.
  ///
  /// In en, this message translates to:
  /// **'Daftary couldn\'t finish opening. Please try again.'**
  String get splashErrorMessage;

  /// Settings section heading grouping visual appearance options such as Liquid Glass.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// Title of the switch that turns the Liquid Glass effect on or off; also the sample title in the glass preview.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass'**
  String get liquidGlassTitle;

  /// Subtitle under the Liquid Glass switch explaining what the effect changes.
  ///
  /// In en, this message translates to:
  /// **'Frosted glass effect on bars and buttons'**
  String get liquidGlassSubtitle;

  /// Snackbar shown when saving the Liquid Glass preference fails after a retry; the choice stays on for this session.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your glass setting. It will apply until you close the app.'**
  String get glassSaveFailed;

  /// Title of the three-level selector for how see-through the glass surfaces are.
  ///
  /// In en, this message translates to:
  /// **'Glass transparency'**
  String get glassTransparencyTitle;

  /// Title of the three-level selector for how strong the glass blur is.
  ///
  /// In en, this message translates to:
  /// **'Glass intensity'**
  String get glassIntensityTitle;

  /// Glass level option: the lowest of three levels.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get glassLevelLow;

  /// Glass level option: the middle of three levels.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get glassLevelMedium;

  /// Glass level option: the highest of three levels.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get glassLevelHigh;

  /// Sample text shown behind the glass strip in the Liquid Glass preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get glassPreviewTitle;

  /// Screen reader label for the Liquid Glass preview tile.
  ///
  /// In en, this message translates to:
  /// **'Sample of the Liquid Glass effect with your current settings'**
  String get glassPreviewSemantics;

  /// Short label of the badge on a transaction or finance entry row that was changed on two devices.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get syncConflictBadgeLabel;

  /// Screen reader label and tooltip of the conflict badge on a row.
  ///
  /// In en, this message translates to:
  /// **'Changed on another device. Choose which version to keep.'**
  String get syncConflictBadgeSemantics;

  /// Title of the sheet that lets the user choose between two versions of a financial record.
  ///
  /// In en, this message translates to:
  /// **'Changed on two devices'**
  String get syncConflictSheetTitle;

  /// Explanation at the top of the conflict resolution sheet.
  ///
  /// In en, this message translates to:
  /// **'This record was edited on this device and on another one. Choose the version to keep. The other version is saved in the history.'**
  String get syncConflictSheetMessage;

  /// Heading of the local version in the conflict resolution sheet.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get syncConflictMineLabel;

  /// Heading of the version from the cloud in the conflict resolution sheet.
  ///
  /// In en, this message translates to:
  /// **'Other device'**
  String get syncConflictTheirsLabel;

  /// Button that keeps the version edited on this device.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get syncConflictKeepMine;

  /// Button that keeps the version from the other device.
  ///
  /// In en, this message translates to:
  /// **'Keep theirs'**
  String get syncConflictKeepTheirs;

  /// Marker shown when one of the two versions deletes the record.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get syncConflictDeletedLabel;

  /// Error shown when resolving a sync conflict failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t resolve the conflict. Try again.'**
  String get syncConflictResolveFailed;

  /// Title of the cloud backup and sync settings page and its Settings entry.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup & sync'**
  String get syncSettingsTitle;

  /// Sync status: everything is synced.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncStatusUpToDate;

  /// Sync status: changes not yet uploaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String syncStatusPending(int count);

  /// Sync status: a sync is running.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncStatusSyncing;

  /// Sync status: no network.
  ///
  /// In en, this message translates to:
  /// **'Offline. Changes are saved on this device and will sync later.'**
  String get syncStatusOffline;

  /// Sync status: waiting before retrying.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the cloud. Trying again soon.'**
  String get syncStatusRetrying;

  /// Sync status: some changes were refused.
  ///
  /// In en, this message translates to:
  /// **'Some changes couldn\'t sync'**
  String get syncStatusFailed;

  /// Sync status: open conflicts.
  ///
  /// In en, this message translates to:
  /// **'Some records need your review'**
  String get syncStatusConflict;

  /// Sync status: the session is invalid.
  ///
  /// In en, this message translates to:
  /// **'Your cloud session has ended. Sync will resume once you sign in again.'**
  String get syncStatusAuthRequired;

  /// Sync status: switched off by the user.
  ///
  /// In en, this message translates to:
  /// **'Sync is off. Your data stays on this device.'**
  String get syncStatusOff;

  /// Sync status: this build has no cloud configuration.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup isn\'t available in this version.'**
  String get syncStatusUnavailable;

  /// Sync status: a downloaded record could not be read.
  ///
  /// In en, this message translates to:
  /// **'Some cloud data couldn\'t be read'**
  String get syncStatusUnreadable;

  /// Explanation shown when a downloaded record cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Some data from your other devices couldn\'t be read by this version of the app. Nothing was lost. Update the app and syncing will continue.'**
  String get syncProblemUnreadableMessage;

  /// When the last successful sync finished.
  ///
  /// In en, this message translates to:
  /// **'Last synced {dateTime}'**
  String syncLastSynced(String dateTime);

  /// Shown when no sync has succeeded yet.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNeverSynced;

  /// Label of the pending-changes count.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get syncCountPending;

  /// Label of the failed-changes count.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syncCountFailed;

  /// Label of the open-conflicts count.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get syncCountConflicts;

  /// Button that starts a sync.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNowButton;

  /// Title of the switch that turns sync on or off.
  ///
  /// In en, this message translates to:
  /// **'Back up and sync'**
  String get syncEnabledTitle;

  /// Subtitle of the sync switch.
  ///
  /// In en, this message translates to:
  /// **'Keep a copy of your data in the cloud and on your other phones.'**
  String get syncEnabledSubtitle;

  /// Title of the account section on the sync page.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get syncAccountSectionTitle;

  /// Action to link an email to the cloud account.
  ///
  /// In en, this message translates to:
  /// **'Link email'**
  String get syncLinkEmailTitle;

  /// Subtitle of the link email action.
  ///
  /// In en, this message translates to:
  /// **'Use your email to restore your data on a new phone.'**
  String get syncLinkEmailSubtitle;

  /// Action to sign in to an existing cloud account.
  ///
  /// In en, this message translates to:
  /// **'Sign in to existing account'**
  String get syncSignInTitle;

  /// Subtitle of the sign in action.
  ///
  /// In en, this message translates to:
  /// **'Use the data already backed up with your email.'**
  String get syncSignInSubtitle;

  /// Shows the masked linked email, for example a***@g***.com.
  ///
  /// In en, this message translates to:
  /// **'Linked to {email}'**
  String syncLinkedAs(String email);

  /// Title of the list of open conflicts.
  ///
  /// In en, this message translates to:
  /// **'Needs your review'**
  String get syncConflictsSectionTitle;

  /// Subtitle of an open conflict row.
  ///
  /// In en, this message translates to:
  /// **'Changed on two devices · {date}'**
  String syncConflictItemSubtitle(String date);

  /// Title of the list of failed changes.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync'**
  String get syncFailedSectionTitle;

  /// Button that queues the failed changes again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get syncRetryButton;

  /// Record type label.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get syncKindPerson;

  /// Record type label.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get syncKindTransaction;

  /// Record type label.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get syncKindTransactionHistory;

  /// Record type label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get syncKindFinanceCategory;

  /// Record type label.
  ///
  /// In en, this message translates to:
  /// **'Finance entry'**
  String get syncKindFinanceEntry;

  /// Record type label.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get syncKindExchangeRate;

  /// Record type label.
  ///
  /// In en, this message translates to:
  /// **'Primary currency'**
  String get syncKindPrimaryCurrency;

  /// Record type label.
  ///
  /// In en, this message translates to:
  /// **'Conflict choice'**
  String get syncKindConflictResolution;

  /// No description provided for @syncKindOccasion.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get syncKindOccasion;

  /// No description provided for @syncKindBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get syncKindBudget;

  /// No description provided for @syncKindBudgetAllocation.
  ///
  /// In en, this message translates to:
  /// **'Budget category'**
  String get syncKindBudgetAllocation;

  /// No description provided for @syncKindSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'Savings goal'**
  String get syncKindSavingsGoal;

  /// No description provided for @syncKindSavingsContribution.
  ///
  /// In en, this message translates to:
  /// **'Savings entry'**
  String get syncKindSavingsContribution;

  /// No description provided for @syncKindSavingsContributionHistory.
  ///
  /// In en, this message translates to:
  /// **'Savings entry history'**
  String get syncKindSavingsContributionHistory;

  /// Why a change was refused.
  ///
  /// In en, this message translates to:
  /// **'This person has transactions on another device.'**
  String get syncFailedReasonPersonHasTransactions;

  /// Why a change was refused.
  ///
  /// In en, this message translates to:
  /// **'This category\'s type doesn\'t match its entries.'**
  String get syncFailedReasonCategoryTypeMismatch;

  /// Why a change was refused.
  ///
  /// In en, this message translates to:
  /// **'The cloud couldn\'t accept this change.'**
  String get syncFailedReasonInvalid;

  /// Why a change was refused.
  ///
  /// In en, this message translates to:
  /// **'This change couldn\'t be sent.'**
  String get syncFailedReasonOther;

  /// Title of the email link sheet.
  ///
  /// In en, this message translates to:
  /// **'Link your email'**
  String get syncEmailLinkTitle;

  /// Title of the email sign-in sheet.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get syncEmailSignInTitle;

  /// Explains linking an email.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a code to your email. Your data stays as it is.'**
  String get syncEmailLinkMessage;

  /// Explains signing in to an existing account.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a code to your email. The data on this phone will be added to that account.'**
  String get syncEmailSignInMessage;

  /// Label of the email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get syncEmailFieldLabel;

  /// Button that sends the one-time code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get syncEmailSendCode;

  /// Shown after the code was sent; the email is masked.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}.'**
  String syncEmailCodeSent(String email);

  /// Label of the one-time code field.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get syncEmailCodeFieldLabel;

  /// Button that confirms the one-time code.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get syncEmailConfirm;

  /// Shown after linking an email.
  ///
  /// In en, this message translates to:
  /// **'Email linked'**
  String get syncEmailLinkSuccess;

  /// Shown after signing in.
  ///
  /// In en, this message translates to:
  /// **'Signed in. Your data will sync now.'**
  String get syncEmailSignInSuccess;

  /// Email code error.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired.'**
  String get syncEmailErrorInvalidCode;

  /// Email code error.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get syncEmailErrorInvalidEmail;

  /// Email code error.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Use \"Sign in to existing account\" instead.'**
  String get syncEmailErrorEmailInUse;

  /// Email code error.
  ///
  /// In en, this message translates to:
  /// **'No account uses this email.'**
  String get syncEmailErrorAccountNotFound;

  /// Email code error.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get syncEmailErrorRateLimited;

  /// Title of the one-time sync notice.
  ///
  /// In en, this message translates to:
  /// **'Your data can now be backed up'**
  String get syncNoticeTitle;

  /// Body of the one-time sync notice.
  ///
  /// In en, this message translates to:
  /// **'Daftary now keeps a private copy of your records in the cloud, so you can restore them on a new phone. You can turn this off anytime in Settings.'**
  String get syncNoticeMessage;

  /// Button in the notice that opens the sync settings.
  ///
  /// In en, this message translates to:
  /// **'Sync settings'**
  String get syncNoticeOpenSettings;

  /// Button that dismisses the sync notice.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get syncNoticeDismiss;

  /// No description provided for @appLockLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Daftary is locked'**
  String get appLockLockTitle;

  /// No description provided for @appLockLockPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue'**
  String get appLockLockPrompt;

  /// No description provided for @appLockLockBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Daftary to see your finances'**
  String get appLockLockBiometricReason;

  /// No description provided for @appLockLockUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get appLockLockUseBiometric;

  /// No description provided for @appLockLockBiometricInProgress.
  ///
  /// In en, this message translates to:
  /// **'Waiting for biometric confirmation. You can also enter your PIN.'**
  String get appLockLockBiometricInProgress;

  /// No description provided for @appLockLockVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking your PIN…'**
  String get appLockLockVerifying;

  /// No description provided for @appLockLockIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get appLockLockIncorrectPin;

  /// No description provided for @appLockLockBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock didn\'t work. Try again or enter your PIN.'**
  String get appLockLockBiometricFailed;

  /// No description provided for @appLockLockBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock isn\'t available on this device right now. Enter your PIN instead.'**
  String get appLockLockBiometricUnavailable;

  /// No description provided for @appLockLockUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get appLockLockUnexpectedError;

  /// No description provided for @appLockLockCooldownTitle.
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect attempts'**
  String get appLockLockCooldownTitle;

  /// No description provided for @appLockLockCooldownMessage.
  ///
  /// In en, this message translates to:
  /// **'PIN entry is paused. Try again in {time}.'**
  String appLockLockCooldownMessage(String time);

  /// No description provided for @appLockLockCooldownBiometricHint.
  ///
  /// In en, this message translates to:
  /// **'You can still unlock with biometrics.'**
  String get appLockLockCooldownBiometricHint;

  /// No description provided for @appLockPinPadDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get appLockPinPadDelete;

  /// No description provided for @appLockPinPadSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get appLockPinPadSubmit;

  /// No description provided for @appLockPinPadDigitsEntered.
  ///
  /// In en, this message translates to:
  /// **'PIN digits entered: {count}'**
  String appLockPinPadDigitsEntered(int count);

  /// No description provided for @appLockPinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get appLockPinSetupTitle;

  /// No description provided for @appLockPinChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get appLockPinChangeTitle;

  /// No description provided for @appLockPinResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new PIN'**
  String get appLockPinResetTitle;

  /// No description provided for @appLockPinVerifyCurrentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get appLockPinVerifyCurrentPrompt;

  /// No description provided for @appLockPinVerifyCurrentHint.
  ///
  /// In en, this message translates to:
  /// **'To change your PIN, first confirm it\'s you.'**
  String get appLockPinVerifyCurrentHint;

  /// No description provided for @appLockPinEnterNewPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN'**
  String get appLockPinEnterNewPrompt;

  /// No description provided for @appLockPinEnterNewHint.
  ///
  /// In en, this message translates to:
  /// **'Use 4 to 6 digits. Your PIN never leaves this device.'**
  String get appLockPinEnterNewHint;

  /// No description provided for @appLockPinConfirmNewPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again'**
  String get appLockPinConfirmNewPrompt;

  /// No description provided for @appLockPinConfirmNewHint.
  ///
  /// In en, this message translates to:
  /// **'This makes sure you typed the PIN you meant.'**
  String get appLockPinConfirmNewHint;

  /// No description provided for @appLockPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs don\'t match. Enter the confirmation again.'**
  String get appLockPinMismatch;

  /// No description provided for @appLockPinInvalid.
  ///
  /// In en, this message translates to:
  /// **'Your PIN must be 4 to 6 digits.'**
  String get appLockPinInvalid;

  /// No description provided for @appLockPinIncorrectCurrent.
  ///
  /// In en, this message translates to:
  /// **'That\'s not your current PIN. Please try again.'**
  String get appLockPinIncorrectCurrent;

  /// No description provided for @appLockPinBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric check didn\'t work. Try again or enter your current PIN.'**
  String get appLockPinBiometricFailed;

  /// No description provided for @appLockPinBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics aren\'t available right now. Enter your current PIN instead.'**
  String get appLockPinBiometricUnavailable;

  /// No description provided for @appLockPinUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your PIN. Please try again.'**
  String get appLockPinUnexpectedError;

  /// No description provided for @appLockPinStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get appLockPinStartOver;

  /// No description provided for @appLockPinUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics instead'**
  String get appLockPinUseBiometric;

  /// No description provided for @appLockPinBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to change your PIN'**
  String get appLockPinBiometricReason;

  /// No description provided for @appLockPinSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving your PIN…'**
  String get appLockPinSaving;

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

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Income & expenses'**
  String get financeTitle;

  /// No description provided for @financeUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get financeUndoAction;

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

  /// 018: pill shown on a budget row, the overall card or a trend month whose spent figure needs an exchange rate that has not been set.
  ///
  /// In en, this message translates to:
  /// **'Rate needed'**
  String get budgetRateNeededBadge;

  /// 018: a blocked budget row shows only its planned amount.
  ///
  /// In en, this message translates to:
  /// **'{amount} planned'**
  String budgetPlannedAmount(String amount);

  /// 018: replaces 'left'/'over' on a budget row whose spending is in a currency without a rate.
  ///
  /// In en, this message translates to:
  /// **'Spending needs an exchange rate for {currencies}'**
  String budgetLineNeedsRate(String currencies);

  /// 018: replaces the overall percentage when any budgeted category's spending needs a missing rate.
  ///
  /// In en, this message translates to:
  /// **'Spent and remaining need an exchange rate for {currencies}'**
  String budgetOverallNeedsRate(String currencies);

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
  /// **'Savings goals with a target date will appear here. Upcoming bills will follow once reminders are available.'**
  String get homeUpcomingPlaceholder;

  /// No description provided for @homeSavingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get homeSavingsTitle;

  /// No description provided for @homeSavingsEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan and track what you\'re saving for'**
  String get homeSavingsEntrySubtitle;

  /// 012/011 Home Upcoming: one goal's target date, already formatted.
  ///
  /// In en, this message translates to:
  /// **'Target date {date}'**
  String homeSavingsUpcomingTargetDate(String date);

  /// 012/011 Home Upcoming: saved so far of the target, both formatted in the goal's currency.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String homeSavingsUpcomingProgress(String current, String target);

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

  /// No description provided for @securitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySettingsTitle;

  /// No description provided for @securitySettingsTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App lock, PIN and screenshot protection'**
  String get securitySettingsTileSubtitle;

  /// No description provided for @appLockSettingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockSettingsSectionTitle;

  /// No description provided for @appLockSettingsToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock Daftary'**
  String get appLockSettingsToggleTitle;

  /// No description provided for @appLockSettingsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask for your PIN whenever you open the app'**
  String get appLockSettingsToggleSubtitle;

  /// No description provided for @appLockSettingsBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint or face'**
  String get appLockSettingsBiometricTitle;

  /// No description provided for @appLockSettingsBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your PIN still works too'**
  String get appLockSettingsBiometricSubtitle;

  /// No description provided for @appLockSettingsBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device. Set up fingerprint or face unlock in your device settings first.'**
  String get appLockSettingsBiometricUnavailable;

  /// No description provided for @appLockSettingsChangePinTile.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get appLockSettingsChangePinTile;

  /// No description provided for @appLockSettingsTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock after leaving the app'**
  String get appLockSettingsTimeoutTitle;

  /// No description provided for @appLockSettingsTimeoutImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get appLockSettingsTimeoutImmediately;

  /// No description provided for @appLockSettingsTimeout30Seconds.
  ///
  /// In en, this message translates to:
  /// **'After 30 seconds'**
  String get appLockSettingsTimeout30Seconds;

  /// No description provided for @appLockSettingsTimeout1Minute.
  ///
  /// In en, this message translates to:
  /// **'After 1 minute'**
  String get appLockSettingsTimeout1Minute;

  /// No description provided for @appLockSettingsTimeout5Minutes.
  ///
  /// In en, this message translates to:
  /// **'After 5 minutes'**
  String get appLockSettingsTimeout5Minutes;

  /// No description provided for @appLockSettingsScreenshotProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshot protection'**
  String get appLockSettingsScreenshotProtectionTitle;

  /// No description provided for @appLockSettingsScreenshotProtectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get appLockSettingsScreenshotProtectionStatus;

  /// No description provided for @appLockSettingsScreenshotProtectionBody.
  ///
  /// In en, this message translates to:
  /// **'Screenshots and screen recordings can\'t capture your data, and the recent-apps view shows a placeholder instead. Sharing and exporting still work.'**
  String get appLockSettingsScreenshotProtectionBody;

  /// No description provided for @appLockSettingsDisableTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off app lock?'**
  String get appLockSettingsDisableTitle;

  /// No description provided for @appLockSettingsDisableMessage.
  ///
  /// In en, this message translates to:
  /// **'Daftary will open without a PIN. Your PIN will be deleted, so turning app lock on again means choosing a new one. Screenshot protection stays on.'**
  String get appLockSettingsDisableMessage;

  /// No description provided for @appLockSettingsDisableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get appLockSettingsDisableConfirm;

  /// No description provided for @appLockSettingsBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to turn off app lock'**
  String get appLockSettingsBiometricReason;

  /// No description provided for @appLockSettingsReauthTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get appLockSettingsReauthTitle;

  /// No description provided for @appLockSettingsReauthMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to turn off app lock.'**
  String get appLockSettingsReauthMessage;

  /// No description provided for @appLockSettingsReauthPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get appLockSettingsReauthPinLabel;

  /// No description provided for @appLockSettingsReauthConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get appLockSettingsReauthConfirm;

  /// No description provided for @appLockSettingsReauthIncorrect.
  ///
  /// In en, this message translates to:
  /// **'That PIN isn\'t right. Try again.'**
  String get appLockSettingsReauthIncorrect;

  /// No description provided for @appLockSettingsReauthLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Try again in {duration}.'**
  String appLockSettingsReauthLockedOut(String duration);

  /// No description provided for @appLockSettingsReauthFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check your PIN. Try again.'**
  String get appLockSettingsReauthFailed;

  /// No description provided for @appLockSettingsEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'App lock is on'**
  String get appLockSettingsEnabledMessage;

  /// No description provided for @appLockSettingsDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'App lock is off'**
  String get appLockSettingsDisabledMessage;

  /// No description provided for @appLockSettingsPinChangedMessage.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get appLockSettingsPinChangedMessage;

  /// No description provided for @appLockSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save this change. Try again.'**
  String get appLockSettingsSaveFailed;

  /// No description provided for @appLockSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your security settings.'**
  String get appLockSettingsLoadFailed;

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
  /// **'This will permanently delete all of your people, transactions, occasions, scans, income and expense entries, categories, budgets, and settings from this device — and your cloud backup, if you use one. This cannot be undone. Consider exporting your data first.'**
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

  /// Shown when 'Delete my data' cannot reach the cloud backup to delete it too; nothing local or remote was removed.
  ///
  /// In en, this message translates to:
  /// **'Your cloud backup couldn\'t be reached, so nothing was deleted — all your data is still intact. Connect to the internet and try again.'**
  String get deleteDataCloudUnreachableError;

  /// No description provided for @appLockForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN'**
  String get appLockForgotTitle;

  /// No description provided for @appLockForgotBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify it\'s you'**
  String get appLockForgotBiometricTitle;

  /// No description provided for @appLockForgotBiometricMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you with biometrics, then choose a new PIN. None of your data will be touched.'**
  String get appLockForgotBiometricMessage;

  /// No description provided for @appLockForgotBiometricAction.
  ///
  /// In en, this message translates to:
  /// **'Verify with biometrics'**
  String get appLockForgotBiometricAction;

  /// No description provided for @appLockForgotBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to set a new Daftary PIN'**
  String get appLockForgotBiometricReason;

  /// No description provided for @appLockForgotBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric verification didn\'t succeed. You can try again.'**
  String get appLockForgotBiometricFailed;

  /// No description provided for @appLockForgotBiometricRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get appLockForgotBiometricRetry;

  /// No description provided for @appLockForgotChooseWipeAction.
  ///
  /// In en, this message translates to:
  /// **'Erase all data instead'**
  String get appLockForgotChooseWipeAction;

  /// No description provided for @appLockForgotWipeTitle.
  ///
  /// In en, this message translates to:
  /// **'The only way back in'**
  String get appLockForgotWipeTitle;

  /// No description provided for @appLockForgotWipeMessage.
  ///
  /// In en, this message translates to:
  /// **'Your PIN can\'t be reset. Without your PIN or biometrics, the only way to use the app again is to erase all of its data from this device and start fresh. If you linked cloud backup to your email, your backup is kept, and you can restore it afterwards by signing in with that email.'**
  String get appLockForgotWipeMessage;

  /// No description provided for @appLockForgotWipeContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue to erase data'**
  String get appLockForgotWipeContinueAction;

  /// No description provided for @appLockForgotBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back to lock screen'**
  String get appLockForgotBackAction;

  /// No description provided for @appLockWipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase all data'**
  String get appLockWipeTitle;

  /// No description provided for @appLockWipeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'This is permanent'**
  String get appLockWipeWarningTitle;

  /// No description provided for @appLockWipeWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently erase all of your people, transactions, occasions, scans, income and expense entries, categories, budgets, settings, and your App Lock PIN from this device. It cannot be undone, and Daftary cannot recover it.'**
  String get appLockWipeWarningMessage;

  /// No description provided for @appLockWipeConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Erase everything'**
  String get appLockWipeConfirmAction;

  /// No description provided for @appLockWipeCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get appLockWipeCancelAction;

  /// No description provided for @appLockWipeInProgress.
  ///
  /// In en, this message translates to:
  /// **'Erasing your data…'**
  String get appLockWipeInProgress;

  /// No description provided for @appLockWipeError.
  ///
  /// In en, this message translates to:
  /// **'Your data couldn\'t be erased. Nothing was removed — your data and PIN are unchanged. Please try again.'**
  String get appLockWipeError;

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

  /// 011: the goal (or entry) being viewed or changed was deleted.
  ///
  /// In en, this message translates to:
  /// **'This savings goal no longer exists.'**
  String get savingsGoalNotFoundError;

  /// 011 FR-006: a withdrawal, edit or delete would take the goal's balance below zero.
  ///
  /// In en, this message translates to:
  /// **'You can\'t withdraw more than this goal has saved.'**
  String get savingsWithdrawalExceedsBalanceError;

  /// 011 FR-021: delete is blocked for a goal with contribution history; archiving is offered instead.
  ///
  /// In en, this message translates to:
  /// **'This goal has saved amounts, so it can\'t be deleted. You can archive it instead.'**
  String get savingsGoalHasHistoryError;

  /// 011 FR-003/FR-016: the target date is today or in the past.
  ///
  /// In en, this message translates to:
  /// **'Choose a target date after today.'**
  String get savingsInvalidTargetDateError;

  /// 011 FR-020: new contributions/withdrawals are rejected on an archived goal.
  ///
  /// In en, this message translates to:
  /// **'This goal is archived. Restore it to add new amounts.'**
  String get savingsGoalArchivedError;

  /// 011 goal form title, create mode.
  ///
  /// In en, this message translates to:
  /// **'New savings goal'**
  String get savingsGoalFormCreateTitle;

  /// 011 goal form title, edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get savingsGoalFormEditTitle;

  /// 011 goal detail app-bar action tooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get savingsGoalEditAction;

  /// 011 goal form field.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get savingsGoalNameLabel;

  /// 011 FR-001 validation.
  ///
  /// In en, this message translates to:
  /// **'Give the goal a name.'**
  String get savingsGoalNameRequiredError;

  /// 011 goal type picker label; the type only picks an icon.
  ///
  /// In en, this message translates to:
  /// **'Type (optional)'**
  String get savingsGoalTypeLabel;

  /// 011 type picker option for a plain custom-named goal.
  ///
  /// In en, this message translates to:
  /// **'No type'**
  String get savingsGoalTypeNone;

  /// 011 standard goal type.
  ///
  /// In en, this message translates to:
  /// **'Emergency fund'**
  String get savingsGoalTypeEmergencyFund;

  /// 011 standard goal type.
  ///
  /// In en, this message translates to:
  /// **'New car'**
  String get savingsGoalTypeNewCar;

  /// 011 standard goal type.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get savingsGoalTypeWedding;

  /// 011 standard goal type.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get savingsGoalTypeVacation;

  /// 011 standard goal type.
  ///
  /// In en, this message translates to:
  /// **'New phone'**
  String get savingsGoalTypeNewPhone;

  /// 011 standard goal type.
  ///
  /// In en, this message translates to:
  /// **'Home furniture'**
  String get savingsGoalTypeHomeFurniture;

  /// 011 standard goal type.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get savingsGoalTypeEducation;

  /// 011 standard goal type.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get savingsGoalTypeOther;

  /// 011 FR-027 currency picker label (create only).
  ///
  /// In en, this message translates to:
  /// **'Goal currency'**
  String get savingsGoalCurrencyLabel;

  /// 011 FR-027: shown instead of the currency picker when editing.
  ///
  /// In en, this message translates to:
  /// **'Every amount of this goal is in {currency}. The currency can\'t be changed after the goal is created.'**
  String savingsGoalCurrencyFixedHint(String currency);

  /// 011 goal form field.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get savingsGoalTargetLabel;

  /// 011 FR-002 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a target amount greater than zero.'**
  String get savingsGoalTargetInvalidError;

  /// 011 starting amount field, create only.
  ///
  /// In en, this message translates to:
  /// **'Already saved (optional)'**
  String get savingsGoalStartingLabel;

  /// 011 starting amount helper text.
  ///
  /// In en, this message translates to:
  /// **'Money you had already set aside before tracking it here.'**
  String get savingsGoalStartingHint;

  /// 011 FR-002 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter zero or a positive amount.'**
  String get savingsGoalStartingInvalidError;

  /// 011 goal form field.
  ///
  /// In en, this message translates to:
  /// **'Monthly contribution (optional)'**
  String get savingsGoalMonthlyLabel;

  /// 011 FR-002 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a monthly amount greater than zero, or leave it empty.'**
  String get savingsGoalMonthlyInvalidError;

  /// 011 goal form field.
  ///
  /// In en, this message translates to:
  /// **'Target date (optional)'**
  String get savingsGoalTargetDateLabel;

  /// 011 target date field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get savingsGoalTargetDateNotSet;

  /// 011 target date clear button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear target date'**
  String get savingsGoalTargetDateClear;

  /// 011 goal form submit, create mode.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get savingsGoalCreateAction;

  /// 011 goal form submit, edit mode.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get savingsGoalUpdateAction;

  /// 011 live estimate preview heading on the goal form.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get savingsGoalPreviewTitle;

  /// 011 progress card figure label.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savingsProgressSavedLabel;

  /// 011 progress card figure label.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get savingsProgressRemainingLabel;

  /// 011 progress card figure label.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get savingsProgressTargetLabel;

  /// 011 progress percentage; percent is pre-formatted with Western digits.
  ///
  /// In en, this message translates to:
  /// **'{percent}% saved'**
  String savingsProgressPercent(String percent);

  /// 011 FR-010 estimate.
  ///
  /// In en, this message translates to:
  /// **'At {amount} a month, you\'ll reach it in {duration}, around {date}.'**
  String savingsEstimateByContribution(
    String amount,
    String duration,
    String date,
  );

  /// 011 FR-010 estimate when the date is too far to show.
  ///
  /// In en, this message translates to:
  /// **'At {amount} a month, you\'ll reach it in {duration}.'**
  String savingsEstimateByContributionUndated(String amount, String duration);

  /// 011 FR-011 required monthly contribution.
  ///
  /// In en, this message translates to:
  /// **'To reach it by {date}, save {amount} a month.'**
  String savingsEstimateRequired(String date, String amount);

  /// 011 FR-012 honest shortfall line.
  ///
  /// In en, this message translates to:
  /// **'At this rate, you\'ll reach this {duration} after your target date.'**
  String savingsEstimateShortfall(String duration);

  /// 011 US1 AS-6: shown when the goal has no plan.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly contribution or a target date to see when you\'ll reach this goal.'**
  String get savingsNoEstimatePrompt;

  /// 011 a number of months.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String savingsDurationMonths(int count);

  /// 011 a number of years.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String savingsDurationYears(int count);

  /// 011 a long timeline, e.g. '2 years and 3 months'.
  ///
  /// In en, this message translates to:
  /// **'{years} and {months}'**
  String savingsDurationYearsAndMonths(String years, String months);

  /// 011 FR-017 celebratory badge.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get savingsGoalAchievedBadge;

  /// 011 FR-017 celebratory message.
  ///
  /// In en, this message translates to:
  /// **'You\'ve saved everything you planned for this goal. Well done!'**
  String get savingsGoalAchievedMessage;

  /// 011 goal detail history section.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get savingsGoalHistoryHeader;

  /// 011 empty history title.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get savingsGoalHistoryEmptyTitle;

  /// 011 empty history message.
  ///
  /// In en, this message translates to:
  /// **'Add what you put toward this goal to track your real progress.'**
  String get savingsGoalHistoryEmptyMessage;

  /// 011 log contribution action.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get savingsLogContributionAction;

  /// 011 log withdrawal action.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get savingsLogWithdrawalAction;

  /// 011 FR-020 explanation shown instead of the log actions.
  ///
  /// In en, this message translates to:
  /// **'This goal is archived. You can still correct past entries; restore it to add new ones.'**
  String get savingsGoalArchivedNotice;

  /// 011 goal detail error state.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this goal'**
  String get savingsGoalLoadErrorTitle;

  /// 011 retry action.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get savingsRetryAction;

  /// 011 entry type label.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get savingsEntryContribution;

  /// 011 entry type label.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get savingsEntryWithdrawal;

  /// 011 label of the entry created from the goal's starting amount.
  ///
  /// In en, this message translates to:
  /// **'Starting amount'**
  String get savingsEntryStartingAmount;

  /// 011 FR-028: the converted goal-currency amount under a foreign entry.
  ///
  /// In en, this message translates to:
  /// **'Counted as {amount}'**
  String savingsEntryConvertedAmount(String amount);

  /// 011 marker on an edited entry.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get savingsEntryEditedLabel;

  /// 011 entry action.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get savingsEntryEditAction;

  /// 011 entry action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get savingsEntryDeleteAction;

  /// 011 entry overflow menu tooltip.
  ///
  /// In en, this message translates to:
  /// **'Entry options'**
  String get savingsEntryActionsTooltip;

  /// 011 FR-009 delete confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get savingsEntryDeleteConfirmTitle;

  /// 011 FR-009/FR-030 delete confirmation message.
  ///
  /// In en, this message translates to:
  /// **'The goal\'s figures will be recalculated. A record of the entry\'s values is kept.'**
  String get savingsEntryDeleteConfirmMessage;

  /// 011 contribution form title.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get savingsContributionFormAddTitle;

  /// 011 withdrawal form title.
  ///
  /// In en, this message translates to:
  /// **'Withdraw money'**
  String get savingsContributionFormWithdrawTitle;

  /// 011 contribution form title, edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get savingsContributionFormEditTitle;

  /// 011 contribution form field.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get savingsContributionAmountLabel;

  /// 011 FR-007 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get savingsContributionAmountInvalidError;

  /// 011 contribution form field.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get savingsContributionDateLabel;

  /// 011 contribution form field.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get savingsContributionNoteLabel;

  /// 011 contribution form submit.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savingsContributionSaveAction;

  /// 011 FR-028 hint when the entered currency differs from the goal's.
  ///
  /// In en, this message translates to:
  /// **'This will be converted to {currency} at the current rate when you save.'**
  String savingsContributionConversionHint(String currency);

  /// 011 US4 overview page title.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get savingsOverviewTitle;

  /// 011 US4 overview: create-goal FAB.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get savingsOverviewNewGoalAction;

  /// 011 US4 overview: open archived goals.
  ///
  /// In en, this message translates to:
  /// **'Archived goals'**
  String get savingsOverviewArchivedAction;

  /// 011 FR-023 empty-state title.
  ///
  /// In en, this message translates to:
  /// **'Start saving toward something'**
  String get savingsOverviewEmptyTitle;

  /// 011 FR-023 empty-state explanation.
  ///
  /// In en, this message translates to:
  /// **'Set a goal — an emergency fund, a trip, a new phone — and track every amount you put aside until you reach it.'**
  String get savingsOverviewEmptyMessage;

  /// 011 FR-023 empty-state action.
  ///
  /// In en, this message translates to:
  /// **'Create your first goal'**
  String get savingsOverviewEmptyAction;

  /// 011 FR-019 combined total label.
  ///
  /// In en, this message translates to:
  /// **'Total saved'**
  String get savingsOverviewTotalLabel;

  /// 011 FR-019: how many goals the total spans.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Across 1 goal} other{Across {count} goals}}'**
  String savingsOverviewGoalCount(int count);

  /// 011 FR-019 incomplete-total marker title.
  ///
  /// In en, this message translates to:
  /// **'Total incomplete'**
  String get savingsOverviewIncompleteTitle;

  /// 011 FR-019: names the missing rates.
  ///
  /// In en, this message translates to:
  /// **'It leaves out goals in {currencies}. Add an exchange rate for {currencies} to count them.'**
  String savingsOverviewIncompleteMessage(String currencies);

  /// 011 FR-019: a blocked goal line.
  ///
  /// In en, this message translates to:
  /// **'Not in the total — needs a {currency} rate'**
  String savingsOverviewNotInTotal(String currency);

  /// 011 overview card: saved of target, in the goal's currency.
  ///
  /// In en, this message translates to:
  /// **'{saved} of {target}'**
  String savingsOverviewGoalProgress(String saved, String target);

  /// 011 overview: goal list header.
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get savingsOverviewGoalsHeader;

  /// 011 overview load error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your goals'**
  String get savingsOverviewLoadErrorTitle;

  /// 011: goal overflow menu tooltip.
  ///
  /// In en, this message translates to:
  /// **'Goal options'**
  String get savingsOverviewGoalActionsTooltip;

  /// 011 FR-020 archive action.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get savingsArchiveAction;

  /// 011 FR-020 restore action.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get savingsArchiveRestoreAction;

  /// 011 FR-020 snackbar after archiving.
  ///
  /// In en, this message translates to:
  /// **'Goal archived'**
  String get savingsArchiveDoneMessage;

  /// 011 FR-020 snackbar after restoring.
  ///
  /// In en, this message translates to:
  /// **'Goal restored'**
  String get savingsArchiveRestoredMessage;

  /// 011 FR-020 undo an archive.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get savingsArchiveUndoAction;

  /// 011 FR-020 archived goals page title.
  ///
  /// In en, this message translates to:
  /// **'Archived goals'**
  String get savingsArchiveTitle;

  /// 011 archived goals empty state.
  ///
  /// In en, this message translates to:
  /// **'No archived goals'**
  String get savingsArchiveEmptyTitle;

  /// 011 archived goals empty state.
  ///
  /// In en, this message translates to:
  /// **'Goals you archive are kept here with their full history, ready to restore.'**
  String get savingsArchiveEmptyMessage;

  /// 011 FR-021 delete action.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get savingsDeleteAction;

  /// 011 FR-021 delete confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String savingsDeleteConfirmTitle(String name);

  /// 011 FR-021 delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'This goal will be removed for good.'**
  String get savingsDeleteConfirmMessage;

  /// 011 FR-021 delete blocked dialog title.
  ///
  /// In en, this message translates to:
  /// **'This goal has history'**
  String get savingsDeleteBlockedTitle;

  /// 011 FR-021 offer to archive instead.
  ///
  /// In en, this message translates to:
  /// **'Amounts have been logged to this goal, so it can\'t be deleted. Archive it instead to hide it while keeping its full history.'**
  String get savingsDeleteBlockedMessage;

  /// 011 FR-021 archive-instead action.
  ///
  /// In en, this message translates to:
  /// **'Archive instead'**
  String get savingsDeleteBlockedArchiveAction;

  /// 011 FR-021 snackbar after deleting.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get savingsDeleteDoneMessage;

  /// 011 FR-006 hint on the withdrawal form.
  ///
  /// In en, this message translates to:
  /// **'Available to withdraw: {amount}'**
  String savingsWithdrawalAvailableHint(String amount);

  /// 011 FR-013/FR-014 goal page entry point to the what-if calculator.
  ///
  /// In en, this message translates to:
  /// **'What if?'**
  String get savingsWhatIfAction;

  /// 011 what-if calculator page title.
  ///
  /// In en, this message translates to:
  /// **'What if?'**
  String get savingsWhatIfTitle;

  /// 011 FR-013 what-if mode: a hypothetical monthly contribution.
  ///
  /// In en, this message translates to:
  /// **'Save a different amount'**
  String get savingsWhatIfModeMonthly;

  /// 011 FR-014 what-if mode: a hypothetical target date.
  ///
  /// In en, this message translates to:
  /// **'Finish by a date'**
  String get savingsWhatIfModeDate;

  /// 011 what-if: heading of the goal's real, current plan.
  ///
  /// In en, this message translates to:
  /// **'Your plan now'**
  String get savingsWhatIfCurrentPlanTitle;

  /// 011 what-if: the goal's real remaining amount.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to save'**
  String savingsWhatIfCurrentRemaining(String amount);

  /// 011 what-if: the goal's real monthly contribution.
  ///
  /// In en, this message translates to:
  /// **'Saving {amount} a month'**
  String savingsWhatIfCurrentMonthly(String amount);

  /// 011 what-if: the goal has no monthly contribution.
  ///
  /// In en, this message translates to:
  /// **'No monthly contribution set'**
  String get savingsWhatIfCurrentNoMonthly;

  /// 011 what-if: the goal's real target date.
  ///
  /// In en, this message translates to:
  /// **'Target date: {date}'**
  String savingsWhatIfCurrentTargetDate(String date);

  /// 011 FR-013 hypothetical monthly contribution field.
  ///
  /// In en, this message translates to:
  /// **'Monthly amount to try'**
  String get savingsWhatIfMonthlyLabel;

  /// 011 FR-016: the hypothetical monthly contribution is empty, zero or negative.
  ///
  /// In en, this message translates to:
  /// **'Enter a monthly amount greater than zero.'**
  String get savingsWhatIfMonthlyInvalidError;

  /// 011 FR-014 hypothetical target date field.
  ///
  /// In en, this message translates to:
  /// **'Finish by'**
  String get savingsWhatIfTargetDateLabel;

  /// 011 what-if target date field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get savingsWhatIfTargetDateNotSet;

  /// 011 what-if: run the calculation.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get savingsWhatIfCalculateAction;

  /// 011 what-if: heading of the hypothetical result card.
  ///
  /// In en, this message translates to:
  /// **'If you did this'**
  String get savingsWhatIfResultTitle;

  /// 011 FR-013 what-if result.
  ///
  /// In en, this message translates to:
  /// **'Saving {amount} a month, you\'d reach your goal in {duration}, around {date}.'**
  String savingsWhatIfResultByMonthly(
    String amount,
    String duration,
    String date,
  );

  /// 011 FR-013 what-if result for a timeline too long to date.
  ///
  /// In en, this message translates to:
  /// **'Saving {amount} a month, you\'d reach your goal in {duration}.'**
  String savingsWhatIfResultByMonthlyUndated(String amount, String duration);

  /// 011 FR-014 what-if result.
  ///
  /// In en, this message translates to:
  /// **'To finish by {date}, you\'d need to save {amount} a month.'**
  String savingsWhatIfResultByDate(String date, String amount);

  /// 011 what-if: the hypothetical finishes earlier than the real plan.
  ///
  /// In en, this message translates to:
  /// **'{duration} sooner than your current plan'**
  String savingsWhatIfCompareSooner(String duration);

  /// 011 what-if: the hypothetical finishes later than the real plan.
  ///
  /// In en, this message translates to:
  /// **'{duration} later than your current plan'**
  String savingsWhatIfCompareLater(String duration);

  /// 011 what-if: the hypothetical finishes when the real plan does.
  ///
  /// In en, this message translates to:
  /// **'The same timeline as your current plan'**
  String get savingsWhatIfCompareSame;

  /// 011 what-if: the required contribution exceeds the real one.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month more than you save now'**
  String savingsWhatIfCompareMore(String amount);

  /// 011 what-if: the required contribution is below the real one.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month less than you save now'**
  String savingsWhatIfCompareLess(String amount);

  /// 011 FR-015: exploring never changes the goal.
  ///
  /// In en, this message translates to:
  /// **'This is only a preview. Your goal stays as it is unless you apply it.'**
  String get savingsWhatIfPreviewNotice;

  /// 011 FR-015: what applying a monthly what-if changes.
  ///
  /// In en, this message translates to:
  /// **'Applying sets your monthly contribution to {amount}. Your target date stays as it is.'**
  String savingsWhatIfApplyExplainMonthly(String amount);

  /// 011 FR-015: what applying a target-date what-if changes.
  ///
  /// In en, this message translates to:
  /// **'Applying sets your target date to {date} and your monthly contribution to {amount}.'**
  String savingsWhatIfApplyExplainDate(String date, String amount);

  /// 011 FR-015 apply action.
  ///
  /// In en, this message translates to:
  /// **'Apply to my goal'**
  String get savingsWhatIfApplyAction;

  /// 011 what-if: leave without changing the goal.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get savingsWhatIfCancelAction;

  /// 011 FR-015: confirmation after applying.
  ///
  /// In en, this message translates to:
  /// **'Your goal\'s plan was updated.'**
  String get savingsWhatIfAppliedMessage;

  /// 011 FR-016: what-if opened on an achieved goal.
  ///
  /// In en, this message translates to:
  /// **'Goal achieved'**
  String get savingsWhatIfAchievedTitle;

  /// 011 FR-016: what-if opened on an achieved goal.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already reached this goal, so there\'s nothing left to plan for.'**
  String get savingsWhatIfAchievedMessage;

  /// 011 what-if: return to the goal page.
  ///
  /// In en, this message translates to:
  /// **'Back to goal'**
  String get savingsWhatIfBackAction;
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
