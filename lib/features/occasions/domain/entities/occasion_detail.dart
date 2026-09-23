import 'package:equatable/equatable.dart';

import 'occasion.dart';
import 'occasion_attachment.dart';
import 'occasion_participant_row.dart';
import 'occasion_summary.dart';

/// Everything the occasion detail screen renders, assembled in one read so
/// the totals and the rows they summarize can never be fetched a moment
/// apart and disagree.
class OccasionDetail extends Equatable {
  const OccasionDetail({
    required this.occasion,
    required this.summary,
    required this.participants,
    required this.attachments,
  });

  final Occasion occasion;
  final OccasionSummary summary;

  /// Chronological, oldest first — same order as a person's own history.
  final List<OccasionParticipantRow> participants;
  final List<OccasionAttachment> attachments;

  @override
  List<Object?> get props => [occasion, summary, participants, attachments];
}
