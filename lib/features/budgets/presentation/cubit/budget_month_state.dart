import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/budget_summary.dart';

enum BudgetMonthStatus { loading, success, failure }

/// Immutable state for `BudgetMonthCubit` (constitution Principle IV).
class BudgetMonthState extends Equatable {
  const BudgetMonthState({
    required this.month,
    this.status = BudgetMonthStatus.loading,
    this.detail,
    this.failure,
  });

  /// `'YYYY-MM'` — the month currently on screen.
  final String month;
  final BudgetMonthStatus status;

  /// The month's budget, computed summary and unbudgeted spending, read
  /// together so the overall card and the rows beneath it can never be a
  /// moment apart and disagree (FR-006).
  ///
  /// Kept through a refresh (rather than cleared) so pull-to-refresh never
  /// blanks the screen; cleared when the month itself changes.
  final BudgetMonthDetail? detail;
  final Failure? failure;

  bool get isLoading => status == BudgetMonthStatus.loading;
  bool get isFailure => status == BudgetMonthStatus.failure;
  bool get hasBudget => detail?.hasBudget ?? false;

  /// FR-018 — the month loaded fine and simply has no budget yet: offer to
  /// create one (or copy one forward), never an error.
  bool get isEmpty => status == BudgetMonthStatus.success && !hasBudget;

  BudgetMonthState copyWith({
    BudgetMonthStatus? status,
    BudgetMonthDetail? detail,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return BudgetMonthState(
      month: month,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [month, status, detail, failure];
}
