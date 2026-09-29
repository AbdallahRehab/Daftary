import 'package:daftary/features/savings/domain/usecases/get_savings_overview.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/features/financial_education/domain/entities/education_article.dart';
import 'package:daftary/features/financial_education/domain/entities/education_category.dart';
import 'package:daftary/features/financial_education/domain/repositories/education_content_repository.dart';
import 'package:daftary/features/financial_education/domain/services/compound_growth_calculator.dart';
import 'package:daftary/features/financial_education/domain/services/doubling_time_calculator.dart';
import 'package:daftary/features/financial_education/domain/services/savings_rate_calculator.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_compound_growth.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_doubling_time.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_savings_rate.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_article.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_category_articles.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_education_categories.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_prefillable_savings_goal_amount.dart';
import 'package:daftary/features/financial_education/presentation/cubit/article_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/category_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/compound_growth_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/content_library_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/doubling_time_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/savings_rate_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/pages/article_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/category_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/compound_growth_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/content_library_home_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/doubling_time_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/savings_rate_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/widgets/persistent_disclaimer_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// T048 — the one consolidated SC-003 suite: `PersistentDisclaimerBanner`
/// renders on ALL 6 Financial Education screens (library home, category,
/// article, and the three calculators), on two separate visits per screen,
/// in both locales, with no code path able to hide it after a first render.
class MockEducationContentRepository extends Mock
    implements EducationContentRepository {}

const _category = EducationCategory(
  id: 'budgeting_basics',
  title: 'Budgeting Basics',
  shortDescription: 'Learn the basics',
  articleIds: ['why_track_your_spending'],
);

const _article = EducationArticle(
  id: 'why_track_your_spending',
  categoryId: 'budgeting_basics',
  title: 'Why Track Your Spending',
  shortDescription: 'A short description',
  bodySections: [
    ArticleSection(heading: 'Section', paragraphs: ['Paragraph one.']),
  ],
);

/// Every screen this feature introduces, by the route that opens it.
final Map<String, Type> _screens = {
  FinancialEducationRoutes.home: ContentLibraryHomePage,
  FinancialEducationRoutes.category('budgeting_basics'): CategoryPage,
  FinancialEducationRoutes.article(
    'budgeting_basics',
    'why_track_your_spending',
  ): ArticlePage,
  FinancialEducationRoutes.compoundGrowth: CompoundGrowthCalculatorPage,
  FinancialEducationRoutes.doublingTime: DoublingTimeCalculatorPage,
  FinancialEducationRoutes.savingsRate: SavingsRateCalculatorPage,
};

/// Mirrors the app router's Financial Education routes (fixed calculator
/// paths declared before the `:categoryId` routes).
GoRouter _buildRouter() => GoRouter(
  initialLocation: '/start',
  routes: [
    GoRoute(
      path: '/start',
      builder: (context, state) => const Scaffold(body: Text('start')),
    ),
    GoRoute(
      path: FinancialEducationRoutes.home,
      builder: (context, state) => const ContentLibraryHomePage(),
    ),
    GoRoute(
      path: FinancialEducationRoutes.compoundGrowth,
      builder: (context, state) => const CompoundGrowthCalculatorPage(),
    ),
    GoRoute(
      path: FinancialEducationRoutes.doublingTime,
      builder: (context, state) => const DoublingTimeCalculatorPage(),
    ),
    GoRoute(
      path: FinancialEducationRoutes.savingsRate,
      builder: (context, state) => const SavingsRateCalculatorPage(),
    ),
    GoRoute(
      path: '/financial-education/:categoryId',
      builder: (context, state) =>
          CategoryPage(categoryId: state.pathParameters['categoryId']!),
    ),
    GoRoute(
      path: '/financial-education/:categoryId/:articleId',
      builder: (context, state) => ArticlePage(
        categoryId: state.pathParameters['categoryId']!,
        articleId: state.pathParameters['articleId']!,
      ),
    ),
  ],
);

/// 016 reads 011 only through `GetSavingsOverview`; these pages are tested
/// with no savings goal on record, so the pre-fill stays hidden.
class _NoSavingsGoals implements GetSavingsOverview {
  const _NoSavingsGoals();

