import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/education_article.dart';
import '../entities/education_category.dart';

/// Read-only access to the bundled educational content
/// (contracts/education_content_repository.md).
///
/// Every method takes the active app [languageCode] (`en`/`ar`) explicitly
/// rather than reaching into app-level settings state from the Data layer;
/// an unsupported code falls back to English. Content ids are identical
/// across languages, so the same id resolves in either tree.
abstract class EducationContentRepository {
  /// All categories, in their authored display order (FR-001/FR-003).
  Future<Either<Failure, List<EducationCategory>>> getCategories({
    required String languageCode,
  });

  /// One category by id; `ContentNotFoundFailure` for an unknown id.
  Future<Either<Failure, EducationCategory>> getCategory(
    String categoryId, {
    required String languageCode,
  });

  /// One full article by id, including its body (FR-003);
  /// `ContentNotFoundFailure` for an unknown id.
  Future<Either<Failure, EducationArticle>> getArticle(
    String articleId, {
    required String languageCode,
  });
}
