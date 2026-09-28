import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/data/repositories/occasions_repository_impl.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasion_detail.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasions_list.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_daos.dart';
import '../transactions/helpers/currency_test_doubles.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';

/// T085 — the ceilings from plan.md: 200 participant contributions in one
/// occasion, and ~2,000 occasions in the list.
///
/// This asserts the query shape, not the device. The budgets are
/// deliberately loose (well above the stated 1s target) because CI machines
/// are noisy: what this actually catches is a regression from a SQL
/// aggregate to client-side summing, or from one batched balance lookup per
/// person to one per row — either turns these milliseconds into seconds and
/// fails by an order of magnitude rather than by a hair.
void main() {
  late AppDatabase db;
  late OccasionsRepositoryImpl repository;

  const participantCount = 200;
  const occasionCount = 2000;
  const occasionId = 'occasion_under_test';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = OccasionsRepositoryImpl(
      testOccasionsDao(db),
      TransactionsRepositoryImpl(testTransactionsDao(db), db),
      PeopleRepositoryImpl(
        testPeopleDao(db),
        const FindPossibleDuplicatePerson(),
        db,
      ),
      db,
      getConversionContextWith(),
      const CurrencyConverterImpl(),
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    // Batch inserts rather than repository calls: the subject here is read
    // performance, and seeding through the write path would dominate the
    // test's own runtime without measuring anything.
    await db.batch((batch) {
      batch.insert(
        db.occasions,
        OccasionsCompanion.insert(
          id: occasionId,
          idempotencyKey: 'key_$occasionId',
          name: "Ahmed's Wedding",
          date: now,
          type: OccasionType.wedding,
          createdAt: now,
          updatedAt: now,
        ),
      );
      for (var i = 0; i < participantCount; i++) {
        batch.insert(
          db.people,
          PeopleCompanion.insert(
            id: 'person_$i',
            name: 'Person $i',
            normalizedName: 'person $i',
            createdAt: now,
            updatedAt: now,
          ),
        );
        batch.insert(
          db.moneyTransactions,
          MoneyTransactionsCompanion.insert(
            id: 'contribution_$i',
            idempotencyKey: 'key_contribution_$i',
            personId: 'person_$i',
            amountMinorUnits: 10000 + i,
            // A realistic mix, so the aggregate has both branches to sum.
            direction: i.isEven ? 'received' : 'given',
            kind: TransactionKind.occasionContribution.name,
            occasionId: const Value(occasionId),
            date: now,
            createdAt: now,
          ),
        );
      }
    });
  });

  tearDown(() => db.close());

  test('GetOccasionDetail over $participantCount contributions stays well '
      'inside budget', () async {
    final stopwatch = Stopwatch()..start();
    final result = await GetOccasionDetail(repository)(occasionId);
    stopwatch.stop();

    final detail = result.getOrElse((f) => fail('expected a detail: $f'));
    expect(detail.participants, hasLength(participantCount));
    expect(detail.summary.participantCount, participantCount);
    expect(
      detail.summary.totalReceived.minorUnits +
          detail.summary.totalGiven.minorUnits,
      greaterThan(0),
    );
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(3000),
      reason:
          'a per-row balance lookup instead of one per distinct person '
          'would blow through this by an order of magnitude',
    );
  });

  test('the totals are an exact integer aggregate, not a float sum', () async {
    final detail = (await GetOccasionDetail(repository)(
      occasionId,
    )).getOrElse((f) => fail('$f'));

    var expectedReceived = 0;
    var expectedGiven = 0;
    for (var i = 0; i < participantCount; i++) {
      if (i.isEven) {
        expectedReceived += 10000 + i;
      } else {
        expectedGiven += 10000 + i;
      }
    }

    expect(detail.summary.totalReceived, Money.egp(expectedReceived));
    expect(detail.summary.totalGiven, Money.egp(expectedGiven));
    expect(detail.summary.net, Money.egp(expectedReceived - expectedGiven));
  });

  test('the occasions list over $occasionCount occasions stays well inside '
      'budget', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.batch((batch) {
      for (var i = 0; i < occasionCount; i++) {
        batch.insert(
          db.occasions,
          OccasionsCompanion.insert(
            id: 'bulk_$i',
            idempotencyKey: 'key_bulk_$i',
            name: 'Occasion $i',
            date: now - i * Duration.millisecondsPerDay,
            type: OccasionType.standardValues[i % 7],
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });

    final stopwatch = Stopwatch()..start();
    final result = await GetOccasionsList(repository)();
    stopwatch.stop();

    final occasions = result.getOrElse((f) => fail('$f'));
    expect(occasions, hasLength(occasionCount + 1));
    // Reverse-chronological, and ordered by the index rather than in Dart.
    expect(
      occasions.first.date.isAfter(occasions.last.date) ||
          occasions.first.date.isAtSameMomentAs(occasions.last.date),
      isTrue,
    );
    expect(stopwatch.elapsedMilliseconds, lessThan(3000));
  });
}
