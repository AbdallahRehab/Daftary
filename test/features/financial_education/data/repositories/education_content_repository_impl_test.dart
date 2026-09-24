import 'package:daftary/features/financial_education/data/datasources/bundled_education_content_data_source.dart';
import 'package:daftary/features/financial_education/data/repositories/education_content_repository_impl.dart';
import 'package:daftary/features/financial_education/domain/entities/education_article.dart';
import 'package:daftary/features/financial_education/domain/entities/education_category.dart';
import 'package:daftary/features/financial_education/domain/entities/education_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fixtures/fixture_asset_bundle.dart';

void main() {
  late FixtureAssetBundle bundle;
  late EducationContentRepositoryImpl repository;

  setUp(() {
    bundle = FixtureAssetBundle();
    repository = EducationContentRepositoryImpl(
      BundledEducationContentDataSource(bundle),
    );
  });

  group('getCategories', () {
    test('returns the categories in authored order for English', () async {
      final result = await repository.getCategories(languageCode: 'en');

      expect(result.getOrElse((_) => fail('expected Right')), const [
        EducationCategory(
          id: 'budgeting_basics',
          title: 'Budgeting Basics',
          shortDescription: 'Fixture category one.',
          articleIds: ['why_track_your_spending', 'broken_article'],
        ),
        EducationCategory(
          id: 'saving_strategies',
          title: 'Saving Strategies',
          shortDescription: 'Fixture category two.',
          articleIds: [],
        ),
      ]);
    });

    test('loads the Arabic tree for the ar language code', () async {
      final result = await repository.getCategories(languageCode: 'ar');

      final categories = result.getOrElse((_) => fail('expected Right'));
      expect(categories.first.title, 'أساسيات الميزانية');
      expect(categories.first.id, 'budgeting_basics');
    });

    test('falls back to English for an unsupported language', () async {
      final result = await repository.getCategories(languageCode: 'fr');

      final categories = result.getOrElse((_) => fail('expected Right'));
      expect(categories.first.title, 'Budgeting Basics');
      expect(
        bundle.requestedKeys.single,
        '${BundledEducationContentDataSource.contentRoot}/en/categories.json',
      );
    });

    test('reads categories.json only once per language (cached)', () async {
      await repository.getCategories(languageCode: 'en');
      await repository.getCategories(languageCode: 'en');

      expect(bundle.requestedKeys, hasLength(1));
    });
  });

  group('getCategory', () {
    test('returns the matching category', () async {
      final result = await repository.getCategory(
        'saving_strategies',
        languageCode: 'en',
      );

      expect(
        result.getOrElse((_) => fail('expected Right')).title,
        'Saving Strategies',
      );
    });

    test('returns ContentNotFoundFailure for an unknown id', () async {
      final result = await repository.getCategory(
        'no_such_category',
        languageCode: 'en',
      );

      expect(result.getLeft().toNullable(), isA<ContentNotFoundFailure>());
    });
  });

  group('getArticle', () {
    test('maps the article JSON including optional headings', () async {
      final result = await repository.getArticle(
        'why_track_your_spending',
        languageCode: 'en',
      );

      expect(
        result,
        const Right<Never, EducationArticle>(
          EducationArticle(
            id: 'why_track_your_spending',
            categoryId: 'budgeting_basics',
            title: 'Why Track Your Spending',
            shortDescription: 'Fixture article.',
            bodySections: [
              ArticleSection(paragraphs: ['Intro paragraph.']),
              ArticleSection(
                heading: 'A heading',
                paragraphs: ['First.', 'Second.'],
              ),
            ],
          ),
        ),
      );
    });

    test('resolves the same id in the Arabic tree', () async {
      final result = await repository.getArticle(
        'why_track_your_spending',
        languageCode: 'ar',
      );

      expect(
        result.getOrElse((_) => fail('expected Right')).title,
        'لماذا تتابع إنفاقك',
      );
    });

    test('returns ContentNotFoundFailure for an unknown id', () async {
      final result = await repository.getArticle(
        'no_such_article',
        languageCode: 'en',
      );

      expect(result.getLeft().toNullable(), isA<ContentNotFoundFailure>());
    });

    test('never builds an asset path from a malformed id', () async {
      final result = await repository.getArticle(
        '../categories',
        languageCode: 'en',
      );

      expect(result.getLeft().toNullable(), isA<ContentNotFoundFailure>());
      expect(bundle.requestedKeys.where((key) => key.contains('..')), isEmpty);
    });

    test(
      'returns ContentAssetLoadFailure for a malformed article file',
      () async {
        final result = await repository.getArticle(
          'broken_article',
          languageCode: 'en',
        );

        expect(result.getLeft().toNullable(), isA<ContentAssetLoadFailure>());
      },
    );

    test(
      'returns ContentAssetLoadFailure when a listed article file is missing',
      () async {
        // The ar fixture lists `missing_article` but ships no file for it.
        final result = await repository.getArticle(
          'missing_article',
          languageCode: 'ar',
        );

        expect(result.getLeft().toNullable(), isA<ContentAssetLoadFailure>());
      },
    );
  });
}
