import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/features/financial_education/domain/entities/education_article.dart';
import 'package:daftary/features/financial_education/domain/entities/education_category.dart';
import 'package:daftary/features/financial_education/domain/entities/education_failures.dart';
import 'package:daftary/features/financial_education/domain/repositories/education_content_repository.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_category_articles.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_education_categories.dart';
import 'package:daftary/features/financial_education/presentation/cubit/category_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/category_state.dart';
import 'package:daftary/features/financial_education/presentation/cubit/content_library_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/content_library_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEducationContentRepository extends Mock
    implements EducationContentRepository {}

void main() {
  late MockEducationContentRepository repository;

  const budgeting = EducationCategory(
    id: 'budgeting_basics',
    title: 'Budgeting Basics',
    shortDescription: 'Short',
    articleIds: ['a1'],
  );
  const saving = EducationCategory(
    id: 'saving_strategies',
    title: 'Saving Strategies',
    shortDescription: 'Short',
    articleIds: [],
  );
  const article = EducationArticle(
    id: 'a1',
    categoryId: 'budgeting_basics',
    title: 'A1',
    shortDescription: 'Short A1',
    bodySections: [
      ArticleSection(paragraphs: ['Body']),
    ],
  );

  setUp(() => repository = MockEducationContentRepository());

  group('ContentLibraryCubit', () {
    ContentLibraryCubit build() =>
        ContentLibraryCubit(GetEducationCategories(repository));

    test('starts in the loading state', () {
      expect(build().state, const ContentLibraryState());
    });

    blocTest<ContentLibraryCubit, ContentLibraryState>(
      'emits loading then success with the categories in order',
      setUp: () => when(
        () => repository.getCategories(languageCode: 'en'),
      ).thenAnswer((_) async => const Right([budgeting, saving])),
      build: build,
      act: (cubit) => cubit.load('en'),
      expect: () => const [
        ContentLibraryState(),
        ContentLibraryState(
          status: ContentLibraryStatus.success,
          categories: [budgeting, saving],
        ),
      ],
    );

    blocTest<ContentLibraryCubit, ContentLibraryState>(
      'requests the active language',
      setUp: () => when(
        () => repository.getCategories(languageCode: 'ar'),
      ).thenAnswer((_) async => const Right([budgeting])),
      build: build,
      act: (cubit) => cubit.load('ar'),
      verify: (_) =>
          verify(() => repository.getCategories(languageCode: 'ar')).called(1),
    );

    blocTest<ContentLibraryCubit, ContentLibraryState>(
      'emits loading then failure when content cannot be loaded',
      setUp: () => when(
        () => repository.getCategories(languageCode: 'en'),
      ).thenAnswer((_) async => const Left(ContentAssetLoadFailure('bad'))),
      build: build,
      act: (cubit) => cubit.load('en'),
      expect: () => const [
        ContentLibraryState(),
        ContentLibraryState(
          status: ContentLibraryStatus.failure,
          errorMessage: 'bad',
        ),
      ],
    );

    blocTest<ContentLibraryCubit, ContentLibraryState>(
      'a retry after a failure clears the error and can succeed',
      setUp: () => when(
        () => repository.getCategories(languageCode: 'en'),
      ).thenAnswer((_) async => const Right([budgeting])),
      build: build,
      seed: () => const ContentLibraryState(
        status: ContentLibraryStatus.failure,
        errorMessage: 'bad',
      ),
      act: (cubit) => cubit.load('en'),
      expect: () => const [
        ContentLibraryState(),
        ContentLibraryState(
          status: ContentLibraryStatus.success,
          categories: [budgeting],
        ),
      ],
    );
  });

  group('CategoryCubit', () {
    CategoryCubit build() => CategoryCubit(GetCategoryArticles(repository));

    blocTest<CategoryCubit, CategoryState>(
      'emits loading then success with the category and its articles',
      setUp: () {
        when(
          () => repository.getCategory('budgeting_basics', languageCode: 'en'),
        ).thenAnswer((_) async => const Right(budgeting));
        when(
          () => repository.getArticle('a1', languageCode: 'en'),
        ).thenAnswer((_) async => const Right(article));
      },
      build: build,
      act: (cubit) => cubit.load('budgeting_basics', 'en'),
      expect: () => const [
        CategoryState(),
        CategoryState(
          status: CategoryStatus.success,
          category: budgeting,
          articles: [article],
        ),
      ],
    );

    blocTest<CategoryCubit, CategoryState>(
      'emits failure for an unknown category',
      setUp: () => when(
        () => repository.getCategory('nope', languageCode: 'en'),
      ).thenAnswer((_) async => const Left(ContentNotFoundFailure('nope'))),
      build: build,
      act: (cubit) => cubit.load('nope', 'en'),
      expect: () => const [
        CategoryState(),
        CategoryState(status: CategoryStatus.failure, errorMessage: 'nope'),
      ],
    );
  });
}
