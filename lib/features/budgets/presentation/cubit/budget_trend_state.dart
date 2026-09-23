import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/category.dart';
import '../../domain/entities/budget_trend_point.dart';

enum BudgetTrendStatus { loading, success, failure }

/// Immutable state for `BudgetTrendCubit` (constitution Principle IV —
/// updated exclusively via [copyWith]).
class BudgetTrendState extends Equatable {
  const BudgetTrendState({
    this.status = BudgetTrendStatus.loading,
    this.points = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.endMonth,
    this.failure,
  });

  final BudgetTrendStatus status;

  /// Oldest month first, exactly as `GetBudgetTrend` returns them — every
  /// month in the window, budgeted or not.
  final List<BudgetTrendPoint> points;

  /// Active expense categories the selector offers (budgets allocate
  /// expense categories only).
  final List<Category> categories;

  /// `null` means the overall planned-vs-actual view (US5 scenario 2).
  final String? selectedCategoryId;

  /// The last month of the window (`'YYYY-MM'`); `null` means the current
  /// month.
  final String? endMonth;

  final Failure? failure;

  bool get isLoading => status == BudgetTrendStatus.loading;
  bool get isFailure => status == BudgetTrendStatus.failure;

  /// FR-014's "not enough history yet" state: loaded fine, but fewer than
  /// `budgetTrendMinimumBudgetedMonths` months in the window had a budget.
  bool get isInsufficientHistory =>
      status == BudgetTrendStatus.success && !points.hasEnoughHistory;

  /// Whether the chart has something meaningful to show.
  bool get showsChart =>
      status == BudgetTrendStatus.success && points.hasEnoughHistory;

  Category? get selectedCategory {
    final id = selectedCategoryId;
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  BudgetTrendState copyWith({
    BudgetTrendStatus? status,
    List<BudgetTrendPoint>? points,
    List<Category>? categories,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? endMonth,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return BudgetTrendState(
      status: status ?? this.status,
      points: points ?? this.points,
      categories: categories ?? this.categories,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      endMonth: endMonth ?? this.endMonth,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    points,
    categories,
    selectedCategoryId,
    endMonth,
    failure,
  ];
}
