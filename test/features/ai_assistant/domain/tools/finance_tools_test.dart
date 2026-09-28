import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/compare_spending_across_periods.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_category_spend.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_top_spending_category.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_arguments.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCategoryBreakdown extends Mock implements GetCategoryBreakdown {}

class MockGetCategories extends Mock implements GetCategories {}

class MockGetFinanceSummary extends Mock implements GetFinanceSummary {}

final _now = DateTime(2026, 9, 24, 15, 30);
final _thisMonth = DateRange(start: DateTime(2026, 9, 1), end: _now);
final _lastMonth = DateRange(
  start: DateTime(2026, 8, 1),
  end: DateTime(2026, 8, 31),
);

const _thisMonthArg = {AIToolArgs.preset: AIPeriodPresets.thisMonth};
const _lastMonthArg = {AIToolArgs.preset: AIPeriodPresets.lastMonth};

// Deliberately awkward values: any rounding, scaling or recomputation in a
// tool would change them.
const _food = CategoryBreakdownItem(
  categoryId: 'c-food',
  categoryName: 'Food',
  icon: 'food',
  total: Money.egp(123457),
  shareOfPeriod: 0.6173123456789,
);
const _transport = CategoryBreakdownItem(
  categoryId: 'c-transport',
  categoryName: 'Transport',
  icon: 'car',
  total: Money.egp(76543),
  shareOfPeriod: 0.3826876543211,
);

