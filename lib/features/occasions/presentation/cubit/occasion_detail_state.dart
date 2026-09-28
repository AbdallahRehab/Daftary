import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/occasion_detail.dart';

enum OccasionDetailStatus { loading, success, failure }

/// What the attachment flow is currently doing, kept separate from
/// [OccasionDetailStatus] so opening the camera never blanks the occasion
/// the user is looking at.
enum AttachmentStatus { idle, picking, saving }

/// Immutable state for [OccasionDetailCubit] (constitution Principle IV).
class OccasionDetailState extends Equatable {
  const OccasionDetailState({
    required this.occasionId,
    this.status = OccasionDetailStatus.loading,
    this.detail,
    this.failure,
    this.attachmentStatus = AttachmentStatus.idle,
    this.attachmentFailure,
    this.isDeleted = false,
  });

  final String occasionId;
  final OccasionDetailStatus status;

  /// The occasion, its computed totals, its participant rows and its
  /// attachments, loaded together so the totals card and the rows beneath
  /// it can never be a moment apart and disagree (FR-007).
  final OccasionDetail? detail;
  final Failure? failure;
  final AttachmentStatus attachmentStatus;

  /// Kept apart from [failure] so a denied camera permission explains
  /// itself without replacing the occasion with an error screen — the
  /// occasion stays fully usable without the photo (FR-017 Edge Cases).
  /// A user cancellation is never recorded here; it is not an error.
  final Failure? attachmentFailure;

  /// Set once the occasion has been deleted, so the page can pop rather
  /// than reload a row that is now a tombstone (FR-013).
  final bool isDeleted;

  bool get isLoading => status == OccasionDetailStatus.loading;
  bool get isAttachmentBusy => attachmentStatus != AttachmentStatus.idle;

  /// Drives the "no participants yet" empty state (FR-020).
  bool get hasParticipants => (detail?.participants.isNotEmpty ?? false);

  /// The count the delete confirmation names before anything is destroyed
  /// (FR-013).
  int get participantCount => detail?.summary.participantCount ?? 0;

  OccasionDetailState copyWith({
    OccasionDetailStatus? status,
    OccasionDetail? detail,
    Failure? failure,
    bool clearFailure = false,
    AttachmentStatus? attachmentStatus,
    Failure? attachmentFailure,
    bool clearAttachmentFailure = false,
    bool? isDeleted,
  }) {
    return OccasionDetailState(
      occasionId: occasionId,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      failure: clearFailure ? null : (failure ?? this.failure),
      attachmentStatus: attachmentStatus ?? this.attachmentStatus,
      attachmentFailure: clearAttachmentFailure
          ? null
          : (attachmentFailure ?? this.attachmentFailure),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
    occasionId,
    status,
    detail,
    failure,
    attachmentStatus,
    attachmentFailure,
    isDeleted,
  ];
}
