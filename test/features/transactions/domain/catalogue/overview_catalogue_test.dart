import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/catalogue_fixtures.dart';

/// 022 Phase 2 (T005) — overview catalogue. The two totals are never netted
/// together, never partial, and archived people are included. Every figure
/// is an exact integer count of minor units.
void main() {
  late CatalogueEnv env;

  setUp(() async => env = await CatalogueEnv.open());
  tearDown(() => env.close());

  Future<OverviewSummary> overview() async =>
      unwrapOrThrow(await env.transactions.getOverview());

  group('CHK004 archived person stays in the overview', () {
    test('Ahmed owes 1,500.00; archived, the total still includes 150000 and '
        'his row is marked archived', () async {
      await env.give('ahmed', 150000);
      await env.person('ahmed', archived: true);

      final summary = await overview();

      expect(summary.totalOwedToUser, const Money.egp(150000));
      expect(summary.totalUserOwes, const Money.egp(0));
      final row = summary.peopleTheyOweYou.single;
      expect(row.personId, 'ahmed');
      expect(row.isArchived, isTrue);
      expect(row.net, const Money.egp(150000));
    });
  });

  group('CHK018 totals are never netted together', () {
    test('owed 150000 + owe 70000 + one settled => 150000 / 70000 / 1, never '
        '80000', () async {
      await env.give('ahmed', 150000);
      await env.receive('mona', 70000);
      await env.give('karim', 5000);
      await env.receive('karim', 5000);

      final summary = await overview();

      expect(summary.totalOwedToUser, const Money.egp(150000));
      expect(summary.totalUserOwes, const Money.egp(70000));
      expect(summary.settledCount, 1);
      expect(summary.peopleTheyOweYou.map((p) => p.personId), ['ahmed']);
      expect(summary.peopleYouOweThem.map((p) => p.personId), ['mona']);
      expect(summary.peopleRateNeeded, isEmpty);
    });
  });

  group('CHK019 USD with no rate is blocked, never 1:1, never dropped', () {
    test('Sara gave 100.00 USD: her balance names USD and the "they owe '
        'you" total is blocked (null)', () async {
      await env.give('sara', 10000, currency: Currency.usd);

      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('sara'),
      );
      expect(balance.isBlocked, isTrue);
      expect(balance.net, isNull);
      expect(balance.missingRatesFor, [Currency.usd]);
      expect(balance.nativeNets, [
        const Money.fromMinorUnits(10000, Currency.usd),
      ]);

      final summary = await overview();
      expect(summary.totalOwedToUser, isNull);
      // Sara can only be owed money, so "you owe them" stays a known total.
      expect(summary.totalUserOwes, const Money.egp(0));
      expect(summary.peopleTheyOweYou.single.personId, 'sara');
      expect(summary.missingRatesFor, [Currency.usd]);
    });
  });

  group('CHK021 opposite directions with a missing rate', () {
    test('gave 100.00 USD, received 1,000.00 EGP, no rate: Sara is in '
        '"rate needed" only and both totals are blocked', () async {
      await env.give('sara', 10000, currency: Currency.usd);
      await env.receive('sara', 100000);

      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('sara'),
      );
      expect(balance.status, isNull);

      final summary = await overview();
      expect(summary.peopleRateNeeded.map((p) => p.personId), ['sara']);
      expect(summary.peopleTheyOweYou, isEmpty);
      expect(summary.peopleYouOweThem, isEmpty);
      expect(summary.totalOwedToUser, isNull);
      expect(summary.totalUserOwes, isNull);
    });
  });

  group('CHK082 listed people add up exactly to the totals', () {
    test('both lists, archived included, sum to the two totals', () async {
      await env.setRate(Currency.usd, 48.5);
      await env.give('ahmed', 150000);
      await env.give('laila', 33333);
      await env.person('laila', archived: true);
      await env.give('sara', 10000, currency: Currency.usd); // +485000
      await env.receive('mona', 70000);
      await env.receive('nour', 1);
      await env.person('nour', archived: true);

      final summary = await overview();

      final owedSum = summary.peopleTheyOweYou.fold<int>(
        0,
        (sum, p) => sum + p.net!.minorUnits,
      );
      final owesSum = summary.peopleYouOweThem.fold<int>(
        0,
        (sum, p) => sum + -p.net!.minorUnits,
      );
      expect(owedSum, 150000 + 33333 + 485000);
      expect(summary.totalOwedToUser, Money.egp(owedSum));
      expect(owesSum, 70000 + 1);
      expect(summary.totalUserOwes, Money.egp(owesSum));
      expect(
        summary.peopleTheyOweYou
            .where((p) => p.isArchived)
            .map((p) => p.personId),
        ['laila'],
      );
      expect(
        summary.peopleYouOweThem
            .where((p) => p.isArchived)
            .map((p) => p.personId),
        ['nour'],
      );
    });
  });
}
