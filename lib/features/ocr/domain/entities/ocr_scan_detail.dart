import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/money_transaction.dart';
import 'candidate_entry.dart';
import 'ocr_scan.dart';

/// Everything the scan-detail screen shows for one past scan (FR-018): the
/// scan itself (and so its source image), the candidate entries in whatever
/// state they ended in, and the real transactions the scan produced.
///
/// [transactions] is read back through `ocr_scan_id` rather than stored on
/// the entries, because a `CandidateEntry` never points at a transaction —
/// the link is deliberately one-way (data-model.md Relationships).
class OcrScanDetail extends Equatable {
  const OcrScanDetail({
    required this.scan,
    required this.entries,
    required this.transactions,
  });

  final OcrScan scan;
  final List<CandidateEntry> entries;
  final List<MoneyTransaction> transactions;

  @override
  List<Object?> get props => [scan, entries, transactions];
}