  @override
  Future<Either<Failure, SavingsOverview>> call({
    bool includeArchived = false,
  }) async =>
      const Right(SavingsOverview(goals: [], primaryCurrency: Currency.egp));
}

void main() {
  late MockEducationContentRepository repository;

  setUp(() async {
    await getIt.reset();
    repository = MockEducationContentRepository();
    when(
      () => repository.getCategories(languageCode: any(named: 'languageCode')),
    ).thenAnswer((_) async => const Right([_category]));
    when(
      () => repository.getCategory(
        any(),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => const Right(_category));
    when(
      () => repository.getArticle(
        any(),
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => const Right(_article));

    getIt
      ..registerFactory<ContentLibraryCubit>(
        () => ContentLibraryCubit(GetEducationCategories(repository)),
      )
      ..registerFactory<CategoryCubit>(
        () => CategoryCubit(GetCategoryArticles(repository)),
      )
      ..registerFactory<ArticleCubit>(
        () => ArticleCubit(GetArticle(repository)),
      )
      // The real, pure calculators behind the real use cases.
      ..registerFactory<CompoundGrowthCalculatorCubit>(
        () => CompoundGrowthCalculatorCubit(
          const CalculateCompoundGrowth(CompoundGrowthCalculatorImpl()),
          const GetPrefillableSavingsGoalAmount(_NoSavingsGoals()),
          EgpFormatter(),
        ),
      )
      ..registerFactory<DoublingTimeCalculatorCubit>(
        () => DoublingTimeCalculatorCubit(
          const CalculateDoublingTime(DoublingTimeCalculatorImpl()),
          EgpFormatter(),
        ),
      )
      ..registerFactory<SavingsRateCalculatorCubit>(
        () => SavingsRateCalculatorCubit(
          const CalculateSavingsRate(SavingsRateCalculatorImpl()),
          EgpFormatter(),
        ),
      );
  });

  tearDown(() async => getIt.reset());

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final router = _buildRouter();
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildLightTheme(),
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  test('PersistentDisclaimerBanner is stateless and takes no parameters '
      'that could hide it', () {
    const banner = PersistentDisclaimerBanner();
    expect(banner, isA<StatelessWidget>());
    expect(banner, isNot(isA<StatefulWidget>()));
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final MapEntry(key: route, value: pageType) in _screens.entries) {
      testWidgets(
        'PersistentDisclaimerBanner renders on $pageType on two separate '
        'visits (${locale.languageCode})',
        (tester) async {
          final router = await pumpApp(tester, locale: locale);

          // SC-003: two separate navigations to the same screen, each a
          // fresh page instance and pump cycle, must both show the
          // disclaimer.
          for (var visit = 1; visit <= 2; visit++) {
            router.push(route);
            await tester.pumpAndSettle();

            expect(find.byType(pageType), findsOneWidget);
            expect(
              find.byKey(PersistentDisclaimerBanner.rootKey),
              findsOneWidget,
              reason: 'visit $visit to $route',
            );
            final l10n = AppLocalizations.of(
              tester.element(find.byType(pageType)),
            )!;
            expect(find.text(l10n.finEduDisclaimer), findsOneWidget);

            router.pop();
            await tester.pumpAndSettle();
            expect(find.byType(pageType), findsNothing);
            expect(
              find.byKey(PersistentDisclaimerBanner.rootKey),
              findsNothing,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('the disclaimer stays visible after interacting with and '
      'scrolling a calculator page', (tester) async {
    final router = await pumpApp(tester);
    router.push(FinancialEducationRoutes.compoundGrowth);
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1000');
    await tester.enterText(fields.at(1), '7');
    await tester.enterText(fields.at(2), '10');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final banner = find.byKey(PersistentDisclaimerBanner.rootKey);
    expect(banner, findsOneWidget);
    // Pinned above the scrollable body, so it is still on-screen.
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getRect(banner).top, greaterThanOrEqualTo(0));
    expect(tester.getRect(banner).bottom, lessThanOrEqualTo(screen.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the disclaimer is shown even while content is still loading', (
    tester,
  ) async {
    when(
      () => repository.getCategories(languageCode: any(named: 'languageCode')),
    ).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 1), () {
        return const Right([_category]);
      }),
    );
    final router = _buildRouter()..go(FinancialEducationRoutes.home);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(PersistentDisclaimerBanner.rootKey), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
