// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
      'Upcoming bills and savings-goal milestones will appear here once reminders and savings goals are available.';

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
  String get deleteDataTitle => 'Delete my data';

  @override
  String get deleteDataWarningTitle => 'This is permanent';

  @override
  String get deleteDataWarningMessage =>
      'This will permanently delete all of your people, transactions, occasions, scans, income and expense entries, categories, budgets, and settings from this device. This cannot be undone. Consider exporting your data first.';

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
}
