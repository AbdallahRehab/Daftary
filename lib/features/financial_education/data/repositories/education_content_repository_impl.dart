import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/education_article.dart';
import '../../domain/entities/education_category.dart';
import '../../domain/entities/education_failures.dart';
import '../../domain/repositories/education_content_repository.dart';
import '../datasources/bundled_education_content_data_source.dart';

/// Maps the bundled data source's exceptions onto typed failures — nothing
/// is ever thrown past this boundary (constitution Principle VII).
@LazySingleton(as: EducationContentRepository)
class EducationContentRepositoryImpl implements EducationContentRepository {
  EducationContentRepositoryImpl(this._dataSource);

  final BundledEducationContentDataSource _dataSource;

  @override
  Future<Either<Failure, List<EducationCategory>>> getCategories({
    required String languageCode,
  }) => _guard(() => _dataSource.loadCategories(languageCode));

  @override
  Future<Either<Failure, EducationCategory>> getCategory(
    String categoryId, {
    required String languageCode,
  }) => _guard(() => _dataSource.loadCategory(categoryId, languageCode));

  @override
  Future<Either<Failure, EducationArticle>> getArticle(
    String articleId, {
    required String languageCode,
  }) => _guard(() => _dataSource.loadArticle(articleId, languageCode));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() load) async {
    try {
      return Right(await load());
    } on EducationContentNotFoundException catch (error) {
      return Left(ContentNotFoundFailure(error.message));
    } on EducationContentFormatException catch (error) {
      return Left(ContentAssetLoadFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
