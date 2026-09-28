import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_budget_for_month.dart';
import 'budget_month_state.dart';

/// Drives the budget month screen (FR-005–FR-009, FR-018).
///
/// Holds no figures of its own: every [reload] re-derives the whole month
/// from `GetBudgetForMonth`, which reads 007's live expense data, so
/// returning from an expense edit anywhere in the app and refreshing is all
/// it takes for actual/remaining/percentage to reflect it (FR-005, US2
/// scenario 4).
@injectable
class BudgetMonthCubit extends Cubit<BudgetMonthState> {
  BudgetMonthCubit(this._getBudgetForMonth)
    : super(const BudgetMonthState(month: ''));

  final GetBudgetForMonth _getBudgetForMonth;

  /// Loads [month] (`'YYYY-MM'`) from scratch. Call once when the page
  /// opens; later refreshes of the same month go through [reload].
  Future<void> load(String month) {
    emit(BudgetMonthState(month: month));
    return reload();
  }

  /// Switches the screen to another month (FR-013) — what a month
  /// navigator calls. A no-op for the month already on screen.
  Future<void> monthChanged(String month) {
    if (month == state.month && !state.isFailure) return Future.value();
    return load(month);
  }

  /// Re-reads the current month, keeping what is on screen until the fresh
  /// figures arrive (pull-to-refresh, or on returning from another screen).
  Future<void> reload() async {
    final month = state.month;
    final result = await _getBudgetForMonth(month);
    // The month may have changed while this read was in flight; a stale
    // answer must never overwrite the newer month's state.
    if (isClosed || state.month != month) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: BudgetMonthStatus.failure, failure: failure),
      ),
      (detail) => emit(
        BudgetMonthState(
          month: month,
          status: BudgetMonthStatus.success,
          detail: detail,
        ),
      ),
    );
  }
}
