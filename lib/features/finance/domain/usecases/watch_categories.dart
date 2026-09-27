import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/category.dart';
import '../entities/finance_entry_type.dart';
import '../repositories/category_repository.dart';

/// 021: the live categories of one direction (FR-011, FR-031), with the
/// same archived-category rule as `GetCategories`.
@injectable
class WatchCategories {
  const WatchCategories(this._repository);

  final CategoryRepository _repository;

  Stream<Either<Failure, List<Category>>> call({
    required CategoryType type,
    bool includeArchived = false,
  }) =>
      _repository.watchCategories(type: type, includeArchived: includeArchived);
}
