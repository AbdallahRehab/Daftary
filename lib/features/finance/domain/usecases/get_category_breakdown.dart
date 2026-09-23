import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/category_breakdown_item.dart';
import '../entities/finance_entry_type.dart';
import '../entities/finance_history_filter.dart';
import '../repositories/finance_repository.dart';

/// Per-category totals for a period, largest first, each carrying its share
/// of the period (FR-015).
@injectable
class GetCategoryBreakdown {
  const GetCategoryBreakdown(this._repository);

  final FinanceRepository _repository;

  Future<Either<Failure, List<CategoryBreakdownItem>>> call(
    DateRange period, {
    FinanceEntryType? type,
  }) {
    return _repository.getCategoryBreakdown(period, type: type);
  }
}
