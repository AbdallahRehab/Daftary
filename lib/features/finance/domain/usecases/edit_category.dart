import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Renames and/or re-icons a category (FR-009). `type` is absent by design
/// — it is immutable after creation, since changing it would silently
/// reclassify every entry already filed under the category.
@injectable
class EditCategory {
  const EditCategory(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Category>> call({
    required String categoryId,
    required String name,
    required String icon,
  }) {
    return _repository.editCategory(
      categoryId: categoryId,
      name: name,
      icon: icon,
    );
  }
}
