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
