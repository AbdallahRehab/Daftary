import 'dart:math' as math;

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/usecases/remove_category.dart';
import 'package:daftary/features/finance/domain/usecases/watch_categories.dart';
import 'package:daftary/features/finance/presentation/cubit/category_management_cubit.dart';
import 'package:daftary/features/finance/presentation/pages/category_management_page.dart';
import 'package:daftary/features/finance/presentation/widgets/category_icon_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/watch_stubs.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

final _now = DateTime(2026);

Category _category(
  String id,
  String name, {
  required String icon,
  CategoryType type = CategoryType.expense,
  bool isArchived = false,
}) => Category(
  id: id,
  name: name,
  type: type,
  icon: icon,
  isArchived: isArchived,
  createdAt: _now,
  updatedAt: _now,
);

/// A custom category (not a seeded one), so its stored name is what renders
/// verbatim in either language — the localized seed names are covered by
/// `category_display_name`'s own resolution and would make an Arabic-locale
/// text lookup here assert the wrong thing.
final _rent = _category('c1', 'إيجار', icon: 'rent');
final _archivedFuel = _category('c2', 'بنزين', icon: 'fuel', isArchived: true);

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/finance/categories',
  routes: [
    GoRoute(
      path: '/finance/categories',
      builder: (context, state) => const CategoryManagementPage(),
    ),
    GoRoute(
      path: '/finance/categories/new',
      builder: (context, state) => const Scaffold(body: Text('form')),
    ),
    GoRoute(
      path: '/finance/categories/:id/edit',
      builder: (context, state) => const Scaffold(body: Text('form')),
    ),
  ],
);

Widget _wrap(ThemeData theme) => MaterialApp.router(
  routerConfig: _buildRouter(),
  theme: theme,
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);

void main() {
  late MockCategoryRepository repository;
  late FakeTableChanges changes;

  setUpAll(() => registerFallbackValue(CategoryType.expense));

  setUp(() {
    repository = MockCategoryRepository();
    changes = FakeTableChanges();
    stubCategoryWatches(repository, changes);
    when(
      () => repository.getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right([_rent, _archivedFuel]));

    getIt.registerFactory<CategoryManagementCubit>(
      () => CategoryManagementCubit(
        WatchCategories(repository),
        RemoveCategory(repository),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await changes.close();
  });

  testWidgets('renders right-to-left under the Arabic locale', (tester) async {
    await tester.pumpWidget(_wrap(buildLightTheme()));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CategoryManagementPage)),
    )!;
    expect(find.text(l10n.financeCategoryManagementTitle), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('إيجار'))),
      TextDirection.rtl,
    );
    // No overflow was thrown while laying the rows out mirrored (SC-005).
    expect(tester.takeException(), equals(null));
  });

  testWidgets('groups active and archived categories into labelled sections', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(buildLightTheme()));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CategoryManagementPage)),
    )!;
    expect(find.text(l10n.financeCategorySectionActive), findsOneWidget);
    expect(find.text(l10n.financeCategorySectionArchived), findsOneWidget);
    expect(find.text('إيجار'), findsOneWidget);
    expect(find.text('بنزين'), findsOneWidget);
    // An archived row says so, rather than looking identical to an active
    // one that happens to sit under a different header.
    expect(find.text(l10n.financeCategoryArchivedNotice), findsOneWidget);
  });

  for (final themeCase in [
    (name: 'light', theme: buildLightTheme()),
    (name: 'dark', theme: buildDarkTheme()),
  ]) {
    testWidgets(
      'category icons and labels stay legible in the ${themeCase.name} theme',
      (tester) async {
        await tester.pumpWidget(_wrap(themeCase.theme));
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(CategoryManagementPage));

        // Icon color comes from the theme at render time, never from a
        // persisted hex value (research.md Decision 10) — so it differs
        // between the two themes and always contrasts its own surface.
        final expectedIconColor = CategoryIconRegistry.colorFor(
          context,
          CategoryType.expense,
        );
        final rentIcon = tester.widget<Icon>(
          find.byIcon(CategoryIconRegistry.iconFor('rent')),
        );
        expect(rentIcon.color, expectedIconColor);

        final fuelIcon = tester.widget<Icon>(
          find.byIcon(CategoryIconRegistry.iconFor('fuel')),
        );
        expect(fuelIcon.color, expectedIconColor);

        final surface = CategoryIconRegistry.surfaceColorFor(
          context,
          CategoryType.expense,
        );
        expect(
          _contrastRatio(expectedIconColor, surface),
          greaterThan(3),
          reason: 'icon must stay readable on its tinted badge',
        );

        final label = tester.widget<Text>(find.text('إيجار'));
        final labelColor =
            label.style?.color ??
            DefaultTextStyle.of(
              tester.element(find.text('إيجار')),
            ).style.color!;
        expect(
          _contrastRatio(labelColor, Theme.of(context).colorScheme.surface),
          greaterThan(4.5),
          reason: 'category name must meet body-text contrast',
        );

        expect(tester.takeException(), equals(null));
      },
    );
  }
}

double _relativeLuminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
