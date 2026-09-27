import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/finance_history_filter.dart';
import '../../domain/usecases/watch_finance_summary.dart';
import 'finance_month_summary_state.dart';

/// Just this month's income/expense totals for the Overview tab's finance
/// card (research.md Decision 9's entry-point seam).
///
/// Deliberately narrower than `FinanceHistoryCubit`: this is a link with a
/// number on it, not a screen, so it reads one summary rather than pulling
/// the breakdown, history, and category set the full page needs. V1.5.2's
/// Home Dashboard is where a real cross-feature aggregate belongs.
///
/// 021: a live [WatchFinanceSummary] subscription, cancelled in [close] —
/// the totals follow entry, rate and primary-currency changes (FR-031).
@injectable
class FinanceMonthSummaryCubit extends Cubit<FinanceMonthSummaryState> {
  FinanceMonthSummaryCubit(this._watchFinanceSummary)
    : super(const FinanceMonthSummaryState());

  final WatchFinanceSummary _watchFinanceSummary;

  StreamSubscription<void>? _subscription;

  /// Subscribes to this month's summary, replacing any earlier
  /// subscription.
  void subscribe() {
    _subscription?.cancel();
    _subscription = _watchFinanceSummary(DateRange.thisMonth()).listen((
      result,
    ) {
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
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
