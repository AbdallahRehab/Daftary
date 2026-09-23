import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/category.dart';
import '../entities/finance_entry_type.dart';
import '../repositories/category_repository.dart';

/// The categories of one direction. Archived ones are excluded by default —
/// the entry-creation picker must not offer them (FR-011) — and included
/// only where the management screen asks for them.
@injectable
class GetCategories {
  const GetCategories(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, List<Category>>> call({
    required CategoryType type,
    bool includeArchived = false,
  }) {
    return _repository.getCategories(
      type: type,
      includeArchived: includeArchived,
    );
  }
}
