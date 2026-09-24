import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// T107 (Phase 9 performance validation, SC-005): seeds 500 people /
/// 10,000 transactions directly via batch inserts (bypassing the DAO/
/// repository write path purely to make seeding itself fast — the read
/// path under test, [TransactionsRepositoryImpl.getOverview], is exercised
/// exactly as production code calls it) and confirms `getOverview` both
/// renders correct totals and completes in under 2 seconds.
void main() {
  test('getOverview totals are correct and complete in under 2s for 500 '
      'people / 10,000 transactions (SC-005)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = TransactionsRepositoryImpl(TransactionsDao(db), db);

    const peopleCount = 500;
    const transactionsPerPerson = 20; // 500 * 20 = 10,000 total.
    final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;

    // Deterministic 3-way split so the expected overview totals can be
    // hand-computed exactly, rather than eyeballing a random seed:
    //   i % 3 == 0 -> they owe the user 5,000 minor units (positive net)
    //   i % 3 == 1 -> the user owes them 5,000 minor units (negative net)
    //   i % 3 == 2 -> settled (net exactly zero)
    final peopleCompanions = <PeopleCompanion>[];
    final transactionCompanions = <MoneyTransactionsCompanion>[];
    var expectedTotalOwedToUser = 0;
    var expectedTotalUserOwes = 0;
    var expectedSettledCount = 0;

    for (var i = 0; i < peopleCount; i++) {
      final personId = 'perf-person-$i';
      peopleCompanions.add(
        PeopleCompanion.insert(
          id: personId,
          name: 'Person $i',
          normalizedName: 'person $i',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final int givenAmount;
      final int receivedAmount;
      switch (i % 3) {
        case 0:
          givenAmount = 1000;
          receivedAmount = 500;
          expectedTotalOwedToUser += 5000;
        case 1:
          givenAmount = 500;
          receivedAmount = 1000;
          expectedTotalUserOwes += 5000;
        default:
          givenAmount = 750;
          receivedAmount = 750;
          expectedSettledCount += 1;
      }

      for (var t = 0; t < transactionsPerPerson ~/ 2; t++) {
        transactionCompanions.add(
          MoneyTransactionsCompanion.insert(
            id: 'perf-tx-$i-given-$t',
            idempotencyKey: 'perf-key-$i-given-$t',
            personId: personId,
            amountMinorUnits: givenAmount,
            direction: 'given',
            kind: 'initialExchange',
            date: now,
            createdAt: now,
          ),
        );
        transactionCompanions.add(
          MoneyTransactionsCompanion.insert(
            id: 'perf-tx-$i-received-$t',
            idempotencyKey: 'perf-key-$i-received-$t',
            personId: personId,
            amountMinorUnits: receivedAmount,
            direction: 'received',
            kind: 'initialExchange',
            date: now,
            createdAt: now,
          ),
        );
      }
    }

    expect(transactionCompanions, hasLength(10000));

    await db.batch((batch) => batch.insertAll(db.people, peopleCompanions));
    await db.batch(
      (batch) => batch.insertAll(db.moneyTransactions, transactionCompanions),
    );

    final stopwatch = Stopwatch()..start();
    final result = await repository.getOverview();
    stopwatch.stop();

    final overview = result.getOrElse(
      (_) => throw StateError('expected Right'),
    );
    expect(overview.totalOwedToUser, Money.egp(expectedTotalOwedToUser));
    expect(overview.totalUserOwes, Money.egp(expectedTotalUserOwes));
    expect(overview.settledCount, expectedSettledCount);
    expect(
      overview.peopleTheyOweYou,
      hasLength(expectedTotalOwedToUser ~/ 5000),
    );
    expect(overview.peopleYouOweThem, hasLength(expectedTotalUserOwes ~/ 5000));

    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 2)),
      reason:
          'getOverview took ${stopwatch.elapsedMilliseconds}ms for '
          '$peopleCount people / ${transactionCompanions.length} '
          'transactions — SC-005 requires under 2s',
    );
  });
}
