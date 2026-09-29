import 'package:equatable/equatable.dart';

import '../../../finance/domain/entities/finance_summary.dart';
import '../../../savings/domain/entities/savings_overview.dart';
import '../../../transactions/domain/entities/overview_summary.dart';
import 'load_status.dart';

/// Immutable state for `DashboardCubit` (data-model.md "Entity:
/// DashboardState", constitution Principle IV).
///
/// The balances ("overview") and this-month finance aggregates each carry
/// their own status, data, and error, and nothing collapses them into one
/// combined status (research.md Decision 2) — so one side failing never
/// hides the other (FR-003). Everything the page branches on beyond these
/// fields is a derived getter, never stored.
class DashboardState extends Equatable {
  const DashboardState({
    this.overviewStatus = LoadStatus.loading,
    this.overviewSummary,
    this.overviewError,
    this.financeStatus = LoadStatus.loading,
    this.financeSummary,
    this.financeError,
    this.isCombinedEmpty = false,
    this.upcomingSavingsGoals = const [],
  });

  final LoadStatus overviewStatus;

  /// Present once [overviewStatus] is [LoadStatus.success].
  final OverviewSummary? overviewSummary;

  /// The failure's message once [overviewStatus] is [LoadStatus.failure].
  /// Diagnostic only — the page shows localized copy, never this string.
  final String? overviewError;

  final LoadStatus financeStatus;

  /// This month's totals, present once [financeStatus] is
  /// [LoadStatus.success].
  final FinanceSummary? financeSummary;

  /// The failure's message once [financeStatus] is [LoadStatus.failure].
  /// Diagnostic only, like [overviewError].
  final String? financeError;

  /// Zero people and no finance entry ever recorded (FR-005, research.md
  /// Decision 3). Only ever `true` while both sides are
  /// [LoadStatus.success]; a partial error is never an empty state.
  final bool isCombinedEmpty;

  /// Home's Upcoming section (012 FR-010, 011 FR-031): active, not yet
  /// achieved savings goals with a target date, soonest first, exactly as
  /// 011's `WatchUpcomingSavingsGoals` returned them. Empty while loading,
  /// when there are none, and when the read failed — Home then shows its
  /// honest empty state, never a fabricated item. Independent of both
  /// snapshot sides, so it never affects their status.
  final List<GoalOverviewLine> upcomingSavingsGoals;

  /// Both sides still loading — the initial full-screen loading gate
  /// (FR-002).
  bool get isFullyLoading =>
      overviewStatus == LoadStatus.loading &&
      financeStatus == LoadStatus.loading;

  /// Both sides failed — the single full-screen error with one combined
  /// retry (FR-004).
  bool get isFullFailure =>
      overviewStatus == LoadStatus.failure &&
      financeStatus == LoadStatus.failure;

  /// Exactly one side failed while the other loaded — each card renders its
  /// own inline error and retry (FR-003).
  bool get isAnyPartialError =>
      (overviewStatus == LoadStatus.failure &&
          financeStatus == LoadStatus.success) ||
      (overviewStatus == LoadStatus.success &&
          financeStatus == LoadStatus.failure);

  /// The balances loaded with zero outstanding anywhere — an explicit "all
  /// settled" state distinct from loading/empty (carried over from the
  /// retired `OverviewState`, 001 US4 AC3).
  bool get isAllSettled =>
      overviewStatus == LoadStatus.success &&
      (overviewSummary?.isAllSettled ?? false);

  /// Nullable fields keep their current value unless replaced or explicitly
  /// cleared with the matching `clear*` flag, so updating one side can
  /// never silently wipe the other side's data or error.
  DashboardState copyWith({
    LoadStatus? overviewStatus,
    OverviewSummary? overviewSummary,
    bool clearOverviewSummary = false,
    String? overviewError,
    bool clearOverviewError = false,
    LoadStatus? financeStatus,
    FinanceSummary? financeSummary,
    bool clearFinanceSummary = false,
    String? financeError,
    bool clearFinanceError = false,
    bool? isCombinedEmpty,
    List<GoalOverviewLine>? upcomingSavingsGoals,
  }) {
    return DashboardState(
      overviewStatus: overviewStatus ?? this.overviewStatus,
      overviewSummary: clearOverviewSummary
          ? null
          : (overviewSummary ?? this.overviewSummary),
      overviewError: clearOverviewError
          ? null
          : (overviewError ?? this.overviewError),
      financeStatus: financeStatus ?? this.financeStatus,
      financeSummary: clearFinanceSummary
          ? null
          : (financeSummary ?? this.financeSummary),
      financeError: clearFinanceError
          ? null
          : (financeError ?? this.financeError),
      isCombinedEmpty: isCombinedEmpty ?? this.isCombinedEmpty,
      upcomingSavingsGoals: upcomingSavingsGoals ?? this.upcomingSavingsGoals,
    );
  }

  @override
  List<Object?> get props => [
    overviewStatus,
    overviewSummary,
    overviewError,
    financeStatus,
    financeSummary,
    financeError,
    isCombinedEmpty,
    upcomingSavingsGoals,
  ];
}
