import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/education_article.dart';
import '../entities/education_category.dart';
import '../repositories/education_content_repository.dart';

/// A category together with its articles, in authored order — what the
/// category screen lists (title + short description per article, FR-003).
/// The first failure encountered short-circuits the whole result, so the
/// screen never renders a silently partial list.
@injectable
class GetCategoryArticles {
  const GetCategoryArticles(this._repository);

  final EducationContentRepository _repository;

  Future<Either<Failure, (EducationCategory, List<EducationArticle>)>> call(
    String categoryId, {
    required String languageCode,
  }) async {
    final categoryResult = await _repository.getCategory(
      categoryId,
      languageCode: languageCode,
    );
    final EducationCategory category;
    switch (categoryResult) {
      case Left(:final value):
        return Left(value);
      case Right(:final value):
        category = value;
    }
    final articles = <EducationArticle>[];
    for (final articleId in category.articleIds) {
      final articleResult = await _repository.getArticle(
        articleId,
        languageCode: languageCode,
      );
      switch (articleResult) {
        case Left(:final value):
          return Left(value);
        case Right(:final value):
          articles.add(value);
      }
    }
    return Right((category, List.unmodifiable(articles)));
  }
}
