import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/usecases/get_categories.dart';
import '../../domain/usecases/get_budget_trend.dart';
import 'budget_trend_state.dart';

/// Drives the spending trend view (US5, FR-014): planned vs. actual across
/// the most recent months, overall or for one selected category.
@injectable
class BudgetTrendCubit extends Cubit<BudgetTrendState> {
  BudgetTrendCubit(this._getBudgetTrend, this._getCategories)
    : super(const BudgetTrendState());

  final GetBudgetTrend _getBudgetTrend;
  final GetCategories _getCategories;

  /// The trend window FR-014 requires: the most recent 6 months.
  static const int monthsBack = 6;

  /// Bumped per trend request, so a slow answer for a category the user
  /// has already switched away from never overwrites the newer one.
  int _requestId = 0;

  /// Loads the category selector's options and the trend for the current
  /// selection. [endMonth] (`'YYYY-MM'`) defaults to the current month.
  Future<void> load({String? endMonth}) async {
    emit(
      state.copyWith(
        status: BudgetTrendStatus.loading,
        endMonth: endMonth,
        clearFailure: true,
      ),
    );

    // Active expense categories only: budgets allocate expense categories,
    // and an archived one is no longer something the user plans against.
    final categoriesResult = await _getCategories(type: CategoryType.expense);
    if (isClosed) return;
    final categoriesFailure = categoriesResult.getLeft().toNullable();
    if (categoriesFailure != null) {
      emit(
        state.copyWith(
          status: BudgetTrendStatus.failure,
          failure: categoriesFailure,
        ),
      );
      return;
    }
    final categories = categoriesResult.toNullable() ?? const [];
    // A selection that no longer resolves (archived or removed since) falls
    // back to the overall view rather than charting an unpickable category.
    final selectionStillValid =
        state.selectedCategoryId == null ||
        categories.any((c) => c.id == state.selectedCategoryId);
    emit(
      state.copyWith(
        categories: categories,
        clearSelectedCategory: !selectionStillValid,
      ),
    );
    await _loadTrend();
  }

  /// A `null` [categoryId] selects the overall view (US5 scenario 2).
  Future<void> categoryChanged(String? categoryId) async {
    if (categoryId == state.selectedCategoryId &&
        state.status == BudgetTrendStatus.success) {
      return;
    }
    emit(
      state.copyWith(
        status: BudgetTrendStatus.loading,
        selectedCategoryId: categoryId,
        clearSelectedCategory: categoryId == null,
        clearFailure: true,
      ),
    );
    await _loadTrend();
  }

  Future<void> _loadTrend() async {
    final requestId = ++_requestId;
    final result = await _getBudgetTrend(
      categoryId: state.selectedCategoryId,
      monthsBack: monthsBack,
      endMonth: state.endMonth,
    );
    if (isClosed || requestId != _requestId) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: BudgetTrendStatus.failure, failure: failure),
      ),
      (points) => emit(
        state.copyWith(
          status: BudgetTrendStatus.success,
          points: points,
          clearFailure: true,
        ),
      ),
    );
  }
}
