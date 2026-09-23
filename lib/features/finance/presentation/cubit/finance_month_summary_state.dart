import 'package:equatable/equatable.dart';

import '../../domain/entities/finance_summary.dart';

enum FinanceMonthSummaryStatus { loading, success, failure }

/// State for the Overview tab's "This month" finance card.
class FinanceMonthSummaryState extends Equatable {
  const FinanceMonthSummaryState({
    this.status = FinanceMonthSummaryStatus.loading,
    this.summary,
  });

  final FinanceMonthSummaryStatus status;
  final FinanceSummary? summary;

  bool get isLoading => status == FinanceMonthSummaryStatus.loading;

  /// The card hides itself rather than showing an error row: it is a
  /// secondary entry point on someone else's screen, and a finance read
  /// failing is no reason to put an error in the middle of the balances
  /// the user actually came to this tab for.
  bool get isHidden =>
      status == FinanceMonthSummaryStatus.failure || summary == null;

  FinanceMonthSummaryState copyWith({
    FinanceMonthSummaryStatus? status,
    FinanceSummary? summary,
  }) {
    return FinanceMonthSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [status, summary];
}
