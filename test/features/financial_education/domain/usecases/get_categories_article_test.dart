import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/financial_education/domain/entities/education_article.dart';
import 'package:daftary/features/financial_education/domain/entities/education_category.dart';
import 'package:daftary/features/financial_education/domain/entities/education_failures.dart';
import 'package:daftary/features/financial_education/domain/repositories/education_content_repository.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_article.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_category_articles.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_education_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEducationContentRepository extends Mock
    implements EducationContentRepository {}

void main() {
  late MockEducationContentRepository repository;

  const category = EducationCategory(
    id: 'budgeting_basics',
    title: 'Budgeting Basics',
    shortDescription: 'Short',
    articleIds: ['a1', 'a2'],
  );
  EducationArticle article(String id) => EducationArticle(
    id: id,
    categoryId: 'budgeting_basics',
    title: 'Title $id',
    shortDescription: 'Short $id',
    bodySections: const [
      ArticleSection(paragraphs: ['Body']),
    ],
  );

  setUp(() => repository = MockEducationContentRepository());

  group('GetEducationCategories', () {
    test('passes the language through and returns the categories', () async {
      when(
        () => repository.getCategories(languageCode: 'ar'),
      ).thenAnswer((_) async => const Right([category]));

      final result = await GetEducationCategories(repository)(
        languageCode: 'ar',
      );

      expect(result.getOrElse((_) => fail('expected Right')), [category]);
      verify(() => repository.getCategories(languageCode: 'ar')).called(1);
    });

    test('surfaces a repository failure unchanged', () async {
      when(
        () => repository.getCategories(languageCode: 'en'),
      ).thenAnswer((_) async => const Left(ContentAssetLoadFailure('bad')));

      final result = await GetEducationCategories(repository)(
        languageCode: 'en',
      );

      expect(
        result,
        const Left<Failure, Never>(ContentAssetLoadFailure('bad')),
      );
    });
  });

  group('GetArticle', () {
    test('passes the id and language through', () async {
      when(
        () => repository.getArticle('a1', languageCode: 'en'),
      ).thenAnswer((_) async => Right(article('a1')));

      final result = await GetArticle(repository)('a1', languageCode: 'en');

      expect(result, Right<Failure, EducationArticle>(article('a1')));
    });

    test('surfaces ContentNotFoundFailure for an unknown id', () async {
      when(
        () => repository.getArticle('nope', languageCode: 'en'),
      ).thenAnswer((_) async => const Left(ContentNotFoundFailure('nope')));

      final result = await GetArticle(repository)('nope', languageCode: 'en');

      expect(result.getLeft().toNullable(), isA<ContentNotFoundFailure>());
    });
  });

  group('GetCategoryArticles', () {
    test('returns the category with its articles in authored order', () async {
      when(
        () => repository.getCategory('budgeting_basics', languageCode: 'en'),
      ).thenAnswer((_) async => const Right(category));
      when(
        () => repository.getArticle('a1', languageCode: 'en'),
      ).thenAnswer((_) async => Right(article('a1')));
      when(
        () => repository.getArticle('a2', languageCode: 'en'),
      ).thenAnswer((_) async => Right(article('a2')));

      final result = await GetCategoryArticles(repository)(
        'budgeting_basics',
        languageCode: 'en',
      );

      final (loadedCategory, articles) = result.getOrElse(
        (_) => fail('expected Right'),
      );
      expect(loadedCategory, category);
      expect(articles, [article('a1'), article('a2')]);
    });

    test('fails as a whole when any article fails to load', () async {
      when(
        () => repository.getCategory('budgeting_basics', languageCode: 'en'),
      ).thenAnswer((_) async => const Right(category));
      when(
        () => repository.getArticle('a1', languageCode: 'en'),
      ).thenAnswer((_) async => const Left(ContentAssetLoadFailure('bad')));

      final result = await GetCategoryArticles(repository)(
        'budgeting_basics',
        languageCode: 'en',
      );

      expect(result.getLeft().toNullable(), isA<ContentAssetLoadFailure>());
      verifyNever(() => repository.getArticle('a2', languageCode: 'en'));
    });

    test('surfaces ContentNotFoundFailure for an unknown category', () async {
      when(
        () => repository.getCategory('nope', languageCode: 'en'),
      ).thenAnswer((_) async => const Left(ContentNotFoundFailure('nope')));

      final result = await GetCategoryArticles(repository)(
        'nope',
        languageCode: 'en',
      );

      expect(result.getLeft().toNullable(), isA<ContentNotFoundFailure>());
    });
  });
}
