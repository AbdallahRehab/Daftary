import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/data/datasources/people_dao.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionsRepositoryImpl repository;
  late String personId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TransactionsRepositoryImpl(TransactionsDao(db), db);
    final person = await PeopleDao(
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
        amount: const Money.fromMinorUnits(200000),
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
          amount: const Money.fromMinorUnits(200000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 1, 1),
        );
        final retried = await repository.addTransaction(
          idempotencyKey: 'key-1',
          personId: personId,
          amount: const Money.fromMinorUnits(999999),
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
        amount: const Money.fromMinorUnits(0),
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
        amount: const Money.fromMinorUnits(200000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );
      await repository.addTransaction(
        idempotencyKey: 'k2',
        personId: personId,
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 1, 2),
      );

      final result = await repository.getPersonBalance(personId);

      final balance = result.getOrElse((_) => throw StateError('x'));
      expect(balance.net, const Money.fromMinorUnits(150000));
    });

    test('a deleted transaction is excluded from the balance', () async {
      final added = await repository.addTransaction(
        idempotencyKey: 'k1',
        personId: personId,
        amount: const Money.fromMinorUnits(200000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );
      final txId = added.getOrElse((_) => throw StateError('x')).id;
      await repository.deleteTransaction(txId);

      final result = await repository.getPersonBalance(personId);

      expect(result.getOrElse((_) => throw StateError('x')).net, Money.zero());
    });
  });

  group('recordRepayment (User Story 3)', () {
    Future<void> giveOutstanding(int minorUnits) => repository
        .addTransaction(
          idempotencyKey: 'seed',
          personId: personId,
          amount: Money.fromMinorUnits(minorUnits),
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
          amount: const Money.fromMinorUnits(50000),
          date: DateTime(2026, 1, 2),
        );

        final repaymentTx = result.getOrElse((_) => throw StateError('x'));
        expect(repaymentTx.kind, TransactionKind.repayment);
        expect(repaymentTx.direction, TransactionDirection.received);

        final balance = await repository.getPersonBalance(personId);
        expect(
          balance.getOrElse((_) => throw StateError('x')).net,
          const Money.fromMinorUnits(100000),
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
          amount: const Money.fromMinorUnits(150000),
          date: DateTime(2026, 1, 2),
        );

        final balance = await repository.getPersonBalance(personId);
        expect(
          balance.getOrElse((_) => throw StateError('x')).net,
          Money.zero(),
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
          amount: const Money.fromMinorUnits(70000),
          date: DateTime(2026, 1, 2),
        );

        final repaymentTx = result.getOrElse((_) => throw StateError('x'));
        expect(repaymentTx.direction, TransactionDirection.received);

        final balance = await repository.getPersonBalance(personId);
        expect(
          balance.getOrElse((_) => throw StateError('x')).net,
          const Money.fromMinorUnits(-20000),
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
          amount: const Money.fromMinorUnits(70000),
          date: DateTime(2026, 1, 2),
        );

        final result = await repository.recordRepayment(
          idempotencyKey: 'r2',
          personId: personId,
          amount: const Money.fromMinorUnits(10000),
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
        final dao = PeopleDao(db);
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
          amount: const Money.fromMinorUnits(150000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 1),
        );
        // Sara: the user owes her 200.
        await repository.addTransaction(
          idempotencyKey: 'k2',
          personId: sara.id,
          amount: const Money.fromMinorUnits(20000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 1, 1),
        );
        // Old Contact (archived): they owe the user 300 — must still count.
        await repository.addTransaction(
          idempotencyKey: 'k3',
          personId: oldContact.id,
          amount: const Money.fromMinorUnits(30000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 1),
        );
        // Settled Person: given == received.
        await repository.addTransaction(
          idempotencyKey: 'k4',
          personId: settledPerson.id,
          amount: const Money.fromMinorUnits(10000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 1, 1),
        );
        await repository.addTransaction(
          idempotencyKey: 'k5',
          personId: settledPerson.id,
          amount: const Money.fromMinorUnits(10000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 1, 2),
        );

        final result = await repository.getOverview();

        final overview = result.getOrElse((_) => throw StateError('x'));
        expect(
          overview.totalOwedToUser,
          const Money.fromMinorUnits(150000 + 30000),
        );
        expect(overview.totalUserOwes, const Money.fromMinorUnits(20000));
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
        amount: const Money.fromMinorUnits(100000),
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
        amount: const Money.fromMinorUnits(200000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 2),
        note: 'edit A',
      );
      final editB = repository.editTransaction(
        transactionId: txId,
        amount: const Money.fromMinorUnits(300000),
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
        amount: const Money.fromMinorUnits(200000),
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
        amount: const Money.fromMinorUnits(200000),
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
}
