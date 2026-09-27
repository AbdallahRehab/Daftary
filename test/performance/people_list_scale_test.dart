import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/archive_person.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
import 'package:daftary/features/people/domain/usecases/watch_active_people.dart';
import 'package:daftary/features/people/presentation/cubit/person_list_cubit.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_balances.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_daos.dart';

/// The People list is the home screen and reloads on every search
/// keystroke, filter change, and return from another screen, so its load
/// time at scale is user-facing. Seeds 500 people / 10,000 transactions
/// and times `PersonListCubit.load()` wired exactly like production
/// (conversion context included).
void main() {
  test('PersonListCubit.load() for 500 people / 10,000 transactions', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final getContext = GetConversionContext(
      CurrencyRepositoryImpl(testCurrencyDao(db), SystemAppClock()),
    );
    final transactions = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: getContext,
    );
    final people = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
      getConversionContext: getContext,
    );

    const peopleCount = 500;
    final now = DateTime(2026).millisecondsSinceEpoch;
    await db.batch((batch) {
      for (var i = 0; i < peopleCount; i++) {
        batch.insert(
          db.people,
          PeopleCompanion.insert(
            id: 'p$i',
            name: 'Person $i',
            normalizedName: 'person $i',
            createdAt: now,
            updatedAt: now,
          ),
        );
        for (var t = 0; t < 20; t++) {
          batch.insert(
            db.moneyTransactions,
            MoneyTransactionsCompanion.insert(
              id: 't$i-$t',
              idempotencyKey: 'k$i-$t',
              personId: 'p$i',
              amountMinorUnits: 1000 + i,
              direction: t.isEven ? 'given' : 'received',
              kind: 'initialExchange',
              date: now,
              createdAt: now,
            ),
          );
        }
      }
    });

    final cubit = PersonListCubit(
      WatchActivePeople(people),
      WatchPersonBalances(transactions),
      ArchivePerson(people),
      RestorePerson(people),
    );
    addTearDown(cubit.close);

    await cubit.subscribe(); // warm-up
    final stopwatch = Stopwatch()..start();
    const runs = 5;
    for (var r = 0; r < runs; r++) {
      await cubit.resubscribe();
    }
    stopwatch.stop();
    final perLoad = stopwatch.elapsedMilliseconds / runs;
    // ignore: avoid_print
    print('PersonListCubit.subscribe(): ${perLoad.toStringAsFixed(1)} ms/load');

    expect(cubit.state.items, hasLength(peopleCount));
    // Measured at ~341 ms/load before balances were batched (one query set
    // per person) and ~6 ms/load after; the budget catches a return to N+1
    // with room for slower CI machines.
    expect(
      perLoad,
      lessThan(100),
      reason:
          'PersonListCubit.load() took ${perLoad}ms for $peopleCount people',
    );
  });
}
