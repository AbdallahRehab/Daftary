import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/usecases/delete_finance_entry.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_category_breakdown.dart';
import '../../domain/usecases/get_finance_history.dart';
import '../../domain/usecases/get_finance_summary.dart';
import '../../domain/usecases/restore_finance_entry.dart';
import 'finance_history_state.dart';

/// Drives the finance history screen: one selected period and filter set,
/// against which the summary (FR-014), the per-category breakdown (FR-015),
/// and the entry list (FR-012/FR-013) are always loaded together — so the
/// three can never show different periods at the same time.
@injectable
class FinanceHistoryCubit extends Cubit<FinanceHistoryState> {
  FinanceHistoryCubit(
    this._getSummary,
    this._getBreakdown,
    this._getHistory,
    this._getCategories,
    this._deleteEntry,
    this._restoreEntry,
    this._repository,
  ) : super(FinanceHistoryState());

  final GetFinanceSummary _getSummary;
  final GetCategoryBreakdown _getBreakdown;
  final GetFinanceHistory _getHistory;
  final GetCategories _getCategories;
  final DeleteFinanceEntry _deleteEntry;
  final RestoreFinanceEntry _restoreEntry;

  /// Only ever used for `hasAnyEntry` — the true-empty vs. no-match
  /// distinction (FR-017/FR-018) is a repository-level question with no
  /// use case of its own.
  final FinanceRepository _repository;

  /// How long the undo affordance stays available after a delete
  /// (research.md Decision 8). Read by the page so the SnackBar and the
  /// Cubit's own window can never drift apart, and settable so a test can
  /// collapse it instead of really waiting five seconds.
  Duration undoWindow = const Duration(seconds: 5);

  Timer? _undoTimer;

  /// Resolves the default period ("this month") and loads everything the
  /// screen renders in one pass.
  Future<void> load() async {
    emit(state.copyWith(status: FinanceHistoryStatus.loading));
    await _reload();
  }

  /// FR-016: switching the period recalculates the summary, the breakdown,
  /// and the history list — never just one of them.
  ///
  /// [customRange] is required for [FinancePeriodPreset.custom] and ignored
  /// for the two fixed presets, whose bounds come from `DateRange`'s own
  /// factories.
  Future<void> periodChanged(
    FinancePeriodPreset preset, {
    DateRange? customRange,
  }) async {
    final period = switch (preset) {
      FinancePeriodPreset.thisMonth => DateRange.thisMonth(),
      FinancePeriodPreset.lastMonth => DateRange.lastMonth(),
      FinancePeriodPreset.custom => customRange ?? state.period,
    };
    emit(
      state.copyWith(
        status: FinanceHistoryStatus.loading,
        periodPreset: preset,
        period: period,
      ),
    );
    await _reload();
  }

  /// A `null` [type] means "both directions" (the `filterAll` option).
  /// A category filter that belongs to the other direction is dropped
  /// rather than left in place selecting nothing.
  Future<void> typeFilterChanged(FinanceEntryType? type) async {
    final selectedCategory = _categoryById(state.categoryFilter);
    final categoryStillApplies =
        selectedCategory != null &&
        (type == null || selectedCategory.type == type);
    emit(
      state.copyWith(
        status: FinanceHistoryStatus.loading,
        typeFilter: type,
        clearTypeFilter: type == null,
        clearCategoryFilter: !categoryStillApplies,
      ),
    );
    await _reload();
  }

  /// A `null` [categoryId] means "all categories".
  Future<void> categoryFilterChanged(String? categoryId) async {
    emit(
      state.copyWith(
        status: FinanceHistoryStatus.loading,
        categoryFilter: categoryId,
        clearCategoryFilter: categoryId == null,
      ),
    );
    await _reload();
  }

  /// Drops the type and category filters, keeping the selected period —
  /// what the no-match state's escape hatch calls.
  Future<void> clearFilters() async {
    emit(
      state.copyWith(
        status: FinanceHistoryStatus.loading,
        clearTypeFilter: true,
        clearCategoryFilter: true,
      ),
    );
    await _reload();
  }

  /// FR-020: the soft delete commits immediately (research.md Decision 8),
  /// and [FinanceHistoryState.pendingUndoEntryId] carries the just-deleted
  /// id for as long as the undo affordance should stay up.
  Future<void> deleteEntry(String entryId) async {
    final result = await _deleteEntry(entryId);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      _emitFailure(failure);
      return;
    }
    _undoTimer?.cancel();
    emit(state.copyWith(pendingUndoEntryId: entryId));
    await _reload();
    _undoTimer = Timer(undoWindow, () {
      if (isClosed) return;
      emit(state.copyWith(clearPendingUndoEntryId: true));
    });
  }

  /// Reverses a delete while its window is still open. A late or duplicate
  /// tap is harmless — `RestoreFinanceEntry` treats an already-active entry
  /// as a quiet success.
  Future<void> undoDelete(String entryId) async {
    _undoTimer?.cancel();
    final result = await _restoreEntry(entryId);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      _emitFailure(failure);
      return;
    }
    emit(state.copyWith(clearPendingUndoEntryId: true));
    await _reload();
  }

  /// The single place the three period-scoped queries are issued, so they
  /// are always run against the same period and filter.
  Future<void> _reload() async {
    final period = state.period;

    final hasAnyEntryResult = await _repository.hasAnyEntry();
    final hasAnyEntryFailure = hasAnyEntryResult.getLeft().toNullable();
    if (hasAnyEntryFailure != null) return _emitFailure(hasAnyEntryFailure);
    final hasAnyEntry = hasAnyEntryResult.toNullable() ?? false;

    final categories = <Category>[];
    for (final type in CategoryType.values) {
      // Archived categories included: an entry filed under one before it was
      // archived still has to resolve a name and an icon (FR-011).
      final result = await _getCategories(type: type, includeArchived: true);
      final failure = result.getLeft().toNullable();
      if (failure != null) return _emitFailure(failure);
      categories.addAll(result.toNullable() ?? const []);
    }

    final summaryResult = await _getSummary(period);
    final summaryFailure = summaryResult.getLeft().toNullable();
    if (summaryFailure != null) return _emitFailure(summaryFailure);

    final breakdownResult = await _getBreakdown(period, type: state.typeFilter);
    final breakdownFailure = breakdownResult.getLeft().toNullable();
    if (breakdownFailure != null) return _emitFailure(breakdownFailure);

    final historyResult = await _getHistory(filter: state.filter);
    final historyFailure = historyResult.getLeft().toNullable();
    if (historyFailure != null) return _emitFailure(historyFailure);

    emit(
      state.copyWith(
        status: FinanceHistoryStatus.success,
        hasAnyEntry: hasAnyEntry,
        categories: categories,
        summary: summaryResult.toNullable(),
        breakdown: breakdownResult.toNullable() ?? const [],
        entries: historyResult.toNullable() ?? const [],
        clearErrorMessage: true,
      ),
    );
  }

  Category? _categoryById(String? id) {
    if (id == null) return null;
    for (final category in state.categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  void _emitFailure(Failure failure) {
    emit(
      state.copyWith(
        status: FinanceHistoryStatus.failure,
        errorMessage: failure.message,
      ),
    );
  }

  @override
  Future<void> close() {
    _undoTimer?.cancel();
    return super.close();
  }
}
