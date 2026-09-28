import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/entities/spending_trend_point.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_spending_trend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetFinanceSummary extends Mock implements GetFinanceSummary {}

/// 013 T005 — the trend is `GetFinanceSummary` called once per calendar
/// month (so every point is already in the primary currency, 018),
/// concurrently, and fails as a unit (contracts/get_spending_trend.md,
/// FR-001/FR-003/FR-005).
void main() {
  late MockGetFinanceSummary getSummary;
  late GetSpendingTrend useCase;

  final reference = DateTime(2026, 9, 24);

  FinanceSummary summaryFor(DateRange period) => FinanceSummary(
    // Distinct, month-derived figures so a mis-ordered or mis-mapped point
    // cannot pass by coincidence.
    totalIncome: Money.egp(period.start.month * 1000 + 1),
    totalExpense: Money.egp(period.start.month * 100 + 7),
    period: period,
  );

  setUpAll(() {
    registerFallbackValue(DateRange.thisMonth());
  });

  setUp(() {
    getSummary = MockGetFinanceSummary();
    useCase = GetSpendingTrend(getSummary);
    when(() => getSummary(any())).thenAnswer(
      (invocation) async =>
          Right(summaryFor(invocation.positionalArguments.first as DateRange)),
    );
  });

  test('asks GetFinanceSummary for each of the last N calendar months, oldest '
      'first, ending with this month to date', () async {
    final result = await useCase(monthsBack: 3, reference: reference);

    final points = result.getOrElse((f) => throw StateError(f.message));
    expect(points.map((p) => p.period).toList(), [
      DateRange(start: DateTime(2026, 7), end: DateTime(2026, 7, 31)),
      DateRange(start: DateTime(2026, 8), end: DateTime(2026, 8, 31)),
      // The current month matches `DateRange.thisMonth` exactly, so its
      // point is the same figure the history screen and Home show.
      DateRange.thisMonth(reference),
    ]);
    verify(() => getSummary(any())).called(3);
  });

  test('defaults to a six-month window and crosses year boundaries', () async {
    final result = await useCase(reference: DateTime(2026, 2, 10));

    final periods = result
        .getOrElse((f) => throw StateError(f.message))
        .map((p) => p.period.start)
        .toList();
    expect(periods, [
      DateTime(2025, 9),
      DateTime(2025, 10),
      DateTime(2025, 11),
      DateTime(2025, 12),
      DateTime(2026),
      DateTime(2026, 2),
    ]);
  });

  test('each point is a straight re-shaping of that month\'s summary, never '
      'a recomputation (FR-003)', () async {
    final result = await useCase(monthsBack: 2, reference: reference);

    final points = result.getOrElse((f) => throw StateError(f.message));
    for (final point in points) {
      final summary = summaryFor(point.period);
      expect(
        point,
        SpendingTrendPoint(
          period: point.period,
          totalIncomeMinorUnits: summary.totalIncome!.minorUnits,
          totalExpenseMinorUnits: summary.totalExpense!.minorUnits,
          netMinorUnits: summary.net!.minorUnits,
        ),
      );
    }
  });

  test('runs the per-month reads concurrently: elapsed time is roughly the '
      'slowest call, not the sum', () async {
    const perCall = Duration(milliseconds: 120);
    when(() => getSummary(any())).thenAnswer((invocation) async {
      await Future<void>.delayed(perCall);
      return Right(
        summaryFor(invocation.positionalArguments.first as DateRange),
      );
    });

    final stopwatch = Stopwatch()..start();
    final result = await useCase(monthsBack: 6, reference: reference);
    stopwatch.stop();

    expect(result.isRight(), isTrue);
    // Sequential would be ~720ms; concurrent is ~120ms plus overhead.
    expect(stopwatch.elapsed, lessThan(perCall * 3));
  });

  test('starts every month\'s read before any of them completes', () async {
    final gates = <Completer<Either<Failure, FinanceSummary>>>[];
    when(() => getSummary(any())).thenAnswer((_) {
      final gate = Completer<Either<Failure, FinanceSummary>>();
      gates.add(gate);
      return gate.future;
    });

    final pending = useCase(monthsBack: 4, reference: reference);
    await Future<void>.delayed(Duration.zero);
    expect(gates, hasLength(4));

    for (final gate in gates) {
      gate.complete(Right(FinanceSummary.empty(DateRange.thisMonth())));
    }
    expect((await pending).isRight(), isTrue);
  });

  test('a failure on any single month fails the whole trend rather than '
      'silently dropping that month (FR-005)', () async {
    const failure = CacheFailure('disk read failed');
    final failingMonth = DateTime(2026, 8);
    when(() => getSummary(any())).thenAnswer((invocation) async {
      final period = invocation.positionalArguments.first as DateRange;
      if (period.start == failingMonth) return const Left(failure);
      return Right(summaryFor(period));
    });

    final result = await useCase(monthsBack: 6, reference: reference);

    expect(result, const Left<Failure, List<SpendingTrendPoint>>(failure));
  });

  test('a month that needs a missing exchange rate fails the trend as '
      'RatesMissingFailure, naming every such currency (018 FR-009)', () async {
    when(() => getSummary(any())).thenAnswer((invocation) async {
      final period = invocation.positionalArguments.first as DateRange;
      if (period.start == DateTime(2026, 8)) {
        return Right(
          FinanceSummary.blocked(
            period: period,
            currency: Currency.egp,
            missingRatesFor: const [Currency.usd],
          ),
        );
      }
      return Right(summaryFor(period));
    });

    final result = await useCase(monthsBack: 3, reference: reference);

    expect(
      result.getLeft().toNullable(),
      isA<RatesMissingFailure>().having(
        (f) => f.missingRatesFor,
        'missingRatesFor',
        [Currency.usd],
      ),
    );
  });
}
