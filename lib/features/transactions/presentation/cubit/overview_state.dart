import 'package:equatable/equatable.dart';

import '../../domain/entities/overview_summary.dart';

enum OverviewStatus { loading, success, failure }

/// Immutable state for [OverviewCubit] (constitution Principle IV).
class OverviewState extends Equatable {
  const OverviewState({
    this.status = OverviewStatus.loading,
    this.summary,
    this.errorMessage,
  });

  final OverviewStatus status;
  final OverviewSummary? summary;
  final String? errorMessage;

  bool get isLoading => status == OverviewStatus.loading;

  /// An explicit "all settled" flag distinct from loading/empty (US4 AC3) —
  /// true once loaded successfully with zero outstanding balances anywhere.
  bool get isAllSettled =>
      status == OverviewStatus.success && (summary?.isAllSettled ?? false);

  OverviewState copyWith({
    OverviewStatus? status,
    OverviewSummary? summary,
    String? errorMessage,
  }) {
    return OverviewState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
