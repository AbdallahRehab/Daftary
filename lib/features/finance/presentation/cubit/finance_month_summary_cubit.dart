import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/finance_history_filter.dart';
import '../../domain/usecases/get_finance_summary.dart';
import 'finance_month_summary_state.dart';

/// Loads just this month's income/expense totals for the Overview tab's
/// finance card (research.md Decision 9's entry-point seam).
///
/// Deliberately narrower than `FinanceHistoryCubit`: this is a link with a
/// number on it, not a screen, so it reads one summary rather than pulling
/// the breakdown, history, and category set the full page needs. V1.5.2's
/// Home Dashboard is where a real cross-feature aggregate belongs.
@injectable
class FinanceMonthSummaryCubit extends Cubit<FinanceMonthSummaryState> {
  FinanceMonthSummaryCubit(this._getFinanceSummary)
    : super(const FinanceMonthSummaryState());

  final GetFinanceSummary _getFinanceSummary;

  Future<void> load() async {
    final result = await _getFinanceSummary(DateRange.thisMonth());
    if (isClosed) return;
    result.match(
      (_) => emit(state.copyWith(status: FinanceMonthSummaryStatus.failure)),
      (summary) => emit(
        FinanceMonthSummaryState(
          status: FinanceMonthSummaryStatus.success,
          summary: summary,
        ),
      ),
    );
  }
}
