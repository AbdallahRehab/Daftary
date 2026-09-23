import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/category.dart';
import '../entities/finance_entry_type.dart';
import '../repositories/category_repository.dart';

/// Creates a custom category (FR-007), surfacing a `DuplicateCategoryFailure`
/// rather than inserting a second category with the same active name
/// (FR-008).
@injectable
class CreateCategory {
  const CreateCategory(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Category>> call({
    required String name,
    required CategoryType type,
    required String icon,
  }) {
    return _repository.createCategory(name: name, type: type, icon: icon);
  }
}
