import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/budget.dart';

/// - [loading]: looking up the copy source for [CopyBudgetState.targetMonth].
/// - [ready]: the lookup finished — [CopyBudgetState.source] may still be
///   `null` (first-ever budget), in which case no copy is offered.
/// - [copying]: a copy is in flight; further taps are ignored.
/// - [success]: [CopyBudgetState.copiedBudget] holds the new budget.
/// - [loadFailure]: the source lookup itself failed.
/// - [copyFailure]: the copy failed; the source is kept so it can be retried.
enum CopyBudgetStatus {
  loading,
  ready,
  copying,
  success,
  loadFailure,
  copyFailure,
}

/// Immutable state for `CopyBudgetCubit` (constitution Principle IV —
/// updated exclusively via [copyWith]).
class CopyBudgetState extends Equatable {
  const CopyBudgetState({
    required this.idempotencyKey,
    this.targetMonth = '',
    this.status = CopyBudgetStatus.loading,
    this.source,
    this.failure,
    this.copiedBudget,
  });

  /// Generated when the cubit is created and regenerated after a successful
  /// copy. Kept across a failed copy, so a retry after an ambiguous failure
  /// resolves to the same budget rather than attempting a second one.
  final String idempotencyKey;

  /// `'YYYY-MM'` — the month the copy would create a budget for.
  final String targetMonth;
  final CopyBudgetStatus status;

  /// The most recent budget before [targetMonth] (FR-012), or `null` when
  /// the user has never budgeted an earlier month — the copy offer is then
  /// hidden rather than shown disabled (US4 acceptance scenario 3).
  final Budget? source;

  /// Typed, so the page decides the wording — e.g. a
  /// `BudgetAlreadyExistsForMonthFailure` can route to the existing budget.
  final Failure? failure;
  final Budget? copiedBudget;

  bool get hasSource => source != null;
  bool get isLoading => status == CopyBudgetStatus.loading;
  bool get isCopying => status == CopyBudgetStatus.copying;
  bool get isSuccess => status == CopyBudgetStatus.success;

  /// Whether the copy action should be enabled — the same rule `copy()`
  /// enforces, so the button can reflect it before it is tapped.
  bool get canCopy =>
      hasSource &&
      (status == CopyBudgetStatus.ready ||
          status == CopyBudgetStatus.copyFailure);

  CopyBudgetState copyWith({
    String? idempotencyKey,
    String? targetMonth,
    CopyBudgetStatus? status,
    Budget? source,
    bool clearSource = false,
    Failure? failure,
    bool clearFailure = false,
    Budget? copiedBudget,
  }) {
    return CopyBudgetState(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      targetMonth: targetMonth ?? this.targetMonth,
      status: status ?? this.status,
      source: clearSource ? null : (source ?? this.source),
      failure: clearFailure ? null : (failure ?? this.failure),
      copiedBudget: copiedBudget ?? this.copiedBudget,
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    targetMonth,
    status,
    source,
    failure,
    copiedBudget,
  ];
}
