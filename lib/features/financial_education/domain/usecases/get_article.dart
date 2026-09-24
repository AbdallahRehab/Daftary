import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/education_article.dart';
import '../repositories/education_content_repository.dart';

/// One full article, body included (FR-003).
@injectable
class GetArticle {
  const GetArticle(this._repository);

  final EducationContentRepository _repository;

  Future<Either<Failure, EducationArticle>> call(
    String articleId, {
    required String languageCode,
  }) => _repository.getArticle(articleId, languageCode: languageCode);
}
