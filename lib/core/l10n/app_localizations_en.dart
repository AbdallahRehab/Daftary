// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
}
