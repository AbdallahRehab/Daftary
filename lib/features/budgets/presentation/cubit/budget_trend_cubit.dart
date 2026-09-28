import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/category.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/usecases/watch_categories.dart';
import '../../domain/entities/budget_trend_point.dart';
import '../../domain/usecases/watch_budget_trend.dart';
import 'budget_trend_state.dart';

/// Drives the spending trend view (US5, FR-014): planned vs. actual across
/// the most recent months, overall or for one selected category.
///
/// 021: the view is live. The Cubit subscribes to the selector's categories
/// ([WatchCategories]) and to the trend for the current selection
/// ([WatchBudgetTrend]), so a budget, an expense, a category or a rate
/// changed anywhere — or applied by sync — updates the chart with no reload
/// (FR-031). Changing the selection replaces only the trend subscription;
/// both are cancelled in [close].
@injectable
class BudgetTrendCubit extends Cubit<BudgetTrendState> {
  BudgetTrendCubit(this._watchBudgetTrend, this._watchCategories)
    : super(const BudgetTrendState());

  final WatchBudgetTrend _watchBudgetTrend;
  final WatchCategories _watchCategories;

  /// The trend window FR-014 requires: the most recent 6 months.
  static const int monthsBack = 6;

  StreamSubscription<void>? _categoriesSubscription;
  StreamSubscription<void>? _trendSubscription;
  Completer<void>? _firstResult;

  Either<Failure, List<Category>>? _categories;
  Either<Failure, List<BudgetTrendPoint>>? _points;

  /// Subscribes to the category selector's options and the trend for the
  /// current selection, replacing any earlier subscription. [endMonth]
  /// (`'YYYY-MM'`) defaults to the current month. The returned future
  /// completes once the first complete result has been emitted.
  Future<void> subscribe({String? endMonth}) {
    _cancelSubscriptions();
    _categories = null;
    emit(
      state.copyWith(
        status: BudgetTrendStatus.loading,
        endMonth: endMonth,
        clearFailure: true,
      ),
    );

    final firstResult = _firstResult = Completer<void>();
    // Active expense categories only: budgets allocate expense categories,
    // and an archived one is no longer something the user plans against.
    _categoriesSubscription = _watchCategories(
      type: CategoryType.expense,
    ).listen(_onCategories);
    _subscribeTrend();
    return firstResult.future;
  }

  /// Retry: subscribes again, from scratch, to the window on screen.
  Future<void> resubscribe() => subscribe(endMonth: state.endMonth);

  /// A `null` [categoryId] selects the overall view (US5 scenario 2).
  Future<void> categoryChanged(String? categoryId) {
    if (categoryId == state.selectedCategoryId &&
        state.status == BudgetTrendStatus.success) {
      return Future.value();
    }
    _completeFirstResult();
    final firstResult = _firstResult = Completer<void>();
    emit(
      state.copyWith(
        status: BudgetTrendStatus.loading,
        selectedCategoryId: categoryId,
        clearSelectedCategory: categoryId == null,
        clearFailure: true,
      ),
    );
    _subscribeTrend();
    return firstResult.future;
  }

  /// Replaces the trend subscription with one for the current selection; a
  /// superseded one never delivers, so a slow answer for a category the
  /// user has already switched away from can never overwrite the newer one.
  void _subscribeTrend() {
    _trendSubscription?.cancel();
    _points = null;
    _trendSubscription = _watchBudgetTrend(
      categoryId: state.selectedCategoryId,
      monthsBack: monthsBack,
      endMonth: state.endMonth,
    ).listen(_onPoints);
  }

  void _onCategories(Either<Failure, List<Category>> result) {
    if (isClosed) return;
    _categories = result;
    final categories = result.toNullable();
    final selected = state.selectedCategoryId;
    // A selection that no longer resolves (archived or removed since) falls
    // back to the overall view rather than charting an unpickable category.
    if (categories != null &&
        selected != null &&
        !categories.any((c) => c.id == selected)) {
      emit(
        state.copyWith(
          status: BudgetTrendStatus.loading,
          categories: categories,
          clearSelectedCategory: true,
        ),
      );
      _subscribeTrend();
      return;
    }
    _emitIfComplete();
  }

  void _onPoints(Either<Failure, List<BudgetTrendPoint>> result) {
    if (isClosed) return;
    _points = result;
    _emitIfComplete();
  }

  /// Emits once both the categories and the trend have arrived.
  void _emitIfComplete() {
    final categories = _categories;
    final points = _points;
    if (categories == null || points == null) return;

    final failure =
        categories.getLeft().toNullable() ?? points.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(status: BudgetTrendStatus.failure, failure: failure));
    } else {
      emit(
        state.copyWith(
          status: BudgetTrendStatus.success,
          categories: categories.toNullable(),
          points: points.toNullable(),
          clearFailure: true,
        ),
      );
    }
    _completeFirstResult();
  }

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscriptions() {
    _categoriesSubscription?.cancel();
    _trendSubscription?.cancel();
    _categoriesSubscription = null;
    _trendSubscription = null;
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
