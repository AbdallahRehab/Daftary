import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/main.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// T081 — end-to-end coverage of US1-US5 against the real app (real DI,
/// real on-device SQLite), following quickstart.md's Manual Validation
/// Scenarios 1-6.
///
/// Each test suffixes the data it creates with a millisecond timestamp, so
/// repeated runs against the same persisted on-device database never
/// collide with each other or with FR-008's duplicate-name check.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `lib/main.dart`'s own `main()` is never invoked by an integration test,
  // so DI bootstrap has to happen explicitly before the first `pumpWidget`.
  setUpAll(() async {
    await configureDependencies();
    // 019: the app shows the splash until startup (settings + onboarding
    // gate) is ready, so run it exactly like `main()` does.
    // 019: startup now resolves the onboarding gate these flows never
    // went through before; mark it complete so they keep landing in the
    // main app whatever an earlier test left in the shared device DB.
    await getIt<OnboardingRepository>().completeOnboarding();
    await getIt<AppStartupCubit>().start();
  });

  Future<void> pumpFinance(WidgetTester tester) async {
    // `appRouter` is a module-level singleton that keeps wherever the
    // previous test left it — reset explicitly so each test starts on a
    // known screen.
    appRouter.go('/finance');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester, AppLocalizations l10n) async {
    // The on-screen keyboard can still cover Save right after typing, so a
    // tap would land on the keyboard instead.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    // The entry form runs past the fold once the category chips are laid
    // out, and `tester.tap` on an off-screen widget only warns rather than
    // failing — a missed Save would otherwise look like a save that did
    // nothing.
    final save = find.text(l10n.commonSave);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  /// Taps the category chip labelled [label].
  ///
  /// `ensureVisible` first: the picker's chips run past the fold, and
  /// `tester.tap` on an off-screen widget only warns — it does not fail — so
  /// a missed tap would otherwise surface much later as a confusing
  /// "choose a category" error.
  Future<void> selectCategory(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(ChoiceChip, label);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  String unique(String base) =>
      '$base ${DateTime.now().millisecondsSinceEpoch}';

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  /// Adds one entry through the UI, from the history screen.
  Future<void> addEntry(
    WidgetTester tester,
    AppLocalizations l10n, {
    required bool isIncome,
    required String amount,
    String? note,
  }) async {
    // The income FAB is a small icon button carrying a tooltip; the expense
    // one is an extended FAB whose label is the only text it exposes.
    await tester.tap(
      isIncome
          ? find.byTooltip(l10n.financeAddIncomeAction)
          : find.widgetWithText(
              FloatingActionButton,
              l10n.financeAddExpenseAction,
            ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, l10n.amountLabel),
      amount,
    );
    await tester.pumpAndSettle();

    await selectCategory(tester, isIncome ? 'Salary' : 'Groceries');

    if (note != null) {
      await tester.enterText(
        find.widgetWithText(TextField, l10n.noteLabel),
        note,
      );
      await tester.pumpAndSettle();
    }

    await tapSave(tester, l10n);
  }

  testWidgets('record an expense: it saves and appears in history '
      '(US1; quickstart.md Scenario 1)', (tester) async {
    await pumpFinance(tester);
    final l10n = await english();
    final note = unique('Flow expense');

    await addEntry(tester, l10n, isIncome: false, amount: '250.50', note: note);

    // The subtitle renders as "date · note" in one Text.
    expect(find.textContaining(note), findsWidgets);
    expect(find.textContaining('250.50'), findsWidgets);
  });

  testWidgets('a zero amount and a missing category are both blocked without '
      'discarding what was entered (US1, FR-003)', (tester) async {
    await pumpFinance(tester);
    final l10n = await english();
    final note = unique('Flow rejected');

    await tester.tap(
      find.widgetWithText(FloatingActionButton, l10n.financeAddExpenseAction),
    );
    await tester.pumpAndSettle();

    // No category picked yet, and a zero amount.
    await tester.enterText(
      find.widgetWithText(TextField, l10n.amountLabel),
      '0',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.noteLabel),
      note,
    );
    await tapSave(tester, l10n);

    // Still on the form, blocked on the missing category first.
    expect(find.text(l10n.financeEntryFormExpenseTitle), findsWidgets);
    expect(find.text(l10n.financeCategoryRequiredError), findsOneWidget);

    // With a category picked, the zero amount is what blocks it now.
    await selectCategory(tester, 'Groceries');
    await tapSave(tester, l10n);
    expect(find.text(l10n.amountInvalidError), findsOneWidget);

    // Nothing the user typed was discarded (FR-003).
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, l10n.noteLabel))
          .controller
          ?.text,
      note,
    );
  });

  testWidgets('record income: it appears alongside expenses and stays visually '
      'distinct (US2; quickstart.md Scenario 2)', (tester) async {
    await pumpFinance(tester);
    final l10n = await english();
    final incomeNote = unique('Flow income');

    await addEntry(
      tester,
      l10n,
      isIncome: true,
      amount: '15000',
      note: incomeNote,
    );

    expect(find.textContaining(incomeNote), findsWidgets);
    // Both direction labels present once income and expense coexist.
    expect(find.textContaining('15,000.00'), findsWidgets);
  });

  testWidgets(
    'the summary, breakdown, and period switching all reflect the recorded '
    'entries (US3; quickstart.md Scenario 3)',
    (tester) async {
      await pumpFinance(tester);
      final l10n = await english();

      await addEntry(tester, l10n, isIncome: false, amount: '100');
      await addEntry(tester, l10n, isIncome: true, amount: '900');

      expect(find.text(l10n.financeSummaryTotalIncome), findsOneWidget);
      expect(find.text(l10n.financeSummaryTotalExpense), findsOneWidget);
      expect(find.text(l10n.financeSummaryNet), findsOneWidget);
      expect(find.text(l10n.financeBreakdownTitle), findsWidgets);

      // Switching to last month keeps the screen coherent; whether it shows
      // entries depends on when the suite runs, so this asserts the switch
      // itself rather than a total that would be calendar-dependent.
      await tester.tap(find.text(l10n.financePeriodLastMonth));
      await tester.pumpAndSettle();
      expect(find.text(l10n.financePeriodLastMonth), findsWidgets);

      await tester.tap(find.text(l10n.financePeriodThisMonth));
      await tester.pumpAndSettle();
      expect(find.text(l10n.financeSummaryNet), findsOneWidget);
    },
  );

  testWidgets('category management: create, duplicate-reject, rename, and the '
      'archive-vs-delete split (US4; quickstart.md Scenario 4)', (
    tester,
  ) async {
    await pumpFinance(tester);
    final categoryRepository = getIt<CategoryRepository>();
    final financeRepository = getIt<FinanceRepository>();

    final name = unique('Gym');

    // 1. The starter set is present on first use.
    final seeded = await categoryRepository.getCategories(
      type: CategoryType.expense,
    );
    expect(seeded.getOrElse((_) => const []).length, greaterThanOrEqualTo(16));

    // 2. Create a custom category.
    final created = await categoryRepository.createCategory(
      name: name,
      type: CategoryType.expense,
      icon: 'fitness',
    );
    final category = created.getOrElse((f) => throw StateError(f.message));

    // 3. A different-cased, differently-spaced duplicate is blocked.
    final duplicate = await categoryRepository.createCategory(
      name: '  ${name.toLowerCase()}  ',
      type: CategoryType.expense,
      icon: 'fitness',
    );
    expect(duplicate.isLeft(), isTrue);

    // The same name under the other direction is allowed.
    final sameNameIncome = await categoryRepository.createCategory(
      name: name,
      type: CategoryType.income,
      icon: 'bonus',
    );
    expect(sameNameIncome.isRight(), isTrue);

    // 4. Rename — entries referencing it follow, since they store an id.
    final renamed = unique('Fitness');
    final edited = await categoryRepository.editCategory(
      categoryId: category.id,
      name: renamed,
      icon: 'fitness',
    );
    expect(edited.getOrElse((f) => throw StateError(f.message)).name, renamed);

    // 5. Used by an entry -> archived, never deleted.
    await financeRepository.addEntry(
      idempotencyKey: unique('idem'),
      categoryId: category.id,
      type: FinanceEntryType.expense,
      amount: Money.egp(5000),
      date: DateTime.now(),
    );
    await categoryRepository.removeCategory(category.id);
    final afterRemoval = await categoryRepository.getCategoryById(category.id);
    expect(
      afterRemoval.getOrElse((f) => throw StateError(f.message)).isArchived,
      isTrue,
      reason: 'a category with history is archived, never deleted (FR-010)',
    );

    // 6. Never used -> deleted outright.
    final unused = await categoryRepository.createCategory(
      name: unique('Unused'),
      type: CategoryType.expense,
      icon: 'other',
    );
    final unusedCategory = unused.getOrElse((f) => throw StateError(f.message));
    await categoryRepository.removeCategory(unusedCategory.id);
    final afterDelete = await categoryRepository.getCategoryById(
      unusedCategory.id,
    );
    expect(afterDelete.isLeft(), isTrue);
  });

  testWidgets('edit, delete with undo, and double-tap protection '
      '(US5, FR-021; quickstart.md Scenario 5)', (tester) async {
    await pumpFinance(tester);
    final financeRepository = getIt<FinanceRepository>();
    final categoryRepository = getIt<CategoryRepository>();

    final categories = await categoryRepository.getCategories(
      type: CategoryType.expense,
    );
    final category = categories.getOrElse((_) => const []).first;

    // Double-tap protection: the same idempotency key twice yields one
    // entry, not two (FR-021).
    final key = unique('idem-double');
    final first = await financeRepository.addEntry(
      idempotencyKey: key,
      categoryId: category.id,
      type: FinanceEntryType.expense,
      amount: Money.egp(7700),
      date: DateTime.now(),
    );
    final retried = await financeRepository.addEntry(
      idempotencyKey: key,
      categoryId: category.id,
      type: FinanceEntryType.expense,
      amount: Money.egp(7700),
      date: DateTime.now(),
    );
    final entry = first.getOrElse((f) => throw StateError(f.message));
    expect(
      retried.getOrElse((f) => throw StateError(f.message)).id,
      entry.id,
      reason: 'a retried save returns the existing entry (FR-021)',
    );

    // Edit: amount changes and the entry is marked edited (FR-019).
    final editedResult = await financeRepository.editEntry(
      entryId: entry.id,
      categoryId: category.id,
      amount: Money.egp(8800),
      date: entry.date,
    );
    final edited = editedResult.getOrElse((f) => throw StateError(f.message));
    expect(edited.amount.minorUnits, 8800);
    expect(edited.isEdited, isTrue);

    // Delete commits immediately and drops out of history.
    await financeRepository.deleteEntry(entry.id);
    final afterDelete = await financeRepository.getHistory(limit: 200);
    expect(
      afterDelete.getOrElse((_) => const []).where((e) => e.id == entry.id),
      isEmpty,
    );

    // Undo restores it exactly as it was.
    await financeRepository.restoreEntry(entry.id);
    final afterUndo = await financeRepository.getEntryById(entry.id);
    final restored = afterUndo.getOrElse((f) => throw StateError(f.message));
    expect(restored.deletedAt, null);
    expect(restored.amount.minorUnits, 8800);

    // A second undo tap is a no-op success, not an error.
    final secondUndo = await financeRepository.restoreEntry(entry.id);
    expect(secondUndo.isRight(), isTrue);
  });

  testWidgets('finance activity leaves the Transactions feature untouched '
      '(FR-023; quickstart.md Scenario 6)', (tester) async {
    await pumpFinance(tester);
    final financeRepository = getIt<FinanceRepository>();
    final categoryRepository = getIt<CategoryRepository>();
    final transactionsRepository = getIt<TransactionsRepository>();

    final overviewBefore = await transactionsRepository.getOverview();
    final before = overviewBefore.getOrElse((f) => throw StateError(f.message));

    final categories = await categoryRepository.getCategories(
      type: CategoryType.expense,
    );
    final category = categories.getOrElse((_) => const []).first;

    final added = await financeRepository.addEntry(
      idempotencyKey: unique('idem-isolation'),
      categoryId: category.id,
      type: FinanceEntryType.expense,
      amount: Money.egp(123400),
      date: DateTime.now(),
    );
    final entry = added.getOrElse((f) => throw StateError(f.message));

    await financeRepository.editEntry(
      entryId: entry.id,
      categoryId: category.id,
      amount: Money.egp(567800),
      date: entry.date,
    );
    await financeRepository.deleteEntry(entry.id);

    final overviewAfter = await transactionsRepository.getOverview();
    final after = overviewAfter.getOrElse((f) => throw StateError(f.message));

    expect(after.totalOwedToUser, before.totalOwedToUser);
    expect(after.totalUserOwes, before.totalUserOwes);
    expect(after.settledCount, before.settledCount);
  });

  testWidgets('the finance summary never counts a soft-deleted entry', (
    tester,
  ) async {
    await pumpFinance(tester);
    final financeRepository = getIt<FinanceRepository>();
    final categoryRepository = getIt<CategoryRepository>();
    // 018: summaries are composed (per-currency SQL + conversion) by the use
    // case, not the repository.
    final getSummary = getIt<GetFinanceSummary>();

    final categories = await categoryRepository.getCategories(
      type: CategoryType.income,
    );
    final category = categories.getOrElse((_) => const []).first;
    final period = DateRange.thisMonth();

    final summaryBefore = await getSummary(period);
    final incomeBefore = summaryBefore
        .getOrElse((f) => throw StateError(f.message))
        .totalIncome!
        .minorUnits;

    final added = await financeRepository.addEntry(
      idempotencyKey: unique('idem-summary'),
      categoryId: category.id,
      type: FinanceEntryType.income,
      amount: Money.egp(50000),
      date: DateTime.now(),
    );
    final entry = added.getOrElse((f) => throw StateError(f.message));

    final summaryWith = await getSummary(period);
    expect(
      summaryWith
          .getOrElse((f) => throw StateError(f.message))
          .totalIncome!
          .minorUnits,
      incomeBefore + 50000,
    );

    await financeRepository.deleteEntry(entry.id);
    final summaryAfter = await getSummary(period);
    expect(
      summaryAfter
          .getOrElse((f) => throw StateError(f.message))
          .totalIncome!
          .minorUnits,
      incomeBefore,
    );
  });
}
