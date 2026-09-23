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
}
