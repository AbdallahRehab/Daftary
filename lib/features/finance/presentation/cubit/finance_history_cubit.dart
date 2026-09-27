import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../../domain/entities/finance_summary.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/usecases/delete_finance_entry.dart';
import '../../domain/usecases/get_category_breakdown.dart';
import '../../domain/usecases/restore_finance_entry.dart';
import '../../domain/usecases/watch_categories.dart';
import '../../domain/usecases/watch_finance_history.dart';
import '../../domain/usecases/watch_finance_summary.dart';
import 'finance_history_state.dart';

/// Drives the finance history screen: one selected period and filter set,
/// against which the summary (FR-014), the per-category breakdown (FR-015),
/// and the entry list (FR-012/FR-013) are always shown together — so the
/// three can never show different periods at the same time.
///
/// 021: the screen is live. The Cubit subscribes to the loaded history
/// window ([WatchFinanceHistory] with `limit: loadedCount`), the period's
/// summary ([WatchFinanceSummary]) and both directions' categories
/// ([WatchCategories]); every emission re-reads the breakdown and the
/// true-empty flag against the same period, so an add, delete, restore or
/// a synced change shows with no reload (FR-031). All subscriptions are
/// cancelled in [close].
@injectable
class FinanceHistoryCubit extends Cubit<FinanceHistoryState> {
  FinanceHistoryCubit(
    this._watchSummary,
    this._getBreakdown,
    this._watchHistory,
    this._watchCategories,
    this._deleteEntry,
    this._restoreEntry,
    this._repository,
  ) : super(FinanceHistoryState());

  final WatchFinanceSummary _watchSummary;
  final GetCategoryBreakdown _getBreakdown;
  final WatchFinanceHistory _watchHistory;
  final WatchCategories _watchCategories;
  final DeleteFinanceEntry _deleteEntry;
  final RestoreFinanceEntry _restoreEntry;

  /// Only ever used for `hasAnyEntry` — the true-empty vs. no-match
  /// distinction (FR-017/FR-018) is a repository-level question with no
  /// use case of its own.
  final FinanceRepository _repository;

  /// The history page size; [loadMore] widens the watched window by this.
  static const pageSize = 50;

  /// How long the undo affordance stays available after a delete
  /// (research.md Decision 8). Read by the page so the SnackBar and the
  /// Cubit's own window can never drift apart, and settable so a test can
  /// collapse it instead of really waiting five seconds.
  Duration undoWindow = const Duration(seconds: 5);

  Timer? _undoTimer;

  /// How many history rows the current subscription watches.
  int _loadedCount = pageSize;

  final _subscriptions = <StreamSubscription<void>>[];
  Completer<void>? _firstResult;

  /// Bumped by every subscription and every derived re-read, so a stale
  /// read never overwrites a newer one.
  int _generation = 0;

  Either<Failure, List<FinanceEntry>>? _entries;
  Either<Failure, FinanceSummary>? _summary;
  Either<Failure, List<Category>>? _expenseCategories;
  Either<Failure, List<Category>>? _incomeCategories;

  /// Subscribes for the default period ("this month") and shows everything
  /// the screen renders. The returned future completes once the first
  /// complete result has been emitted.
  Future<void> subscribe() {
    emit(state.copyWith(status: FinanceHistoryStatus.loading));
    return _subscribe();
  }

  /// Retry and pull to refresh: subscribes again from scratch.
  Future<void> resubscribe() => subscribe();

  /// "Load more": widens the watched history window by [pageSize] without
  /// a loading state, so the list keeps its scroll position.
  Future<void> loadMore() {
    _loadedCount += pageSize;
    return _subscribe();
  }

