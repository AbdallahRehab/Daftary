import 'package:daftary/core/database/app_database.dart'
    hide isNull, isNotNull, ExchangeRate;
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';

import '../../helpers/currency_test_doubles.dart';
import '../../../../helpers/test_daos.dart';

void main() {
  late AppDatabase db;
  late TransactionsRepositoryImpl repository;
  late String personId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TransactionsRepositoryImpl(testTransactionsDao(db), db);
    final person = await testPeopleDao(
      db,
    ).insertPerson(id: 'p1', name: 'Ahmed', createdAt: DateTime(2026));
    personId = person.id;
  });

  tearDown(() => db.close());

  group('addTransaction', () {
    test('records a transaction against a person', () async {
      final result = await repository.addTransaction(
        idempotencyKey: 'key-1',
        personId: personId,
        amount: const Money.egp(200000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 1, 1),
      );

      expect(result.isRight(), isTrue);
    });

    test(
      'a retried call with the same idempotency_key is a no-op that returns the existing row (FR-020/SC-006)',
      () async {
        final first = await repository.addTransaction(
          idempotencyKey: 'key-1',
          personId: personId,
          amount: const Money.egp(200000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 1, 1),
        );
        final retried = await repository.addTransaction(
          idempotencyKey: 'key-1',
          personId: personId,
          amount: const Money.egp(999999),
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 2),
        );

        final firstTx = first.getOrElse((_) => throw StateError('x'));
        final retriedTx = retried.getOrElse((_) => throw StateError('x'));
        expect(retriedTx.id, firstTx.id);
        expect(retriedTx.amount, firstTx.amount);

        final history = await repository.getPersonHistory(personId);
        expect(history.getOrElse((_) => []), hasLength(1));
      },
    );

    test('rejects a zero amount (FR-005)', () async {
      final result = await repository.addTransaction(
        idempotencyKey: 'key-1',
        personId: personId,
        amount: const Money.egp(0),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('getPersonBalance', () {
    test('net = given - received over non-deleted rows (FR-008)', () async {
      await repository.addTransaction(
        idempotencyKey: 'k1',
        personId: personId,
        amount: const Money.egp(200000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );
      await repository.addTransaction(
        idempotencyKey: 'k2',
        personId: personId,
        amount: const Money.egp(50000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 1, 2),
      );

      final result = await repository.getPersonBalance(personId);

      final balance = result.getOrElse((_) => throw StateError('x'));
      expect(balance.net, const Money.egp(150000));
    });

    test('a deleted transaction is excluded from the balance', () async {
      final added = await repository.addTransaction(
        idempotencyKey: 'k1',
        personId: personId,
        amount: const Money.egp(200000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );
      final txId = added.getOrElse((_) => throw StateError('x')).id;
      await repository.deleteTransaction(txId);

      final result = await repository.getPersonBalance(personId);

      expect(
        result.getOrElse((_) => throw StateError('x')).net,
        Money.zero(Currency.egp),
      );
    });
  });

  group('recordRepayment (User Story 3)', () {
    Future<void> giveOutstanding(int minorUnits) => repository
        .addTransaction(
          idempotencyKey: 'seed',
          personId: personId,
          amount: Money.egp(minorUnits),
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 1),
        )
        .then((_) {});

    test(
      'AC1: a partial repayment reduces the net by exactly the repaid amount (1,500 -> 1,000 after 500)',
      () async {
        await giveOutstanding(150000);

        final result = await repository.recordRepayment(
          idempotencyKey: 'r1',
          personId: personId,
          amount: const Money.egp(50000),
          date: DateTime(2026, 1, 2),
        );

        final repaymentTx = result.getOrElse((_) => throw StateError('x'));
        expect(repaymentTx.kind, TransactionKind.repayment);
        expect(repaymentTx.direction, TransactionDirection.received);

        final balance = await repository.getPersonBalance(personId);
        expect(
          balance.getOrElse((_) => throw StateError('x')).net,
          const Money.egp(100000),
        );
      },
    );

    test(
      'AC2: a repayment equal to the outstanding amount settles it (1,500 -> 0)',
      () async {
        await giveOutstanding(150000);

        await repository.recordRepayment(
          idempotencyKey: 'r1',
          personId: personId,
          amount: const Money.egp(150000),
          date: DateTime(2026, 1, 2),
        );

        final balance = await repository.getPersonBalance(personId);
        expect(
          balance.getOrElse((_) => throw StateError('x')).net,
          Money.zero(Currency.egp),
        );
      },
    );

    test(
      'AC3: an overshoot repayment flips the sign (owed 500 + repayment 700 -> user owes 200)',
      () async {
        await giveOutstanding(50000);

        final result = await repository.recordRepayment(
          idempotencyKey: 'r1',
          personId: personId,
          amount: const Money.egp(70000),
          date: DateTime(2026, 1, 2),
        );

        final repaymentTx = result.getOrElse((_) => throw StateError('x'));
        expect(repaymentTx.direction, TransactionDirection.received);

        final balance = await repository.getPersonBalance(personId);
        expect(
          balance.getOrElse((_) => throw StateError('x')).net,
          const Money.egp(-20000),
        );
      },
    );

    test(
      'once the balance has flipped negative, a further repayment is inferred as "given" (not "received")',
      () async {
        await giveOutstanding(50000);
        await repository.recordRepayment(
          idempotencyKey: 'r1',
          personId: personId,
          amount: const Money.egp(70000),
          date: DateTime(2026, 1, 2),
        );

        final result = await repository.recordRepayment(
          idempotencyKey: 'r2',
          personId: personId,
          amount: const Money.egp(10000),
          date: DateTime(2026, 1, 3),
        );

        expect(
          result.getOrElse((_) => throw StateError('x')).direction,
          TransactionDirection.given,
        );
      },
    );
  });

  group('getOverview (User Story 4)', () {
    test(
      'totals/groups active and archived people, and includes an archived '
      'person with a non-zero balance in the totals (FR-024, Clarifications)',
      () async {
        final dao = testPeopleDao(db);
        final sara = await dao.insertPerson(
          id: 'p2',
          name: 'Sara',
          createdAt: DateTime(2026),
        );
        final oldContact = await dao.insertPerson(
          id: 'p3',
          name: 'Old Contact',
          createdAt: DateTime(2026),
        );
        final settledPerson = await dao.insertPerson(
          id: 'p4',
          name: 'Settled Person',
          createdAt: DateTime(2026),
        );
        await dao.setArchived(oldContact.id, true, DateTime(2026));

        // Ahmed (personId): they owe the user 1,500.
        await repository.addTransaction(
          idempotencyKey: 'k1',
          personId: personId,
          amount: const Money.egp(150000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 1),
        );
        // Sara: the user owes her 200.
        await repository.addTransaction(
          idempotencyKey: 'k2',
          personId: sara.id,
          amount: const Money.egp(20000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 1, 1),
        );
        // Old Contact (archived): they owe the user 300 — must still count.
        await repository.addTransaction(
          idempotencyKey: 'k3',
          personId: oldContact.id,
          amount: const Money.egp(30000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 1),
        );
        // Settled Person: given == received.
        await repository.addTransaction(
          idempotencyKey: 'k4',
          personId: settledPerson.id,
          amount: const Money.egp(10000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 1),
        );
        await repository.addTransaction(
          idempotencyKey: 'k5',
          personId: settledPerson.id,
          amount: const Money.egp(10000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 1, 2),
        );

        final result = await repository.getOverview();

        final overview = result.getOrElse((_) => throw StateError('x'));
        expect(overview.totalOwedToUser, const Money.egp(150000 + 30000));
        expect(overview.totalUserOwes, const Money.egp(20000));
        expect(
          overview.peopleTheyOweYou.map((p) => p.personId),
          containsAll([personId, oldContact.id]),
        );
        expect(
          overview.peopleTheyOweYou
              .firstWhere((p) => p.personId == oldContact.id)
              .isArchived,
          isTrue,
        );
        expect(overview.peopleYouOweThem.map((p) => p.personId), [sara.id]);
        expect(overview.settledCount, 1);
      },
    );
  });

  group('concurrent edits (T111 — spec.md Edge Cases)', () {
    test('two overlapping editTransaction calls on the same row never produce '
        'a merged/ambiguous state — whichever write lands last in SQLite '
        'wins entirely, and its audit entry carries the later changedAt '
        '(research.md Decision 7)', () async {
      final added = await repository.addTransaction(
        idempotencyKey: 'seed',
        personId: personId,
        amount: const Money.egp(100000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
        note: 'original',
      );
      final txId = added.getOrElse((_) => throw StateError('x')).id;

      // Two in-flight edits, started together rather than awaited one
      // after another — whichever actually commits its UPDATE last is
      // "the more recent confirmed edit" and must win outright.
      final editA = repository.editTransaction(
        transactionId: txId,
        amount: const Money.egp(200000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 2),
        note: 'edit A',
      );
      final editB = repository.editTransaction(
        transactionId: txId,
        amount: const Money.egp(300000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 1, 3),
        note: 'edit B',
      );

      final results = await Future.wait([editA, editB]);
      expect(results.every((r) => r.isRight()), isTrue);

      final row = await (db.select(
        db.moneyTransactions,
      )..where((t) => t.id.equals(txId))).getSingle();

      final wonByA = row.note == 'edit A';
      final wonByB = row.note == 'edit B';
      // Exactly one edit's full payload persisted — never a hybrid (e.g.
      // edit A's amount paired with edit B's note).
      expect(wonByA ^ wonByB, isTrue);
      if (wonByA) {
        expect(row.amountMinorUnits, 200000);
        expect(row.direction, 'given');
      } else {
        expect(row.amountMinorUnits, 300000);
        expect(row.direction, 'received');
      }

      final editedEntries =
          await (db.select(db.transactionAuditEntries)
                ..where(
                  (a) =>
                      a.transactionId.equals(txId) &
                      a.changeType.equals('edited'),
                )
                ..orderBy([(a) => OrderingTerm(expression: a.changedAt)]))
              .get();

      // Both edits were applied and logged — neither was silently
      // dropped or merged into the other.
      expect(editedEntries, hasLength(2));

      // The persisted row's editedAt matches the LATER of the two audit
      // entries' changedAt: the more recent confirmed edit wins, and
      // that fact is itself traceable via the audit trail.
      expect(row.editedAt, editedEntries.last.changedAt);
    });
  });

  group('hasAnyTransaction (006-onboarding-screens FR-010a)', () {
    test('returns Right(false) with no transactions', () async {
      final result = await repository.hasAnyTransaction();
      expect(result.getOrElse((_) => true), isFalse);
    });

    test('returns Right(true) with an active transaction', () async {
      await repository.addTransaction(
        idempotencyKey: 'key-1',
        personId: personId,
        amount: const Money.egp(200000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 1, 1),
      );

      final result = await repository.hasAnyTransaction();

      expect(result.getOrElse((_) => false), isTrue);
    });

    test('returns Right(true) with only a soft-deleted transaction', () async {
      final added = await repository.addTransaction(
        idempotencyKey: 'key-1',
        personId: personId,
        amount: const Money.egp(200000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 1, 1),
      );
      final txId = added
          .getOrElse((_) => throw StateError('expected Right'))
          .id;
      await repository.deleteTransaction(txId);

      final result = await repository.hasAnyTransaction();

      expect(result.getOrElse((_) => false), isTrue);
    });
  });

  group('multi-currency (018 T022)', () {
    /// A repository whose conversion context is [primary] + [rates].
    TransactionsRepositoryImpl repositoryWith({
      Currency primary = Currency.egp,
      List<ExchangeRate> rates = const [],
    }) => TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: getConversionContextWith(
        primary: primary,
        rates: rates,
      ),
    );

    Future<void> add(
      TransactionsRepositoryImpl repo,
      String key,
      Money amount,
      TransactionDirection direction, {
      String? forPersonId,
    }) async {
      final result = await repo.addTransaction(
        idempotencyKey: key,
        personId: forPersonId ?? personId,
        amount: amount,
        direction: direction,
        date: DateTime(2026, 1, 1),
      );
      expect(result.isRight(), isTrue);
    }

    test('currency_code round-trips through add → history', () async {
      await add(
        repository,
        'k1',
        const Money.fromMinorUnits(1050, Currency.usd),
        TransactionDirection.given,
      );

      final row = await db.select(db.moneyTransactions).getSingle();
      expect(row.currencyCode, 'USD');
      final history = (await repository.getPersonHistory(
        personId,
      )).getOrElse((_) => throw StateError('x'));
      expect(
        history.single.amount,
        const Money.fromMinorUnits(1050, Currency.usd),
      );
    });

    test('a row inserted without a currency defaults to EGP', () async {
      // The pre-018 insert shape: no currency_code supplied at all.
      await db
          .into(db.moneyTransactions)
          .insert(
            MoneyTransactionsCompanion.insert(
              id: 'legacy',
              idempotencyKey: 'legacy-key',
              personId: personId,
              amountMinorUnits: 12345,
              direction: 'given',
              kind: 'initialExchange',
              date: DateTime(2026).millisecondsSinceEpoch,
              createdAt: DateTime(2026).millisecondsSinceEpoch,
            ),
          );

      final row = await db.select(db.moneyTransactions).getSingle();
      expect(row.currencyCode, 'EGP');
      final history = (await repository.getPersonHistory(
        personId,
      )).getOrElse((_) => throw StateError('x'));
      expect(history.single.amount, const Money.egp(12345));
    });

    test('editing can change the currency, and the edit persists it', () async {
      await add(
        repository,
        'k1',
        const Money.egp(1000),
        TransactionDirection.given,
      );
      final txId = (await db.select(db.moneyTransactions).getSingle()).id;

      await repository.editTransaction(
        transactionId: txId,
        amount: const Money.fromMinorUnits(700, Currency.eur),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );

      final row = await db.select(db.moneyTransactions).getSingle();
      expect(row.currencyCode, 'EUR');
      expect(row.amountMinorUnits, 700);
    });

    test('a person with 2+ currencies, all convertible, sums correctly into '
        'the primary currency', () async {
      final repo = repositoryWith(
        rates: [rate(Currency.usd, Currency.egp, 50)],
      );
      await add(repo, 'k1', const Money.egp(10000), TransactionDirection.given);
      await add(
        repo,
        'k2',
        const Money.fromMinorUnits(1000, Currency.usd),
        TransactionDirection.given,
      );
      await add(
        repo,
        'k3',
        const Money.fromMinorUnits(200, Currency.usd),
        TransactionDirection.received,
      );

      final balance = (await repo.getPersonBalance(
        personId,
      )).getOrElse((_) => throw StateError('x'));

      // 100.00 EGP + (10.00 - 2.00) USD × 50 = 500.00 EGP.
      expect(balance.isBlocked, isFalse);
      expect(balance.net, const Money.egp(50000));
      expect(balance.status, RelationshipStatus.theyOweYou);
    });

    test('converts into a non-EGP primary currency', () async {
      final repo = repositoryWith(
        primary: Currency.usd,
        rates: [rate(Currency.egp, Currency.usd, 0.02)],
      );
      await add(
        repo,
        'k1',
        const Money.egp(50000),
        TransactionDirection.received,
      );
      await add(
        repo,
        'k2',
        const Money.fromMinorUnits(300, Currency.usd),
        TransactionDirection.given,
      );

      final balance = (await repo.getPersonBalance(
        personId,
      )).getOrElse((_) => throw StateError('x'));

      // -500.00 EGP × 0.02 + 3.00 USD = -7.00 USD.
      expect(balance.net, const Money.fromMinorUnits(-700, Currency.usd));
      expect(balance.status, RelationshipStatus.youOweThem);
    });

    test('a missing rate blocks the balance and names the currency — never a '
        '1:1 fallback (FR-009)', () async {
      final repo = repositoryWith();
      await add(repo, 'k1', const Money.egp(10000), TransactionDirection.given);
      await add(
        repo,
        'k2',
        const Money.fromMinorUnits(500, Currency.eur),
        TransactionDirection.given,
      );

      final balance = (await repo.getPersonBalance(
        personId,
      )).getOrElse((_) => throw StateError('x'));

      expect(balance.isBlocked, isTrue);
      expect(balance.net, isNull);
      expect(balance.missingRatesFor, [Currency.eur]);
      expect(
        balance.nativeNets,
        containsAll(const [
          Money.egp(10000),
          Money.fromMinorUnits(500, Currency.eur),
        ]),
      );
      // Every currency points the same way, so the status is still known.
      expect(balance.status, RelationshipStatus.theyOweYou);
    });

    test('a blocked balance whose currencies point in opposite directions has '
        'an unknown (null) status', () async {
      final repo = repositoryWith();
      await add(repo, 'k1', const Money.egp(10000), TransactionDirection.given);
      await add(
        repo,
        'k2',
        const Money.fromMinorUnits(500, Currency.gbp),
        TransactionDirection.received,
      );

      final balance = (await repo.getPersonBalance(
        personId,
      )).getOrElse((_) => throw StateError('x'));

      expect(balance.missingRatesFor, [Currency.gbp]);
      expect(balance.status, isNull);
    });

    test(
      'a currency the person is settled in never blocks the total',
      () async {
        final repo = repositoryWith();
        await add(
          repo,
          'k1',
          const Money.egp(10000),
          TransactionDirection.given,
        );
        await add(
          repo,
          'k2',
          const Money.fromMinorUnits(500, Currency.usd),
          TransactionDirection.given,
        );
        await add(
          repo,
          'k3',
          const Money.fromMinorUnits(500, Currency.usd),
          TransactionDirection.received,
        );

        final balance = (await repo.getPersonBalance(
          personId,
        )).getOrElse((_) => throw StateError('x'));

        expect(balance.net, const Money.egp(10000));
      },
    );

    test('an EGP-only history is unaffected by the conversion step', () async {
      final repo = repositoryWith(
        rates: [rate(Currency.usd, Currency.egp, 50)],
      );
      await add(
        repo,
        'k1',
        const Money.egp(200000),
        TransactionDirection.given,
      );
      await add(
        repo,
        'k2',
        const Money.egp(50000),
        TransactionDirection.received,
      );

      final balance = (await repo.getPersonBalance(
        personId,
      )).getOrElse((_) => throw StateError('x'));

      expect(
        balance,
        const PersonBalance(personId: 'p1', net: Money.egp(150000)),
      );
    });

    group('getOverview', () {
      Future<void> addPerson(String id, String name) => testPeopleDao(
        db,
      ).insertPerson(id: id, name: name, createdAt: DateTime(2026));

      test('converts every person into primary-currency totals', () async {
        await addPerson('p2', 'Sara');
        final repo = repositoryWith(
          rates: [rate(Currency.usd, Currency.egp, 50)],
        );
        await add(
          repo,
          'k1',
          const Money.fromMinorUnits(1000, Currency.usd),
          TransactionDirection.given,
        );
        await add(
          repo,
          'k2',
          const Money.egp(3000),
          TransactionDirection.received,
          forPersonId: 'p2',
        );

        final summary = (await repo.getOverview()).getOrElse(
          (_) => throw StateError('x'),
        );

        expect(summary.isBlocked, isFalse);
        expect(summary.totalOwedToUser, const Money.egp(50000));
        expect(summary.totalUserOwes, const Money.egp(3000));
        expect(summary.peopleTheyOweYou.single.net, const Money.egp(50000));
      });

      test('a missing rate blocks only the affected total and names the '
          'currency', () async {
        await addPerson('p2', 'Sara');
        final repo = repositoryWith();
        await add(
          repo,
          'k1',
          const Money.fromMinorUnits(1000, Currency.sar),
          TransactionDirection.given,
        );
        await add(
          repo,
          'k2',
          const Money.egp(3000),
          TransactionDirection.received,
          forPersonId: 'p2',
        );

        final summary = (await repo.getOverview()).getOrElse(
          (_) => throw StateError('x'),
        );

        expect(summary.missingRatesFor, [Currency.sar]);
        expect(summary.totalOwedToUser, isNull);
        expect(summary.totalUserOwes, const Money.egp(3000));
        final ahmed = summary.peopleTheyOweYou.single;
        expect(ahmed.isBlocked, isTrue);
        expect(ahmed.nativeNets, const [
          Money.fromMinorUnits(1000, Currency.sar),
        ]);
      });

      test('an opposite-direction blocked person is listed as rate-needed and '
          'blocks both totals', () async {
        final repo = repositoryWith();
        await add(
          repo,
          'k1',
          const Money.egp(1000),
          TransactionDirection.given,
        );
        await add(
          repo,
          'k2',
          const Money.fromMinorUnits(1000, Currency.aed),
          TransactionDirection.received,
        );

        final summary = (await repo.getOverview()).getOrElse(
          (_) => throw StateError('x'),
        );

        expect(summary.peopleRateNeeded.single.personId, personId);
        expect(summary.peopleTheyOweYou, isEmpty);
        expect(summary.peopleYouOweThem, isEmpty);
        expect(summary.totalOwedToUser, isNull);
        expect(summary.totalUserOwes, isNull);
        expect(summary.isAllSettled, isFalse);
      });
    });

    test('recordRepayment infers direction from the converted balance and '
        'stores its own currency', () async {
      final repo = repositoryWith(
        rates: [rate(Currency.usd, Currency.egp, 50)],
      );
      // They owe 10.00 EGP but you owe 1.00 USD (= 50.00 EGP): net you
      // owe them, so a repayment is money you give.
      await add(repo, 'k1', const Money.egp(1000), TransactionDirection.given);
      await add(
        repo,
        'k2',
        const Money.fromMinorUnits(100, Currency.usd),
        TransactionDirection.received,
      );

      final result = await repo.recordRepayment(
        idempotencyKey: 'r1',
        personId: personId,
        amount: const Money.fromMinorUnits(80, Currency.usd),
        date: DateTime(2026, 1, 2),
      );

      final repayment = result.getOrElse((_) => throw StateError('x'));
      expect(repayment.direction, TransactionDirection.given);
      expect(repayment.amount, const Money.fromMinorUnits(80, Currency.usd));
    });
  });

  group('getPersonBalances (batched People-list read)', () {
    test('matches getPersonBalance for every person: converted, blocked, '
        'deleted rows, and no transactions at all', () async {
      final repo = TransactionsRepositoryImpl(
        testTransactionsDao(db),
        db,
        getConversionContext: getConversionContextWith(
          rates: [rate(Currency.usd, Currency.egp, 50)],
        ),
      );
      final peopleDao = testPeopleDao(db);
      for (final id in ['p2', 'p3']) {
        await peopleDao.insertPerson(
          id: id,
          name: 'Person $id',
          createdAt: DateTime(2026),
        );
      }
      Future<void> add(String key, String who, Money amount) async {
        final result = await repo.addTransaction(
          idempotencyKey: key,
          personId: who,
          amount: amount,
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 1),
        );
        expect(result.isRight(), isTrue);
      }

      // p1: EGP + convertible USD, plus a deleted row that must not count.
      await add('k1', personId, const Money.egp(10000));
      await add('k2', personId, const Money.fromMinorUnits(1000, Currency.usd));
      await add('k3', personId, const Money.egp(99999));
      final deleted = (await db.select(db.moneyTransactions).get()).firstWhere(
        (row) => row.idempotencyKey == 'k3',
      );
      await repo.deleteTransaction(deleted.id);
      // p2: SAR has no rate, so the balance is blocked.
      await add('k4', 'p2', const Money.fromMinorUnits(500, Currency.sar));
      // p3: no transactions.

      final ids = [personId, 'p2', 'p3'];
      final batched = (await repo.getPersonBalances(
        ids,
      )).getOrElse((_) => throw StateError('x'));

      expect(batched.keys, ids);
      for (final id in ids) {
        final single = (await repo.getPersonBalance(
          id,
        )).getOrElse((_) => throw StateError('x'));
        expect(batched[id], single, reason: id);
      }
      expect(batched[personId]!.net, const Money.egp(60000));
      expect(batched['p2']!.isBlocked, isTrue);
      expect(batched['p3']!.status, RelationshipStatus.settled);
    });
  });
}
