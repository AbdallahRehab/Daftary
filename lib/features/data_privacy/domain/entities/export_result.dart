import 'package:equatable/equatable.dart';

/// The sections one export file is made of, in file order (research.md
/// Decision 4). The first five are the original export; 022 D1 appends ten
/// after them, so the original bytes never change.
///
/// [key] names the section in [ExportResult.sectionCounts]; [marker] is the
/// `## MARKER` line that opens the section inside the CSV file.
enum ExportSection {
  people('People', 'PEOPLE'),
  transactions('Transactions', 'TRANSACTIONS'),
  financeEntries('FinanceEntries', 'FINANCE_ENTRIES'),
  categories('Categories', 'CATEGORIES'),
  settings('Settings', 'SETTINGS'),
  occasions('Occasions', 'OCCASIONS'),

  /// By reference: the transaction, occasion and person ids and whether it
  /// counts toward the balance. The amounts are in TRANSACTIONS.
  occasionContributions('OccasionContributions', 'OCCASION_CONTRIBUTIONS'),
  budgets('Budgets', 'BUDGETS'),
  budgetAllocations('BudgetAllocations', 'BUDGET_ALLOCATIONS'),
  savingsGoals('SavingsGoals', 'SAVINGS_GOALS'),
  savingsContributions('SavingsContributions', 'SAVINGS_CONTRIBUTIONS'),
  exchangeRates('ExchangeRates', 'EXCHANGE_RATES'),
  transactionChanges('TransactionChanges', 'TRANSACTION_CHANGES'),
  savingsContributionChanges(
    'SavingsContributionChanges',
    'SAVINGS_CONTRIBUTION_CHANGES',
  ),
  financeEntryChanges('FinanceEntryChanges', 'FINANCE_ENTRY_CHANGES');

  const ExportSection(this.key, this.marker);

  final String key;
  final String marker;
}

/// The outcome of one successful `ExportUserData` call (data-model.md
/// "Entity: ExportResult"). In-memory only, never persisted.
class ExportResult extends Equatable {
  const ExportResult({
    required this.filePath,
    required this.generatedAt,
    required this.sectionCounts,
  });

  /// The finished `.csv` in the app's own sandboxed temp directory. Always
  /// an existing, non-empty file — even an all-empty export carries its
  /// section markers and header rows (FR-008).
  final String filePath;

  final DateTime generatedAt;

  /// Data rows written per section, keyed by [ExportSection.key] (SC-003).
  final Map<String, int> sectionCounts;

  /// Every data row across every section — what the ready state reports
  /// back to the user as "N records were included".
  int get totalRecords =>
      sectionCounts.values.fold(0, (sum, count) => sum + count);

  @override
  List<Object?> get props => [filePath, generatedAt, sectionCounts];
}