  Future<void> _subscribe() {
    _cancelSubscriptions();
    _generation++;
    _entries = null;
    _summary = null;
    _expenseCategories = null;
    _incomeCategories = null;

    final firstResult = _firstResult = Completer<void>();
    _subscriptions.addAll([
      _watchHistory(
        filter: state.filter,
        limit: _loadedCount,
      ).listen((result) => _onChange(() => _entries = result)),
      _watchSummary(
        state.period,
      ).listen((result) => _onChange(() => _summary = result)),
      // Archived categories included: an entry filed under one before it
      // was archived still has to resolve a name and an icon (FR-011).
      _watchCategories(
        type: CategoryType.expense,
        includeArchived: true,
      ).listen((result) => _onChange(() => _expenseCategories = result)),
      _watchCategories(
        type: CategoryType.income,
        includeArchived: true,
      ).listen((result) => _onChange(() => _incomeCategories = result)),
    ]);
    return firstResult.future;
  }

  /// Records [change]; once every stream has delivered, re-reads the
  /// breakdown and the true-empty flag and emits the whole screen.
  Future<void> _onChange(void Function() change) async {
    if (isClosed) return;
    change();
    final entries = _entries;
    final summary = _summary;
    final expenseCategories = _expenseCategories;
    final incomeCategories = _incomeCategories;
    if (entries == null ||
        summary == null ||
        expenseCategories == null ||
        incomeCategories == null) {
      return;
    }
    final generation = ++_generation;

    final streamed = <Either<Failure, Object>>[
      expenseCategories,
      incomeCategories,
      summary,
      entries,
    ];
    for (final result in streamed) {
      final failure = result.getLeft().toNullable();
      if (failure != null) return _finish(() => _emitFailure(failure));
    }

    final hasAnyEntryResult = await _repository.hasAnyEntry();
    if (generation != _generation || isClosed) return;
    final hasAnyEntryFailure = hasAnyEntryResult.getLeft().toNullable();
    if (hasAnyEntryFailure != null) {
      return _finish(() => _emitFailure(hasAnyEntryFailure));
    }

    final breakdownResult = await _getBreakdown(
      state.period,
      type: state.typeFilter,
    );
    if (generation != _generation || isClosed) return;
    final breakdownFailure = breakdownResult.getLeft().toNullable();
    if (breakdownFailure != null) {
      return _finish(() => _emitFailure(breakdownFailure));
    }

    _finish(
      () => emit(
        state.copyWith(
          status: FinanceHistoryStatus.success,
          hasAnyEntry: hasAnyEntryResult.toNullable() ?? false,
          categories: [
            ...expenseCategories.toNullable() ?? const <Category>[],
            ...incomeCategories.toNullable() ?? const <Category>[],
          ],
          summary: summary.toNullable(),
          breakdown: breakdownResult.toNullable() ?? CategoryBreakdown.empty,
          entries: entries.toNullable() ?? const [],
          clearFailure: true,
        ),
      ),
    );
  }

  void _finish(void Function() emitResult) {
    emitResult();
    _completeFirstResult();
  }

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
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
    await _subscribe();
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
    await _subscribe();
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
    await _subscribe();
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
    await _subscribe();
  }

  /// FR-020: the soft delete commits immediately (research.md Decision 8),
  /// and [FinanceHistoryState.pendingUndoEntryId] carries the just-deleted
  /// id for as long as the undo affordance should stay up. The live
  /// subscription drops the row and recalculates the totals.
  Future<void> deleteEntry(String entryId) async {
    final result = await _deleteEntry(entryId);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      _emitFailure(failure);
      return;
    }
    _undoTimer?.cancel();
    emit(state.copyWith(pendingUndoEntryId: entryId));
    _undoTimer = Timer(undoWindow, () {
      if (isClosed) return;
      emit(state.copyWith(clearPendingUndoEntryId: true));
    });
  }

  /// Reverses a delete while its window is still open. A late or duplicate
  /// tap is harmless — `RestoreFinanceEntry` treats an already-active entry
  /// as a quiet success. The live subscription brings the row back.
  Future<void> undoDelete(String entryId) async {
    _undoTimer?.cancel();
    final result = await _restoreEntry(entryId);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      _emitFailure(failure);
      return;
    }
    emit(state.copyWith(clearPendingUndoEntryId: true));
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
      state.copyWith(status: FinanceHistoryStatus.failure, failure: failure),
    );
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    // A superseded subscription will never deliver; release its waiter.
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _undoTimer?.cancel();
    _cancelSubscriptions();
    return super.close();
  }
}
