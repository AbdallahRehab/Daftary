import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/education_category.dart';
import '../repositories/education_content_repository.dart';

/// Every content-library category for the active app language (FR-001).
@injectable
class GetEducationCategories {
  const GetEducationCategories(this._repository);

  final EducationContentRepository _repository;

  Future<Either<Failure, List<EducationCategory>>> call({
    required String languageCode,
  }) => _repository.getCategories(languageCode: languageCode);
}