Category _category(String id, String name) => Category(
  id: id,
  name: name,
  type: FinanceEntryType.expense,
  icon: 'x',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

FinanceSummary _summary(DateRange period, int expense) => FinanceSummary(
  totalIncome: const Money.egp(999999),
  totalExpense: Money.egp(expense),
  period: period,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_thisMonth);
    registerFallbackValue(FinanceEntryType.expense);
  });

  late MockGetCategoryBreakdown getCategoryBreakdown;
  late MockGetCategories getCategories;
  late MockGetFinanceSummary getFinanceSummary;
  late AIPeriodResolver periods;

  setUp(() {
    getCategoryBreakdown = MockGetCategoryBreakdown();
    getCategories = MockGetCategories();
    getFinanceSummary = MockGetFinanceSummary();
    periods = AIPeriodResolver.withClock(() => _now);
  });

  void stubBreakdown(List<CategoryBreakdownItem> items) {
    when(
      () => getCategoryBreakdown(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => Right(CategoryBreakdown(items: items)));
  }

  group('GetCategorySpendTool', () {
    late GetCategorySpendTool tool;

    setUp(() {
      tool = GetCategorySpendTool(getCategoryBreakdown, getCategories, periods);
    });

    test('all categories: copies the breakdown through unchanged, for '
        "expenses only, over 007's own thisMonth preset", () async {
      stubBreakdown([_food, _transport]);

      final result = (await tool({
        AIToolArgs.period: _thisMonthArg,
      })).getOrElse((f) => fail('$f'));

      verify(
        () => getCategoryBreakdown(_thisMonth, type: FinanceEntryType.expense),
      ).called(1);
      verifyZeroInteractions(getCategories);
      expect(result.toolName, AIToolNames.getCategorySpend);
      expect(result.sourceUseCase, 'GetCategoryBreakdown');
      expect(result.foundData, isTrue);
      expect(result.data['categories'], [
        {
          'name': 'Food',
          'amountMinorUnits': 123457,
          'shareOfPeriod': 0.6173123456789,
        },
        {
          'name': 'Transport',
          'amountMinorUnits': 76543,
          'shareOfPeriod': 0.3826876543211,
        },
      ]);
      expect(result.data['period'], {
        'startDate': '2026-09-01',
        'endDate': '2026-09-24',
      });
      expect(result.data[AIToolDataKeys.currency], 'EGP');
      expect(result.data[AIToolDataKeys.amountUnit], 'minorUnits');
    });

    test('named category: picks the matching entry by id, unchanged, with '
        'case/whitespace-insensitive name resolution', () async {
      stubBreakdown([_food, _transport]);
      when(
        () => getCategories(
          type: FinanceEntryType.expense,
          includeArchived: true,
        ),
      ).thenAnswer(
        (_) async => Right([
          _category('c-food', 'Food'),
          _category('c-transport', 'Transport'),
        ]),
      );

      final result = (await tool({
        AIToolArgs.period: _lastMonthArg,
        AIToolArgs.categoryName: '  TRANSPORT ',
      })).getOrElse((f) => fail('$f'));

      verify(
        () => getCategoryBreakdown(_lastMonth, type: FinanceEntryType.expense),
      ).called(1);
      expect(result.foundData, isTrue);
      expect(result.data['category'], {
        'name': 'Transport',
        'amountMinorUnits': 76543,
        'shareOfPeriod': 0.3826876543211,
      });
    });

    test('an existing category with no spend in the period is a genuine '
        'zero (foundData true), not missing data', () async {
      stubBreakdown([_food]);
      when(
        () => getCategories(
          type: FinanceEntryType.expense,
          includeArchived: true,
        ),
      ).thenAnswer(
        (_) async =>
            Right([_category('c-food', 'Food'), _category('c-rent', 'Rent')]),
      );

      final result = (await tool({
        AIToolArgs.period: _thisMonthArg,
        AIToolArgs.categoryName: 'rent',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isTrue);
      expect(result.data['category'], {
        'name': 'Rent',
        'amountMinorUnits': 0,
        'shareOfPeriod': 0.0,
      });
    });

    test('foundData=false when the period has no expense entries at all, '
        'even for a named category', () async {
      stubBreakdown([]);

      final result = (await tool({
        AIToolArgs.period: _thisMonthArg,
        AIToolArgs.categoryName: 'Food',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.noEntriesForPeriod);
      expect(result.data.containsKey('category'), isFalse);
      verifyZeroInteractions(getCategories);
    });

    test('foundData=false for an unknown category name', () async {
      stubBreakdown([_food]);
      when(
        () => getCategories(
          type: FinanceEntryType.expense,
          includeArchived: true,
        ),
      ).thenAnswer((_) async => Right([_category('c-food', 'Food')]));

      final result = (await tool({
        AIToolArgs.period: _thisMonthArg,
        AIToolArgs.categoryName: 'Holidays',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.categoryNotFound);
    });

    test('foundData=false with candidates for an ambiguous name — never a '
        'best guess', () async {
      stubBreakdown([_food]);
      when(
        () => getCategories(
          type: FinanceEntryType.expense,
          includeArchived: true,
        ),
      ).thenAnswer(
        (_) async =>
            Right([_category('a', 'Car fuel'), _category('b', 'Car repairs')]),
      );

      final result = (await tool({
        AIToolArgs.period: _thisMonthArg,
        AIToolArgs.categoryName: 'car',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.ambiguousCategory);
      expect(result.data['candidates'], ['Car fuel', 'Car repairs']);
    });

    test('passes a use-case failure through unchanged', () async {
      when(
        () => getCategoryBreakdown(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      final result = await tool({AIToolArgs.period: _thisMonthArg});

      expect(result, const Left<Failure, Never>(CacheFailure('db')));
    });

    group('argument validation → ValidationFailure, use case never called', () {
      for (final (label, args) in <(String, Map<String, Object?>)>[
        ('missing period', {}),
        ('period not an object', {AIToolArgs.period: 'thisMonth'}),
        (
          'unknown preset',
          {
            AIToolArgs.period: {AIToolArgs.preset: 'lastYear'},
          },
        ),
        (
          'custom without dates',
          {
            AIToolArgs.period: {AIToolArgs.preset: AIPeriodPresets.custom},
          },
        ),
        (
          'categoryName not a string',
          {AIToolArgs.period: _thisMonthArg, AIToolArgs.categoryName: 42},
        ),
      ]) {
        test(label, () async {
          final result = await tool(args);
          expect(result.getLeft().toNullable(), isA<ValidationFailure>());
          verifyZeroInteractions(getCategoryBreakdown);
        });
      }
    });
  });

  group('GetTopSpendingCategoryTool', () {
    late GetTopSpendingCategoryTool tool;

    setUp(() {
      tool = GetTopSpendingCategoryTool(getCategoryBreakdown, periods);
    });

    test('returns the first entry of the use case\'s already-sorted list, '
        'unchanged', () async {
      stubBreakdown([_food, _transport]);

      final result = (await tool({
        AIToolArgs.period: _thisMonthArg,
      })).getOrElse((f) => fail('$f'));

      verify(
        () => getCategoryBreakdown(_thisMonth, type: FinanceEntryType.expense),
      ).called(1);
      expect(result.toolName, AIToolNames.getTopSpendingCategory);
      expect(result.sourceUseCase, 'GetCategoryBreakdown');
      expect(result.foundData, isTrue);
      expect(result.data['category'], {
        'name': 'Food',
        'amountMinorUnits': 123457,
        'shareOfPeriod': 0.6173123456789,
      });
    });

    test('reads list order rather than comparing amounts itself', () async {
      // Out of amount order on purpose: the use case owns the ordering.
      stubBreakdown([_transport, _food]);

      final result = (await tool({
        AIToolArgs.period: _thisMonthArg,
      })).getOrElse((f) => fail('$f'));

      expect((result.data['category']! as Map)['name'], 'Transport');
    });

    test('foundData=false when the period has no expense entries', () async {
      stubBreakdown([]);

      final result = (await tool({
        AIToolArgs.period: _thisMonthArg,
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.noEntriesForPeriod);
      expect(result.data.containsKey('category'), isFalse);
    });

    test('invalid period → ValidationFailure', () async {
      final result = await tool({AIToolArgs.period: <String, Object?>{}});
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyZeroInteractions(getCategoryBreakdown);
    });
  });

  group('CompareSpendingAcrossPeriodsTool', () {
    late CompareSpendingAcrossPeriodsTool tool;

    setUp(() {
      tool = CompareSpendingAcrossPeriodsTool(getFinanceSummary, periods);
    });

    void stubSummary(DateRange period, int expense) {
      when(
        () => getFinanceSummary(period),
      ).thenAnswer((_) async => Right(_summary(period, expense)));
    }

    test(
      'both totals come unmodified from one GetFinanceSummary call per '
      'period; only the documented difference/percentage is derived',
      () async {
        stubSummary(_lastMonth, 200000);
        stubSummary(_thisMonth, 250050);

        final result = (await tool({
          AIToolArgs.periodA: _lastMonthArg,
          AIToolArgs.periodB: _thisMonthArg,
        })).getOrElse((f) => fail('$f'));

        verify(() => getFinanceSummary(_lastMonth)).called(1);
        verify(() => getFinanceSummary(_thisMonth)).called(1);
        expect(result.toolName, AIToolNames.compareSpendingAcrossPeriods);
        expect(result.sourceUseCase, 'GetFinanceSummary');
        expect(result.foundData, isTrue);
        expect(result.data['periodATotalMinorUnits'], 200000);
        expect(result.data['periodBTotalMinorUnits'], 250050);
        expect(result.data['differenceMinorUnits'], 50050);
        expect(result.data['percentChange'], 25.0); // 25.025 → 1 decimal
        // Income is never folded into a spending comparison.
        expect(result.data.values, isNot(contains(999999)));
      },
    );

    test('a decrease is a negative difference and percentage', () async {
      stubSummary(_lastMonth, 300000);
      stubSummary(_thisMonth, 200000);

      final result = (await tool({
        AIToolArgs.periodA: _lastMonthArg,
        AIToolArgs.periodB: _thisMonthArg,
      })).getOrElse((f) => fail('$f'));

      expect(result.data['differenceMinorUnits'], -100000);
      expect(result.data['percentChange'], -33.3);
    });

    test('custom periods resolve to the exact inclusive dates', () async {
      final a = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      final b = DateRange(
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 28),
      );
      stubSummary(a, 100);
      stubSummary(b, 100);

      final result = (await tool({
        AIToolArgs.periodA: {
          AIToolArgs.preset: AIPeriodPresets.custom,
          AIToolArgs.startDate: '2026-01-01',
          AIToolArgs.endDate: '2026-01-31',
        },
        AIToolArgs.periodB: {
          AIToolArgs.preset: AIPeriodPresets.custom,
          AIToolArgs.startDate: '2026-02-01',
          AIToolArgs.endDate: '2026-02-28',
        },
      })).getOrElse((f) => fail('$f'));

      expect(result.data['differenceMinorUnits'], 0);
      expect(result.data['percentChange'], 0.0);
    });

    test('foundData=false when either period has no expenses', () async {
      stubSummary(_lastMonth, 0);
      stubSummary(_thisMonth, 5000);

      final result = (await tool({
        AIToolArgs.periodA: _lastMonthArg,
        AIToolArgs.periodB: _thisMonthArg,
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.noEntriesForPeriod);
      expect(result.data['emptyPeriods'], ['periodA']);
      expect(result.data.containsKey('percentChange'), isFalse);
    });

    test('passes a use-case failure through unchanged', () async {
      when(
        () => getFinanceSummary(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      final result = await tool({
        AIToolArgs.periodA: _lastMonthArg,
        AIToolArgs.periodB: _thisMonthArg,
      });

      expect(result, const Left<Failure, Never>(CacheFailure('db')));
    });

    test(
      'a missing periodB → ValidationFailure, use case never called',
      () async {
        final result = await tool({AIToolArgs.periodA: _lastMonthArg});
        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        verifyZeroInteractions(getFinanceSummary);
      },
    );
  });
}
