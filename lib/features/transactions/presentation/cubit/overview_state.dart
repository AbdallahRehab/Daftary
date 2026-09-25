import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/overview_summary.dart';

enum OverviewStatus { loading, success, failure }

/// Immutable state for [OverviewCubit] (constitution Principle IV).
class OverviewState extends Equatable {
  const OverviewState({
    this.status = OverviewStatus.loading,
    this.summary,
    this.failure,
  });

  final OverviewStatus status;
  final OverviewSummary? summary;
  final Failure? failure;

  bool get isLoading => status == OverviewStatus.loading;

  /// An explicit "all settled" flag distinct from loading/empty (US4 AC3) —
  /// true once loaded successfully with zero outstanding balances anywhere.
  bool get isAllSettled =>
      status == OverviewStatus.success && (summary?.isAllSettled ?? false);

  OverviewState copyWith({
    OverviewStatus? status,
    OverviewSummary? summary,
    Failure? failure,
  }) {
    return OverviewState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, summary, failure];
}
