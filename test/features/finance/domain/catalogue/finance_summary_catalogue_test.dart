import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/catalogue_fixtures.dart';

/// 022 Phase 2 (T008) — finance-summary catalogue. Income and expense stay
/// separate from person and savings money; the net can be negative. Every
/// figure is an exact integer count of minor units.
void main() {
  late CatalogueEnv env;

  final october = DateRange(
    start: DateTime(2026, 10, 1),
    end: DateTime(2026, 10, 31),
  );
  final november = DateRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );

  setUp(() async => env = await CatalogueEnv.open());
  tearDown(() => env.close());

  Future<FinanceSummary> summaryOf(DateRange period) async =>
      unwrapOrThrow(await env.financeSummary(period));

  group('CHK036 income only', () {
    test('Income 10,000.00 on 2026-10-01 => income 1000000, expense 0, net '
        '1000000, and no person balance changes', () async {
      await env.give('ahmed', 150000);
      final before = await env.net('ahmed');

      await env.income(1000000, DateTime(2026, 10, 1));

      final summary = await summaryOf(october);
      expect(summary.totalIncome, const Money.egp(1000000));
      expect(summary.totalExpense, const Money.egp(0));
      expect(summary.net, const Money.egp(1000000));
      expect(await env.net('ahmed'), before);
      expect(before, 150000);
    });
  });

  group('CHK037 income lands in its own month', () {
    test('October stays 1000000 after November income of 500000', () async {
      await env.income(1000000, DateTime(2026, 10, 1));
      await env.income(500000, DateTime(2026, 11, 1));

      expect((await summaryOf(october)).totalIncome, const Money.egp(1000000));
      expect((await summaryOf(november)).totalIncome, const Money.egp(500000));
    });
  });

  group('CHK038 income never touches a budget line', () {
    test('Food actual stays 0 after income is added', () async {
      await env.budget('2026-10', {catFood: 200000});
      final before = unwrapOrThrow(
        await env.budgets.getBudgetForMonth('2026-10'),
      );
      expect(
        before.summary!.categoryBreakdown.single.actualAmountMinorUnits,
        0,
      );

      await env.income(1000000, DateTime(2026, 10, 1));

      final after = unwrapOrThrow(
        await env.budgets.getBudgetForMonth('2026-10'),
      );
      expect(after.summary!.categoryBreakdown.single.actualAmountMinorUnits, 0);
      expect(after.summary!.totalActualMinorUnits, 0);
    });
  });

  group('CHK039 income and expenses together', () {
    test('income 1000000, Food 120000 + Transport 30000 => expense 150000, '
        'net 850000', () async {
      await env.income(1000000, DateTime(2026, 10, 1));
      await env.expense(catFood, 120000, DateTime(2026, 10, 3));
      await env.expense(catTransport, 30000, DateTime(2026, 10, 4));

      final summary = await summaryOf(october);

      expect(summary.totalIncome, const Money.egp(1000000));
      expect(summary.totalExpense, const Money.egp(150000));
      expect(summary.net, const Money.egp(850000));
    });
  });

  group('CHK040 spending above income', () {
    test('income 100000 - expense 150000 => net -50000', () async {
      await env.income(100000, DateTime(2026, 10, 1));
      await env.expense(catFood, 150000, DateTime(2026, 10, 3));

      final summary = await summaryOf(october);

      expect(summary.net, const Money.egp(-50000));
      expect(summary.net!.isNegative, isTrue);
      expect(summary.totalExpense, const Money.egp(150000));
    });
  });

  group('CHK041 a loan to a person is not an expense', () {
    test(
      'October expense stays 150000 after "I gave" 1,000.00 to Ahmed',
      () async {
        await env.expense(catFood, 150000, DateTime(2026, 10, 3));

        await env.give('ahmed', 100000, date: DateTime(2026, 10, 5));

        expect(
          (await summaryOf(october)).totalExpense,
          const Money.egp(150000),
        );
        expect(await env.net('ahmed'), 100000);
      },
    );
  });

  group('CHK042 a savings contribution is not an expense', () {
    test(
      'October expense stays 150000 after logging 2,000.00 to a goal',
      () async {
        await env.expense(catFood, 150000, DateTime(2026, 10, 3));
        final goal = await env.goal();

        await env.contribute(goal.id, 200000);

        final summary = await summaryOf(october);
        expect(summary.totalExpense, const Money.egp(150000));
        expect(summary.totalIncome, const Money.egp(0));
      },
    );
  });

  group('CHK075 category breakdown', () {
    test('Food 120000 (80%) and Transport 30000 (20%) add up to exactly '
        '150000', () async {
      await env.expense(catFood, 120000, DateTime(2026, 10, 3));
      await env.expense(catTransport, 30000, DateTime(2026, 10, 4));

      final breakdown = unwrapOrThrow(await env.categoryBreakdown(october));

      expect(breakdown.items.map((i) => i.categoryId), [catFood, catTransport]);
      expect(breakdown.items[0].total, const Money.egp(120000));
      expect((breakdown.items[0].shareOfPeriod! * 100).round(), 80);
      expect(breakdown.items[1].total, const Money.egp(30000));
      expect((breakdown.items[1].shareOfPeriod! * 100).round(), 20);
      final sum = breakdown.items.fold<int>(
        0,
        (s, i) => s + i.total!.minorUnits,
      );
      expect(sum, 150000);
    });
  });
}
