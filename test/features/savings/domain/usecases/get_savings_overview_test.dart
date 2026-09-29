import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/archive_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/get_savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/watch_savings_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/savings_harness.dart';

/// T055 — `GetSavingsOverview` (FR-019) through the real repository and
/// 018's real currency repository.
void main() {
  late SavingsHarness h;
  late GetSavingsOverview overview;

  setUp(() async {
    h = await SavingsHarness.open();
    overview = GetSavingsOverview(h.repository);
  });

  tearDown(() => h.close());

  Future<SavingsOverview> load({bool includeArchived = false}) async =>
      (await overview(
        includeArchived: includeArchived,
      )).getOrElse((f) => throw StateError(f.message));

  test(
    'no goals: an empty, complete overview in the primary currency',
    () async {
      final result = await load();

      expect(result.isEmpty, isTrue);
      expect(result.totalSavedMinorUnits, 0);
      expect(result.isIncomplete, isFalse);
      expect(result.primaryCurrency, Currency.egp);
    },
  );

  test('US4 AS-1: each goal is listed, oldest first, with its own progress; '
      'the total sums them', () async {
    final a = await h.createGoal(
      name: 'Emergency',
      target: 1000000,
      starting: 250000,
    );
    h.clock.current = h.clock.current.add(const Duration(minutes: 1));
    final b = await h.createGoal(
      name: 'Vacation',
      target: 500000,
      starting: 100000,
    );
    h.clock.current = h.clock.current.add(const Duration(minutes: 1));
    final c = await h.createGoal(name: 'Phone', target: 300000);
    await h.withdraw(b.id, 40000);

    final result = await load();

    expect([for (final l in result.goals) l.goal.id], [a.id, b.id, c.id]);
    expect(
      [for (final l in result.goals) l.progress.currentAmountMinorUnits],
      [250000, 60000, 0],
    );
    expect(result.goals[0].progress.percentageProgress, 25);
    expect(result.totalSavedMinorUnits, 310000);
    expect(result.isIncomplete, isFalse);
  });

  test('US4 AS-6: a USD goal shows progress in USD; the total converts it '
      'into EGP at the current rate', () async {
    await h.createGoal(name: 'EGP goal', target: 1000000, starting: 100000);
    final usd = await h.createGoal(
      name: 'USD goal',
      currency: Currency.usd,
      target: 100000,
      starting: 10000,
    );
    await h.setRate(Currency.usd, 50);

    final result = await load();

    final usdLine = result.goals.singleWhere((l) => l.goal.id == usd.id);
    expect(usdLine.progress.currency, Currency.usd);
    expect(usdLine.progress.currentAmountMinorUnits, 10000);
    expect(usdLine.progress.targetAmountMinorUnits, 100000);
    // 100.00 USD × 50 = 5,000.00 EGP.
    expect(usdLine.primaryCurrencyAmountMinorUnits, 500000);
    expect(usdLine.isBlocked, isFalse);
    expect(result.totalSaved, Money.fromMinorUnits(600000, Currency.egp));
    expect(result.isIncomplete, isFalse);
  });

  test('US4 AS-7 / FR-019: without the USD rate the USD goal stays listed '
      'with its own progress, is left out of the total, and the total is '
      'marked incomplete naming USD — never converted 1:1', () async {
    await h.createGoal(name: 'EGP goal', target: 1000000, starting: 100000);
    final usd = await h.createGoal(
      name: 'USD goal',
      currency: Currency.usd,
      target: 100000,
      starting: 10000,
    );

    final result = await load();

    final usdLine = result.goals.singleWhere((l) => l.goal.id == usd.id);
    expect(usdLine.isBlocked, isTrue);
    expect(usdLine.primaryCurrencyAmountMinorUnits, isNull);
    expect(usdLine.missingRatesFor, [Currency.usd]);
    expect(usdLine.progress.currentAmountMinorUnits, 10000);
    expect(result.totalSavedMinorUnits, 100000);
    expect(result.isIncomplete, isTrue);
    expect(result.missingRatesFor, [Currency.usd]);
  });

  test('missing rates are named once each, in first-seen order', () async {
    await h.createGoal(currency: Currency.usd, target: 1000, starting: 10);
    await h.createGoal(currency: Currency.eur, target: 1000, starting: 10);
    await h.createGoal(currency: Currency.usd, target: 1000, starting: 20);

    final result = await load();

    expect(result.missingRatesFor, [Currency.usd, Currency.eur]);
    expect(result.totalSavedMinorUnits, 0);
  });

  test('a foreign goal with nothing saved needs no rate: zero is zero in '
      'every currency', () async {
    await h.createGoal(currency: Currency.usd, target: 1000);

    final result = await load();

    expect(result.goals.single.primaryCurrencyAmountMinorUnits, 0);
    expect(result.isIncomplete, isFalse);
  });

  test('the total follows the primary currency: with USD primary an EGP '
      'goal is the one converted', () async {
    await h.createGoal(target: 1000000, starting: 500000);
    await h.createGoal(currency: Currency.usd, target: 100000, starting: 1000);
    await h.setPrimary(Currency.usd);
    await h.setRate(Currency.egp, 0.02, to: Currency.usd);

    final result = await load();

    expect(result.primaryCurrency, Currency.usd);
    // 5,000.00 EGP × 0.02 = 100.00 USD, plus 10.00 USD.
    expect(result.totalSavedMinorUnits, 11000);
    expect(result.isIncomplete, isFalse);
  });

  test('includeArchived toggles archived goals in and out', () async {
    final active = await h.createGoal(name: 'Active', starting: 1000);
    final archived = await h.createGoal(name: 'Paused', starting: 2000);
    await ArchiveSavingsGoal(h.repository)(archived.id);

    final defaultView = await load();
    final withArchived = await load(includeArchived: true);

    expect([for (final l in defaultView.goals) l.goal.id], [active.id]);
    expect(defaultView.totalSavedMinorUnits, 1000);
    expect([
      for (final l in withArchived.goals) l.goal.id,
    ], unorderedEquals([active.id, archived.id]));
    expect(withArchived.totalSavedMinorUnits, 3000);
  });

  test('deleted entries and deleted goals never count', () async {
    final goal = await h.createGoal(target: 100000);
    final entry = await h.contribute(goal.id, 5000);
    await h.contribute(goal.id, 700);
    await h.repository.deleteContribution(entry.id);
    final empty = await h.createGoal(name: 'Mistake');
    await h.repository.deleteSavingsGoal(empty.id);

    final result = await load();

    expect(result.goals.single.goal.id, goal.id);
    expect(result.totalSavedMinorUnits, 700);
  });

  test(
    'live: watchSavingsOverview re-emits on an entry and on a new rate',
    () async {
      final usd = await h.createGoal(currency: Currency.usd, starting: 100);
      final emissions = <SavingsOverview>[];
      final subscription = WatchSavingsOverview(
        h.repository,
      )().listen((result) => emissions.add(result.getOrElse((f) => throw f)));
      Future<void> settle() =>
          Future<void>.delayed(const Duration(milliseconds: 200));

      await settle();
      expect(emissions.last.isIncomplete, isTrue);

      await h.setRate(Currency.usd, 50);
      await settle();
      expect(emissions.last.isIncomplete, isFalse);
      expect(emissions.last.totalSavedMinorUnits, 5000);

      await h.contribute(usd.id, 100, currency: Currency.usd);
      await settle();
      expect(emissions.last.totalSavedMinorUnits, 10000);

      await subscription.cancel();
    },
  );
}
