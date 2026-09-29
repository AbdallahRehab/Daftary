import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/savings_overview.dart';

enum SavingsOverviewStatus { loading, success, failure }

/// Immutable state for `SavingsOverviewCubit` (constitution Principle IV).
class SavingsOverviewState extends Equatable {
  const SavingsOverviewState({
    this.status = SavingsOverviewStatus.loading,
    this.overview,
    this.failure,
  });

  final SavingsOverviewStatus status;

  /// The active goals and their combined total, loaded together so the
  /// total can never disagree with the cards beneath it.
  final SavingsOverview? overview;
  final Failure? failure;

  bool get isLoading => status == SavingsOverviewStatus.loading;

  /// Loaded, with no active goals — FR-023's empty state.
  bool get isEmpty =>
      status == SavingsOverviewStatus.success && (overview?.isEmpty ?? true);

  /// Some goal needs a missing rate, so the total leaves it out (FR-019).
  bool get isIncomplete => overview?.isIncomplete ?? false;

  SavingsOverviewState copyWith({
    SavingsOverviewStatus? status,
    SavingsOverview? overview,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SavingsOverviewState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, overview, failure];
}
