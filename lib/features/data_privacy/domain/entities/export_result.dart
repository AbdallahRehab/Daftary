import 'package:equatable/equatable.dart';

/// The five sections one export file is made of, in file order
/// (research.md Decision 4).
///
/// [key] names the section in [ExportResult.sectionCounts]; [marker] is the
/// `## MARKER` line that opens the section inside the CSV file.
enum ExportSection {
  people('People', 'PEOPLE'),
  transactions('Transactions', 'TRANSACTIONS'),
  financeEntries('FinanceEntries', 'FINANCE_ENTRIES'),
  categories('Categories', 'CATEGORIES'),
  settings('Settings', 'SETTINGS');

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
