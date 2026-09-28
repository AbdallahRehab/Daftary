import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ocr_scan.dart';

enum ScanHistoryStatus { loading, success, failure }

/// Immutable state for [ScanHistoryCubit] (constitution Principle IV).
class ScanHistoryState extends Equatable {
  const ScanHistoryState({
    this.status = ScanHistoryStatus.loading,
    this.scans = const [],
    this.failure,
  });

  final ScanHistoryStatus status;

  /// Newest first, excluding deleted scans (FR-018). The repository query
  /// establishes that order, so the list is rendered exactly as received
  /// and never re-sorted here — two sort rules in two layers can only
  /// disagree.
  final List<OcrScan> scans;
  final Failure? failure;

  bool get isLoading => status == ScanHistoryStatus.loading;

  /// "You haven't scanned anything yet". Distinct from [isLoading] so the
  /// page never shows a spinner that would sit there forever, and distinct
  /// from [hasFailed] so a read error is never mistaken for an empty
  /// history.
  bool get isEmpty => status == ScanHistoryStatus.success && scans.isEmpty;

  bool get hasFailed => status == ScanHistoryStatus.failure;

  ScanHistoryState copyWith({
    ScanHistoryStatus? status,
    List<OcrScan>? scans,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ScanHistoryState(
      status: status ?? this.status,
      scans: scans ?? this.scans,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, scans, failure];
}
