import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/category.dart';
import '../entities/finance_entry_type.dart';
import '../repositories/category_repository.dart';

/// Confirms the starter category set is present (FR-006).
///
/// A read-through check, not a writer: the seeding itself happens once in
/// the database's own open path, where it can be made atomic with the
/// schema that holds it. This use case exists so callers and tests have a
/// single named place to ask "does the user have categories to pick from?"
/// without reaching past the repository into the migration.
@injectable
class SeedDefaultCategories {
  const SeedDefaultCategories(this._repository);

  final CategoryRepository _repository;

  /// Every category of both directions, archived ones excluded — the same
  /// view the entry form's picker sees.
  Future<Either<Failure, List<Category>>> call() async {
    final expenses = await _repository.getCategories(
      type: CategoryType.expense,
    );
    if (expenses.isLeft()) {
      return expenses;
    }
    final incomes = await _repository.getCategories(type: CategoryType.income);
    return incomes.map(
      (incomeList) => [
        ...expenses.getOrElse((_) => const []),
        ...incomeList,
      ],
    );
  }
}
