import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/category_repository.dart';

/// Removes a category (FR-010): hard-deleted when nothing references it,
/// archived when something does. The branch is decided by the data, not by
/// the caller — which is why there is no "archive" flag here.
@injectable
class RemoveCategory {
  const RemoveCategory(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call(String categoryId) =>
      _repository.removeCategory(categoryId);
}
