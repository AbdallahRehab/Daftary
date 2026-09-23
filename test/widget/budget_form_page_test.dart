import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/features/budgets/domain/entities/budget_summary.dart';
import 'package:daftary/features/budgets/domain/usecases/add_budget_category_allocation.dart';
import 'package:daftary/features/budgets/domain/usecases/create_budget.dart';
import 'package:daftary/features/budgets/domain/usecases/delete_budget.dart';
import 'package:daftary/features/budgets/domain/usecases/edit_budget.dart';
import 'package:daftary/features/budgets/domain/usecases/edit_budget_category_allocation.dart';
import 'package:daftary/features/budgets/domain/usecases/get_budget_for_month.dart';
import 'package:daftary/features/budgets/domain/usecases/remove_budget_category_allocation.dart';
import 'package:daftary/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:daftary/features/budgets/presentation/pages/budget_form_page.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetForMonth extends Mock implements GetBudgetForMonth {}

class MockCreateBudget extends Mock implements CreateBudget {}

class MockEditBudget extends Mock implements EditBudget {}

class MockDeleteBudget extends Mock implements DeleteBudget {}

class MockAddAllocation extends Mock implements AddBudgetCategoryAllocation {}

class MockEditAllocation extends Mock implements EditBudgetCategoryAllocation {}

class MockRemoveAllocation extends Mock
    implements RemoveBudgetCategoryAllocation {}

class MockGetCategories extends Mock implements GetCategories {}

/// The budget form (T025): the picker offers expense categories and adds
/// them as rows; a negative amount is refused with an explanation (FR-002);
/// the live total drives the non-blocking "exceeds income" hint (FR-004).
void main() {
  const month = '2026-09';
  final now = DateTime(2026, 9, 1);
  final rent = Category(
    id: 'seed_rent',
    name: 'Rent',
    type: CategoryType.expense,
    icon: 'rent',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  );
  final archived = Category(
    id: 'custom_old',
    name: 'Old stuff',
    type: CategoryType.expense,
    icon: 'shopping',
    isArchived: true,
    createdAt: now,
    updatedAt: now,
  );

  late BudgetFormCubit cubit;

  setUpAll(() => registerFallbackValue(CategoryType.expense));

  setUp(() {
    final getCategories = MockGetCategories();
    final getBudgetForMonth = MockGetBudgetForMonth();
    when(
      () => getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right([rent, archived]));
    when(
      () => getBudgetForMonth(any()),
    ).thenAnswer((_) async => const Right(BudgetMonthDetail.empty(month)));
    cubit = BudgetFormCubit(
      getBudgetForMonth,
      MockCreateBudget(),
      MockEditBudget(),
      MockDeleteBudget(),
      MockAddAllocation(),
      MockEditAllocation(),
      MockRemoveAllocation(),
      getCategories,
      EgpFormatter(),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..initialize(month),
          child: const BudgetFormView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the picker hides archived categories and adds a tapped one '
      'as a row (FR-021)', (tester) async {
    await pump(tester);

    expect(find.text('New budget'), findsOneWidget);
    expect(find.text('Old stuff'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rent'));
    await tester.pumpAndSettle();

    expect(find.text('Planned amount'), findsOneWidget);
    // Once on the budget, it is no longer offered.
    expect(find.widgetWithText(ChoiceChip, 'Rent'), findsNothing);
  });

  testWidgets('a negative amount is refused with an explanation (FR-002)', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rent'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Planned amount'),
      '-10',
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text("The amount can't be negative"), findsOneWidget);
  });

  testWidgets('the live total shows the exceeds-income hint (FR-004)', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Expected income (optional)'),
      '5000',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rent'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Planned amount'),
      '7000',
    );
    await tester.pumpAndSettle();

    expect(find.text('7,000.00 EGP'), findsOneWidget);
    expect(
      find.text('Planned spending exceeds expected income by 2,000.00 EGP'),
      findsOneWidget,
    );
    expect(find.text('You can still save this budget.'), findsOneWidget);
  });

  testWidgets('renders in Arabic without layout errors', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    expect(find.text('ميزانية جديدة'), findsOneWidget);
  });
}
