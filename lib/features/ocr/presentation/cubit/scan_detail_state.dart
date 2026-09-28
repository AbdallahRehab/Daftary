import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ocr_scan_detail.dart';

enum ScanDetailStatus { loading, success, failure, deleted }

/// Immutable state for [ScanDetailCubit] (constitution Principle IV).
class ScanDetailState extends Equatable {
  const ScanDetailState({
    this.status = ScanDetailStatus.loading,
    this.detail,
    this.failure,
  });

  final ScanDetailStatus status;

  /// The scan, its candidate entries in whatever state they ended in, and
  /// the transactions it produced (FR-018). `null` until the first
  /// successful read.
  final OcrScanDetail? detail;
  final Failure? failure;

  bool get isLoading => status == ScanDetailStatus.loading;
  bool get hasFailed => status == ScanDetailStatus.failure;

  /// Set once the scan has been deleted, so the page can pop instead of
  /// re-rendering a record that no longer exists.
  bool get isDeleted => status == ScanDetailStatus.deleted;

  /// A scan that produced nothing — fully discarded or abandoned. Still
  /// worth showing (User Story 5, Acceptance Scenario 3), just clearly
  /// marked as having created no money.
  bool get producedNoTransactions =>
      status == ScanDetailStatus.success &&
      (detail?.transactions.isEmpty ?? false);

  ScanDetailState copyWith({
    ScanDetailStatus? status,
    OcrScanDetail? detail,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ScanDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, detail, failure];
}
