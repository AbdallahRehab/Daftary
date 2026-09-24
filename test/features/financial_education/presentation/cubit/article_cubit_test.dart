import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/features/financial_education/domain/entities/education_article.dart';
import 'package:daftary/features/financial_education/domain/entities/education_failures.dart';
import 'package:daftary/features/financial_education/domain/repositories/education_content_repository.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_article.dart';
import 'package:daftary/features/financial_education/presentation/cubit/article_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/article_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEducationContentRepository extends Mock
    implements EducationContentRepository {}

void main() {
  late MockEducationContentRepository repository;

  const article = EducationArticle(
    id: 'why_track_your_spending',
    categoryId: 'budgeting_basics',
    title: 'Why Track Your Spending',
    shortDescription: 'Short',
    bodySections: [
      ArticleSection(paragraphs: ['Intro']),
      ArticleSection(heading: 'Heading', paragraphs: ['One', 'Two']),
    ],
  );

  setUp(() => repository = MockEducationContentRepository());

  ArticleCubit build() => ArticleCubit(GetArticle(repository));

  test('starts in the loading state', () {
    expect(build().state, const ArticleState());
  });

  blocTest<ArticleCubit, ArticleState>(
    'emits loading then success with the full article body',
    setUp: () => when(
      () =>
          repository.getArticle('why_track_your_spending', languageCode: 'ar'),
    ).thenAnswer((_) async => const Right(article)),
    build: build,
    act: (cubit) => cubit.load('why_track_your_spending', 'ar'),
    expect: () => const [
      ArticleState(),
      ArticleState(status: ArticleStatus.success, article: article),
    ],
    verify: (cubit) {
      expect(cubit.state.article!.bodySections, hasLength(2));
      expect(cubit.state.article!.bodySections.last.heading, 'Heading');
    },
  );

  blocTest<ArticleCubit, ArticleState>(
    'emits loading then failure for an unknown article id',
    setUp: () => when(
      () => repository.getArticle('nope', languageCode: 'en'),
    ).thenAnswer((_) async => const Left(ContentNotFoundFailure('nope'))),
    build: build,
    act: (cubit) => cubit.load('nope', 'en'),
    expect: () => const [
      ArticleState(),
      ArticleState(status: ArticleStatus.failure, errorMessage: 'nope'),
    ],
  );

  blocTest<ArticleCubit, ArticleState>(
    'emits failure when the article asset is malformed',
    setUp: () => when(
      () => repository.getArticle('broken', languageCode: 'en'),
    ).thenAnswer((_) async => const Left(ContentAssetLoadFailure('bad json'))),
    build: build,
    act: (cubit) => cubit.load('broken', 'en'),
    expect: () => const [
      ArticleState(),
      ArticleState(status: ArticleStatus.failure, errorMessage: 'bad json'),
    ],
  );
}
