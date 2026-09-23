import 'package:equatable/equatable.dart';

import 'candidate_entry.dart';

/// What the parser made of one recognized page: the per-line candidates,
/// plus the two whole-page hints it reads once rather than per line
/// (research.md Decision 3).
class ParsedScan extends Equatable {
  const ParsedScan({
    required this.entries,
    this.occasionHeading,
    this.batchDate,
  });

  const ParsedScan.empty()
    : entries = const [],
      occasionHeading = null,
      batchDate = null;

  /// Candidates in page order. Empty means nothing on the page looked like
  /// a name/amount line, which the caller turns into
  /// `NoCandidatesParsedFailure` (FR-004).
  final List<CandidateEntry> entries;

  /// A heading-shaped line naming an occasion, offered to the user as a
  /// suggestion on the review screen (FR-014). Never applied on its own —
  /// tagging a batch to an occasion is always the user's action.
  final String? occasionHeading;

  /// A date-shaped token found anywhere on the page, applied to every entry
  /// that had no date of its own. `null` means entries fall back to the
  /// scan's own date instead.
  final DateTime? batchDate;

  bool get isEmpty => entries.isEmpty;

  @override
  List<Object?> get props => [entries, occasionHeading, batchDate];
}
