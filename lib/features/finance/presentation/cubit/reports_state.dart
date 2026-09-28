import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../../domain/entities/spending_trend_point.dart';

/// The whole screen's lifecycle. [empty] is the true first-use state
/// (FR-004) — no finance entry recorded anywhere — distinct from a period
/// that merely has no expenses.
enum ReportsStatus { loading, success, empty, failure }

/// The breakdown section's own lifecycle, so switching its period can show
/// progress or fail inline without disturbing the trend above it (spec US1
/// AC3).
enum ReportsBreakdownStatus { loading, success, failure }

/// The breakdown's selectable windows. Each resolves through [range] at
/// query time, so "this month" is always the current month even on a
/// screen left open across midnight at month end.
enum ReportsPeriod {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months;

  /// The inclusive span this preset covers relative to [reference]
  /// (default: now). The two single-month presets reuse `DateRange`'s own
  /// factories, so they match the finance history screen's presets exactly.
  DateRange range([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return switch (this) {
      ReportsPeriod.thisMonth => DateRange.thisMonth(now),
      ReportsPeriod.lastMonth => DateRange.lastMonth(now),
      ReportsPeriod.last3Months => DateRange(
        start: DateTime(now.year, now.month - 2),
        end: now,
      ),
      ReportsPeriod.last6Months => DateRange(
        start: DateTime(now.year, now.month - 5),
        end: now,
      ),
    };
  }
}

/// Immutable state for `ReportsCubit` (constitution Principle IV).
class ReportsState extends Equatable {
  const ReportsState({
    this.status = ReportsStatus.loading,
    this.trend = const [],
    this.breakdownPeriod = ReportsPeriod.thisMonth,
    this.breakdown = CategoryBreakdown.empty,
    this.breakdownStatus = ReportsBreakdownStatus.loading,
    this.failure,
  });

  final ReportsStatus status;

  /// Oldest month first, exactly as `GetSpendingTrend` returned it.
  final List<SpendingTrendPoint> trend;

  final ReportsPeriod breakdownPeriod;

  /// Expense categories for [breakdownPeriod], as 007's
  /// `GetCategoryBreakdown` returned them (FR-002/FR-003) — blocked when a
  /// currency in the period has no exchange rate (018 FR-009).
  final CategoryBreakdown breakdown;
  final ReportsBreakdownStatus breakdownStatus;

  /// The last failure, for the page to describe with localized copy
  /// (`messageFor`) — never its raw message.
  final Failure? failure;

  bool get isLoading => status == ReportsStatus.loading;
  bool get isFailure => status == ReportsStatus.failure;
  bool get isEmpty => status == ReportsStatus.empty;
  bool get isSuccess => status == ReportsStatus.success;

  ReportsState copyWith({
    ReportsStatus? status,
    List<SpendingTrendPoint>? trend,
    ReportsPeriod? breakdownPeriod,
    CategoryBreakdown? breakdown,
    ReportsBreakdownStatus? breakdownStatus,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ReportsState(
      status: status ?? this.status,
      trend: trend ?? this.trend,
      breakdownPeriod: breakdownPeriod ?? this.breakdownPeriod,
      breakdown: breakdown ?? this.breakdown,
      breakdownStatus: breakdownStatus ?? this.breakdownStatus,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    trend,
    breakdownPeriod,
    breakdown,
    breakdownStatus,
    failure,
  ];
}
