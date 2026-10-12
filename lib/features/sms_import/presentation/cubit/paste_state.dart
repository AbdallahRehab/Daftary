import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/entities/sms_value_types.dart';

/// The Paste screen's phases (ui-contract §3.5).
enum PasteStatus {
  /// Empty or edited field; Paste and Process available.
  ready,

  /// The clipboard was empty or held no text (US4-6). Not an error.
  clipboardEmpty,

  /// Splitting and staging; every control disabled.
  processing,

  /// At least one bank transaction was recognized ([result] is set).
  recognized,

  /// Bank messages were found, but none could be read: enter manually.
  unreadableOnly,

  /// No supported bank message (FR-018). Nothing was stored.
  notRecognized,

  /// A bound was exceeded ([tooLargeLimit] says which). Nothing stored.
  tooLarge,

  /// Staging failed ([failure]).
  error,
}

/// Immutable state of `PasteCubit`. It never holds the pasted or shared
/// text: the text lives only in the page's field and, for a share, in the
/// in-memory `SharedTextInbox` until consumed.
class PasteState extends Equatable {
  const PasteState({
    this.status = PasteStatus.ready,
    this.fromShare = false,
    this.result,
    this.tooLargeLimit,
    this.failure,
  });

  final PasteStatus status;

  /// The current or last import came from the Android share target.
  final bool fromShare;
  final PasteImportResult? result;
  final InputLimit? tooLargeLimit;
  final Failure? failure;

  bool get isProcessing => status == PasteStatus.processing;

  /// Messages recognized as bank transactions in the last import.
  int get recognizedCount => result?.summary.recognized ?? 0;

  /// Messages in the last import that were not staged as transactions.
  int get skippedCount {
    final summary = result?.summary;
    if (summary == null) return 0;
    final skipped = summary.scanned - summary.recognized;
    return skipped < 0 ? 0 : skipped;
  }

  @override
  List<Object?> get props => [
    status,
    fromShare,
    result,
    tooLargeLimit,
    failure,
  ];

  /// Redacted: phase, counts and codes only, never text (FR-097).
  @override
  String toString() =>
      'PasteState(status: ${status.name}, fromShare: $fromShare, '
      'recognized: $recognizedCount, skipped: $skippedCount, '
      'newItems: ${result?.newIds.length ?? 0}, '
      'limit: ${tooLargeLimit?.name}, failure: ${failure.runtimeType})';
}
