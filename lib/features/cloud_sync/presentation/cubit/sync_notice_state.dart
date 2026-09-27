import 'package:equatable/equatable.dart';

/// [unknown] until the status is read; [show] once when the notice is due;
/// [hidden] when it is not, or after it was acknowledged.
enum SyncNoticeVisibility { unknown, show, hidden }

/// Immutable state for `SyncNoticeCubit` (constitution Principle IV).
class SyncNoticeState extends Equatable {
  const SyncNoticeState({
    this.visibility = SyncNoticeVisibility.unknown,
    this.isAcknowledging = false,
  });

  final SyncNoticeVisibility visibility;
  final bool isAcknowledging;

  SyncNoticeState copyWith({
    SyncNoticeVisibility? visibility,
    bool? isAcknowledging,
  }) {
    return SyncNoticeState(
      visibility: visibility ?? this.visibility,
      isAcknowledging: isAcknowledging ?? this.isAcknowledging,
    );
  }

  @override
  List<Object?> get props => [visibility, isAcknowledging];
}
