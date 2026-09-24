import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/delete_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_history.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/restore_finance_entry.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_history_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_history_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/conversion_fakes.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class _FilterFallback extends Fake implements FinanceHistoryFilter {}

/// T037 + T067 — the history Cubit coordinates the three period-scoped
/// queries as one unit (FR-014/FR-015/FR-012), keeps true-empty and
/// no-match distinguishable (FR-017/FR-018), and drives the delete/undo
/// window (FR-020, research.md Decision 8).
void main() {
  late MockFinanceRepository financeRepository;
  late FakeGetConversionContext getConversionContext;
  late MockCategoryRepository categoryRepository;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final groceries = Category(
    id: 'seed_groceries',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: 'groceries',
    isDefault: true,
    createdAt: today,
    updatedAt: today,
  );
  final salary = Category(
    id: 'seed_salary',
    name: 'Salary',
    type: CategoryType.income,
    icon: 'salary',
    isDefault: true,
    createdAt: today,
    updatedAt: today,
  );

  FinanceEntry entry(String id, FinanceEntryType type, int amount) =>
      FinanceEntry(
        id: id,
        idempotencyKey: 'key-$id',
        categoryId: type == FinanceEntryType.income
            ? 'seed_salary'
            : 'seed_groceries',
        type: type,
        amount: Money.egp(amount),
        date: today,
        createdAt: today,
      );

  final expenseEntry = entry('e1', FinanceEntryType.expense, 4575);
  final incomeEntry = entry('i1', FinanceEntryType.income, 1000000);

  final summary = FinanceSummary(
    totalIncome: const Money.egp(1000000),
    totalExpense: const Money.egp(4575),
    period: DateRange.thisMonth(),
  );

  const periodTotals = FinancePeriodTotals(
    income: [Money.egp(1000000)],
    expense: [Money.egp(4575)],
  );

  const categoryTotals = [
    CategoryCurrencyTotals(
      categoryId: 'seed_groceries',
      categoryName: 'Groceries',
      icon: 'groceries',
      totals: [Money.egp(4575)],
    ),
  ];

  const breakdown = CategoryBreakdown(
    items: [
      CategoryBreakdownItem(
        categoryId: 'seed_groceries',
        categoryName: 'Groceries',
        icon: 'groceries',
        total: Money.egp(4575),
        shareOfPeriod: 1,
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(DateRange.thisMonth());
    registerFallbackValue(_FilterFallback());
  });

  setUp(() {
    getConversionContext = FakeGetConversionContext();
    financeRepository = MockFinanceRepository();
    categoryRepository = MockCategoryRepository();

    when(
      () => categoryRepository.getCategories(
        type: CategoryType.expense,
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right([groceries]));
    when(
      () => categoryRepository.getCategories(
        type: CategoryType.income,
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => Right([salary]));
    when(
      () => financeRepository.hasAnyEntry(),
    ).thenAnswer((_) async => const Right(true));
    when(
      () => financeRepository.getSummaryTotals(any()),
    ).thenAnswer((_) async => const Right(periodTotals));
    when(
      () =>
          financeRepository.getCategoryTotals(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => const Right(categoryTotals));
    when(
      () => financeRepository.getHistory(
        filter: any(named: 'filter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => Right([expenseEntry, incomeEntry]));
  });

  FinanceHistoryCubit buildCubit() => FinanceHistoryCubit(
    GetFinanceSummary(
      financeRepository,
      getConversionContext,
      const CurrencyConverterImpl(),
    ),
    GetCategoryBreakdown(
      financeRepository,
      getConversionContext,
      const CurrencyConverterImpl(),
    ),
    GetFinanceHistory(financeRepository),
    GetCategories(categoryRepository),
    DeleteFinanceEntry(financeRepository),
    RestoreFinanceEntry(financeRepository),
    financeRepository,
  );

  blocTest<FinanceHistoryCubit, FinanceHistoryState>(
    'load() resolves "this month" and loads summary, breakdown, and history '
    'together (FR-014/FR-015/FR-012)',
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FinanceHistoryState>().having(
        (s) => s.status,
        'status',
        FinanceHistoryStatus.loading,
      ),
      isA<FinanceHistoryState>()
          .having((s) => s.status, 'status', FinanceHistoryStatus.success)
          .having(
            (s) => s.periodPreset,
            'preset',
            FinancePeriodPreset.thisMonth,
          )
          .having((s) => s.period, 'period', DateRange.thisMonth())
          .having((s) => s.summary, 'summary', summary)
          .having((s) => s.breakdown, 'breakdown', breakdown)
          .having((s) => s.entries.length, 'entries', 2)
          // The category lookup each row renders its name/icon from.
          .having(
            (s) => s.categoriesById.keys,
            'categoriesById',
            containsAll(<String>['seed_groceries', 'seed_salary']),
          )
          .having((s) => s.isTrueEmpty, 'isTrueEmpty', isFalse)
          .having((s) => s.isNoMatch, 'isNoMatch', isFalse),
    ],
    verify: (_) {
      verify(
        () => financeRepository.getSummaryTotals(DateRange.thisMonth()),
      ).called(1);
      verify(
        () => financeRepository.getCategoryTotals(
          DateRange.thisMonth(),
          type: null,
        ),
      ).called(1);
      verify(
        () => financeRepository.getHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(1);
    },
  );

  blocTest<FinanceHistoryCubit, FinanceHistoryState>(
    'switching to last month reloads all three against the new period '
    '(FR-016)',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.periodChanged(FinancePeriodPreset.lastMonth);
    },
    verify: (cubit) {
      expect(cubit.state.periodPreset, FinancePeriodPreset.lastMonth);
      expect(cubit.state.period, DateRange.lastMonth());
      verify(
        () => financeRepository.getSummaryTotals(DateRange.lastMonth()),
      ).called(1);
      verify(
        () => financeRepository.getCategoryTotals(
          DateRange.lastMonth(),
          type: null,
        ),
      ).called(1);
      final captured = verify(
        () => financeRepository.getHistory(
          filter: captureAny(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).captured;
      expect(
        (captured.last as FinanceHistoryFilter).dateRange,
        DateRange.lastMonth(),
      );
    },
  );

  blocTest<FinanceHistoryCubit, FinanceHistoryState>(
    'a custom range is used verbatim for all three queries (FR-016)',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.periodChanged(
        FinancePeriodPreset.custom,
        customRange: DateRange(
          start: DateTime(2026, 1, 3),
          end: DateTime(2026, 2, 9),
        ),
      );
    },
    verify: (cubit) {
      expect(cubit.state.periodPreset, FinancePeriodPreset.custom);
      expect(cubit.state.period.start, DateTime(2026, 1, 3));
      expect(cubit.state.period.end, DateTime(2026, 2, 9));
      verify(
        () => financeRepository.getSummaryTotals(
          DateRange(start: DateTime(2026, 1, 3), end: DateTime(2026, 2, 9)),
        ),
      ).called(1);
    },
  );

  blocTest<FinanceHistoryCubit, FinanceHistoryState>(
    'type and category filters combine into one history filter, and '
    'clearFilters drops both (FR-013)',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.typeFilterChanged(FinanceEntryType.expense);
      await cubit.categoryFilterChanged('seed_groceries');
      await cubit.clearFilters();
    },
    verify: (cubit) {
      final captured = verify(
        () => financeRepository.getHistory(
          filter: captureAny(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).captured.cast<FinanceHistoryFilter>();

      expect(captured[1].type, FinanceEntryType.expense);
      expect(captured[1].categoryId, isNull);
      expect(captured[2].type, FinanceEntryType.expense);
      expect(captured[2].categoryId, 'seed_groceries');
      expect(captured[3].type, isNull);
      expect(captured[3].categoryId, isNull);
      // The period survives a filter reset — only the filters are dropped.
      expect(captured[3].dateRange, DateRange.thisMonth());
      expect(cubit.state.hasFilters, isFalse);
    },
  );

  blocTest<FinanceHistoryCubit, FinanceHistoryState>(
    'selecting the opposite direction drops a category filter that no longer '
    'applies',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.categoryFilterChanged('seed_groceries');
      await cubit.typeFilterChanged(FinanceEntryType.income);
    },
    verify: (cubit) {
      expect(cubit.state.typeFilter, FinanceEntryType.income);
      expect(cubit.state.categoryFilter, isNull);
    },
  );

  blocTest<FinanceHistoryCubit, FinanceHistoryState>(
    'true-empty: nothing has ever been recorded (FR-017)',
    build: buildCubit,
    setUp: () {
      when(
        () => financeRepository.hasAnyEntry(),
      ).thenAnswer((_) async => const Right(false));
      when(
        () => financeRepository.getHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Right(<FinanceEntry>[]));
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.isTrueEmpty, isTrue);
      expect(cubit.state.isNoMatch, isFalse);
    },
  );

  blocTest<FinanceHistoryCubit, FinanceHistoryState>(
    'no-match: entries exist but the current filter matches none of them, '
    'which is a different state from true-empty (FR-018)',
    build: buildCubit,
    setUp: () {
      when(
        () => financeRepository.getHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Right(<FinanceEntry>[]));
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.periodChanged(FinancePeriodPreset.lastMonth);
    },
    verify: (cubit) {
      expect(cubit.state.hasAnyEntry, isTrue);
      expect(cubit.state.isNoMatch, isTrue);
      expect(cubit.state.isTrueEmpty, isFalse);
    },
  );

  blocTest<FinanceHistoryCubit, FinanceHistoryState>(
    'surfaces a load failure with a retryable error state',
    build: buildCubit,
    setUp: () {
      when(
        () => financeRepository.getSummaryTotals(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db is unhappy')));
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.isFailure, isTrue);
      expect(cubit.state.errorMessage, 'db is unhappy');
    },
  );

  group('delete + undo (FR-020, T067)', () {
    late Set<String> deletedIds;

    setUp(() {
      deletedIds = <String>{};
      when(
        () => financeRepository.getHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => Right([
          for (final e in [expenseEntry, incomeEntry])
            if (!deletedIds.contains(e.id)) e,
        ]),
      );
      when(() => financeRepository.deleteEntry(any())).thenAnswer((
        invocation,
      ) async {
        deletedIds.add(invocation.positionalArguments.first as String);
        return const Right(unit);
      });
      when(() => financeRepository.restoreEntry(any())).thenAnswer((
        invocation,
      ) async {
        final id = invocation.positionalArguments.first as String;
        deletedIds.remove(id);
        return Right(id == expenseEntry.id ? expenseEntry : incomeEntry);
      });
    });

    blocTest<FinanceHistoryCubit, FinanceHistoryState>(
      'deleting removes the entry and exposes it for the undo window',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.deleteEntry(expenseEntry.id);
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoEntryId, expenseEntry.id);
        expect(cubit.state.entries.map((e) => e.id), ['i1']);
        verify(() => financeRepository.deleteEntry('e1')).called(1);
      },
    );

    blocTest<FinanceHistoryCubit, FinanceHistoryState>(
      'undo within the window restores the entry and reloads all three',
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.deleteEntry(expenseEntry.id);
        await cubit.undoDelete(expenseEntry.id);
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoEntryId, isNull);
        expect(cubit.state.entries.map((e) => e.id), ['e1', 'i1']);
        verify(() => financeRepository.restoreEntry('e1')).called(1);
        // Three loads: the initial one, the post-delete one, the post-undo
        // one — the totals never lag behind the list.
        verify(() => financeRepository.getSummaryTotals(any())).called(3);
      },
    );

    blocTest<FinanceHistoryCubit, FinanceHistoryState>(
      'letting the window expire clears the undo affordance and leaves the '
      'entry deleted',
      build: () => buildCubit()..undoWindow = const Duration(milliseconds: 20),
      act: (cubit) async {
        await cubit.load();
        await cubit.deleteEntry(expenseEntry.id);
        await Future<void>.delayed(const Duration(milliseconds: 60));
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoEntryId, isNull);
        expect(cubit.state.entries.map((e) => e.id), ['i1']);
        verifyNever(() => financeRepository.restoreEntry(any()));
      },
    );
  });

  group('multi-currency (018)', () {
    setUp(() {
      when(() => financeRepository.getSummaryTotals(any())).thenAnswer(
        (_) async => Right(
          FinancePeriodTotals(
            income: const [Money.egp(1000000)],
            expense: [
              const Money.egp(4575),
              Money.fromMinorUnits(2000, Currency.usd),
            ],
          ),
        ),
      );
    });

    blocTest<FinanceHistoryCubit, FinanceHistoryState>(
      'a missing rate carries the blocked summary, naming the currency, up '
      'to the state (FR-009)',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final summary = cubit.state.summary!;
        expect(cubit.state.status, FinanceHistoryStatus.success);
        expect(summary.isBlocked, isTrue);
        expect(summary.missingRatesFor, [Currency.usd]);
        expect(summary.totalIncome, isNull);
        expect(summary.net, isNull);
        expect(cubit.state.primaryCurrency, Currency.egp);
      },
    );

    blocTest<FinanceHistoryCubit, FinanceHistoryState>(
      'with the rate set, the summary is converted into the primary currency',
      build: () {
        getConversionContext.context = ConversionContext(
          primary: Currency.egp,
          rates: [rate(Currency.usd, Currency.egp, 50)],
        );
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final summary = cubit.state.summary!;
        expect(summary.isBlocked, isFalse);
        // 4,575 piastres + 20.00 USD × 50 = 45.75 + 1,000.00 EGP.
        expect(summary.totalExpense, const Money.egp(4575 + 100000));
      },
    );
  });
}
