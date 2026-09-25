import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../../domain/entities/finance_summary.dart';

enum FinanceHistoryStatus { loading, success, failure }

/// The three period presets FR-016 requires at minimum. "This month" and
/// "last month" are resolved from `DateRange`'s own factories (research.md
/// Decision 6) rather than re-derived here; [custom] carries whatever range
/// the user picked.
enum FinancePeriodPreset { thisMonth, lastMonth, custom }

/// Immutable state for `FinanceHistoryCubit` (constitution Principle IV).
class FinanceHistoryState extends Equatable {
  FinanceHistoryState({
    DateRange? period,
    this.status = FinanceHistoryStatus.loading,
    this.periodPreset = FinancePeriodPreset.thisMonth,
    this.summary,
    this.breakdown = CategoryBreakdown.empty,
    this.entries = const [],
    this.categories = const [],
    this.typeFilter,
    this.categoryFilter,
    this.hasAnyEntry = false,
    this.pendingUndoEntryId,
    this.failure,
  }) : period = period ?? DateRange.thisMonth();

  final FinanceHistoryStatus status;

  /// The resolved inclusive `[start, end]` span every one of the three
  /// queries below was run against.
  final DateRange period;
  final FinancePeriodPreset periodPreset;

  final FinanceSummary? summary;
  final CategoryBreakdown breakdown;
  final List<FinanceEntry> entries;

  /// Every category of both directions, archived ones included, so a row
  /// whose category has since been archived still resolves a name and icon
  /// (FR-011).
  final List<Category> categories;

  final FinanceEntryType? typeFilter;
  final String? categoryFilter;

  /// FR-017: whether the user has ever recorded anything at all, which is
  /// the only thing that separates the true first-use empty state from
  /// "your filter matched nothing" (FR-018).
  final bool hasAnyEntry;

  /// The entry just soft-deleted, for as long as the undo affordance should
  /// stay on screen (research.md Decision 8). `null` once the window closes.
  final String? pendingUndoEntryId;

  final Failure? failure;

  bool get isLoading => status == FinanceHistoryStatus.loading;

  /// The currency the summary and breakdown are expressed in (018 FR-005)
  /// — what a history row compares its own currency against to decide
  /// whether it needs a currency chip.
  Currency get primaryCurrency => summary?.currency ?? breakdown.currency;
  bool get isFailure => status == FinanceHistoryStatus.failure;

  /// Category lookup for rendering a history row's name/icon without a
  /// per-row repository call.
  Map<String, Category> get categoriesById => {
    for (final category in categories) category.id: category,
  };

  /// Only the categories a filter control should offer: active ones, and
  /// narrowed to the selected direction when one is selected.
  List<Category> get filterableCategories => [
    for (final category in categories)
      if (category.isActive &&
          (typeFilter == null || category.type == typeFilter))
        category,
  ];

  /// FR-017 — the user has never recorded anything. Distinct from
  /// [isNoMatch]: the answer here is "start tracking", not "loosen your
  /// filter".
  bool get isTrueEmpty =>
      status == FinanceHistoryStatus.success && !hasAnyEntry;

  /// FR-018 — entries exist, but none of them fall inside the selected
  /// period/filter combination.
  bool get isNoMatch =>
      status == FinanceHistoryStatus.success && hasAnyEntry && entries.isEmpty;

  bool get hasFilters => typeFilter != null || categoryFilter != null;

  /// The filter the history query is actually run with — the period is part
  /// of it, so the list can never disagree with the totals above it.
  FinanceHistoryFilter get filter => FinanceHistoryFilter(
    type: typeFilter,
    categoryId: categoryFilter,
    dateRange: period,
  );

  FinanceHistoryState copyWith({
    FinanceHistoryStatus? status,
    DateRange? period,
    FinancePeriodPreset? periodPreset,
    FinanceSummary? summary,
    CategoryBreakdown? breakdown,
    List<FinanceEntry>? entries,
    List<Category>? categories,
    FinanceEntryType? typeFilter,
    bool clearTypeFilter = false,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    bool? hasAnyEntry,
    String? pendingUndoEntryId,
    bool clearPendingUndoEntryId = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return FinanceHistoryState(
      status: status ?? this.status,
      period: period ?? this.period,
      periodPreset: periodPreset ?? this.periodPreset,
      summary: summary ?? this.summary,
      breakdown: breakdown ?? this.breakdown,
      entries: entries ?? this.entries,
      categories: categories ?? this.categories,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      categoryFilter: clearCategoryFilter
          ? null
          : (categoryFilter ?? this.categoryFilter),
      hasAnyEntry: hasAnyEntry ?? this.hasAnyEntry,
      pendingUndoEntryId: clearPendingUndoEntryId
          ? null
          : (pendingUndoEntryId ?? this.pendingUndoEntryId),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    period,
    periodPreset,
    summary,
    breakdown,
    entries,
    categories,
    typeFilter,
    categoryFilter,
    hasAnyEntry,
    pendingUndoEntryId,
    failure,
  ];
}
