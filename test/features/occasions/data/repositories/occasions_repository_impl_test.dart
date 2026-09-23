import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/data/datasources/occasions_dao.dart';
import 'package:daftary/features/occasions/data/repositories/occasions_repository_impl.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_detail.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_filter.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/people/data/datasources/people_dao.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/entities/people_failures.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:drift/native.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late OccasionsDao dao;
  late TransactionsRepositoryImpl transactionsRepository;
  late PeopleRepositoryImpl peopleRepository;
  late OccasionsRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = OccasionsDao(db);
    transactionsRepository = TransactionsRepositoryImpl(
      TransactionsDao(db),
      db,
    );
    peopleRepository = PeopleRepositoryImpl(
      PeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
    );
    repository = OccasionsRepositoryImpl(
      dao,
      transactionsRepository,
      peopleRepository,
      db,
    );
    await PeopleDao(
      db,
    ).insertPerson(id: 'p1', name: 'Ahmed', createdAt: DateTime(2026));
    await PeopleDao(
      db,
    ).insertPerson(id: 'p2', name: 'Mona', createdAt: DateTime(2026));
  });

  tearDown(() => db.close());

  T unwrap<T>(Either<Failure, T> either) =>
      either.getOrElse((failure) => throw StateError('$failure'));

  Future<Occasion> createOccasion({
    String key = 'occ-key',
    String name = 'Sara wedding',
    String type = OccasionType.wedding,
    DateTime? date,
  }) async {
    final result = await repository.createOccasion(
      idempotencyKey: key,
      name: name,
      date: date ?? DateTime(2026, 3, 10),
      type: type,
    );
    return unwrap<Occasion>(result);
  }

  group('createOccasion', () {
    test('trims the name and stores the date as date-only', () async {
      final occasion = await createOccasion(name: '  Sara wedding  ');

      expect(occasion.name, 'Sara wedding');
      expect(occasion.date, DateTime(2026, 3, 10));
      expect(occasion.isArchived, isFalse);
    });

    test('rejects a blank name or type (FR-001/FR-002)', () async {
      final blankName = await repository.createOccasion(
        idempotencyKey: 'k1',
        name: '   ',
        date: DateTime(2026, 3, 10),
        type: OccasionType.wedding,
      );
      final blankType = await repository.createOccasion(
        idempotencyKey: 'k2',
        name: 'Sara wedding',
        date: DateTime(2026, 3, 10),
        type: '  ',
      );

      expect(blankName.getLeft().toNullable(), isA<ValidationFailure>());
      expect(blankType.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('a retried call with the same idempotency key returns the existing '
        'occasion instead of creating a second one (FR-019)', () async {
      final first = await createOccasion(name: 'Sara wedding');
      final retried = await repository.createOccasion(
        idempotencyKey: 'occ-key',
        name: 'A different name',
        date: DateTime(2027, 1, 1),
        type: OccasionType.condolence,
      );

      final retriedOccasion = unwrap<Occasion>(retried);
      expect(retriedOccasion.id, first.id);
      expect(retriedOccasion.name, 'Sara wedding');

      final list = await repository.getOccasionsList();
      expect(unwrap<List<Occasion>>(list), hasLength(1));
    });
  });

  group('addParticipantContribution', () {
    test('creates one occasionContribution row carrying the occasion, person '
        'and direction (FR-005)', () async {
      final occasion = await createOccasion();

      final result = await repository.addParticipantContribution(
        idempotencyKey: 'c1',
        occasionId: occasion.id,
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 10),
      );

      final contribution = unwrap<MoneyTransaction>(result);
      expect(contribution.kind, TransactionKind.occasionContribution);
      expect(contribution.occasionId, occasion.id);
      expect(contribution.personId, 'p1');
      expect(contribution.direction, TransactionDirection.received);

      // The same row the person's own profile reads (FR-010).
      final history = await transactionsRepository.getPersonHistory('p1');
      expect(unwrap<List<MoneyTransaction>>(history), hasLength(1));
    });

    test('rejects a non-positive amount', () async {
      final occasion = await createOccasion();

      final result = await repository.addParticipantContribution(
        idempotencyKey: 'c1',
        occasionId: occasion.id,
        personId: 'p1',
        amount: const Money.fromMinorUnits(0),
        direction: TransactionDirection.given,
        date: DateTime(2026, 3, 10),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('rejects an unknown occasion', () async {
      final result = await repository.addParticipantContribution(
        idempotencyKey: 'c1',
        occasionId: 'does-not-exist',
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 3, 10),
      );

      expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
    });

    test('defaults countsTowardBalance to false under a condolence occasion, '
        'and true under any other type (FR-018)', () async {
      final condolence = await createOccasion(
        key: 'k-cond',
        name: 'Uncle condolence',
        type: OccasionType.condolence,
      );
      final wedding = await createOccasion(key: 'k-wed');

      final condolenceRow = unwrap<MoneyTransaction>(
        await repository.addParticipantContribution(
          idempotencyKey: 'c1',
          occasionId: condolence.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(50000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 10),
        ),
      );
      final weddingRow = unwrap<MoneyTransaction>(
        await repository.addParticipantContribution(
          idempotencyKey: 'c2',
          occasionId: wedding.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(50000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 10),
        ),
      );

      expect(condolenceRow.countsTowardBalance, isFalse);
      expect(weddingRow.countsTowardBalance, isTrue);
    });

    test('an explicit countsTowardBalance overrides the condolence default '
        '(FR-018)', () async {
      final condolence = await createOccasion(type: OccasionType.condolence);

      final row = unwrap<MoneyTransaction>(
        await repository.addParticipantContribution(
          idempotencyKey: 'c1',
          occasionId: condolence.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(50000),
          direction: TransactionDirection.received,
          countsTowardBalance: true,
          date: DateTime(2026, 3, 10),
        ),
      );

      expect(row.countsTowardBalance, isTrue);
    });
  });

  group('editOccasion', () {
    test('changing the type to condolence leaves existing contributions\' '
        'countsTowardBalance untouched (research.md Decision 3)', () async {
      final occasion = await createOccasion();
      final row = unwrap<MoneyTransaction>(
        await repository.addParticipantContribution(
          idempotencyKey: 'c1',
          occasionId: occasion.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(50000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 10),
        ),
      );

      await repository.editOccasion(
        occasionId: occasion.id,
        name: 'Renamed',
        date: DateTime(2026, 4, 1),
        type: OccasionType.condolence,
      );

      final detail = unwrap<OccasionDetail>(
        await repository.getOccasionDetail(occasion.id),
      );
      expect(detail.occasion.name, 'Renamed');
      expect(detail.occasion.type, OccasionType.condolence);
      expect(detail.participants.single.transactionId, row.id);
      expect(detail.participants.single.countsTowardBalance, isTrue);
    });

    test('reports an unknown occasion as not found', () async {
      final result = await repository.editOccasion(
        occasionId: 'nope',
        name: 'Renamed',
        date: DateTime(2026, 4, 1),
        type: OccasionType.wedding,
      );

      expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
    });
  });

  group('getOccasionDetail', () {
    test(
      'totals given and received separately and counts distinct participants '
      '(FR-007/FR-008/FR-020)',
      () async {
        final occasion = await createOccasion();
        await repository.addParticipantContribution(
          idempotencyKey: 'c1',
          occasionId: occasion.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(50000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 10),
        );
        // The same person may contribute twice (a gift plus a top-up).
        await repository.addParticipantContribution(
          idempotencyKey: 'c2',
          occasionId: occasion.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(10000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 11),
        );
        await repository.addParticipantContribution(
          idempotencyKey: 'c3',
          occasionId: occasion.id,
          personId: 'p2',
          amount: const Money.fromMinorUnits(20000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 3, 12),
        );

        final detail = unwrap<OccasionDetail>(
          await repository.getOccasionDetail(occasion.id),
        );

        expect(detail.summary.totalReceived.minorUnits, 60000);
        expect(detail.summary.totalGiven.minorUnits, 20000);
        expect(detail.summary.net.minorUnits, 40000);
        expect(detail.summary.settlementStatus, SettlementStatus.moreReceived);
        expect(detail.summary.participantCount, 2);
        expect(detail.participants, hasLength(3));
        expect(
          detail.participants.map((row) => row.personName),
          containsAll(<String>['Ahmed', 'Mona']),
        );
      },
    );

    test(
      'settles at zero when given and received cancel out (FR-008)',
      () async {
        final occasion = await createOccasion();
        await repository.addParticipantContribution(
          idempotencyKey: 'c1',
          occasionId: occasion.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(30000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 10),
        );
        await repository.addParticipantContribution(
          idempotencyKey: 'c2',
          occasionId: occasion.id,
          personId: 'p2',
          amount: const Money.fromMinorUnits(30000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 3, 10),
        );

        final detail = unwrap<OccasionDetail>(
          await repository.getOccasionDetail(occasion.id),
        );

        expect(detail.summary.settlementStatus, SettlementStatus.settled);
      },
    );

    test('each row carries the person\'s whole-history status, not an '
        'occasion-scoped one (FR-009)', () async {
      final occasion = await createOccasion();
      // Received inside the occasion: on its own this would read as
      // "you owe them".
      await repository.addParticipantContribution(
        idempotencyKey: 'c1',
        occasionId: occasion.id,
        personId: 'p1',
        amount: const Money.fromMinorUnits(10000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 10),
      );
      // A much larger loan outside it flips the person's real status.
      await transactionsRepository.addTransaction(
        idempotencyKey: 't1',
        personId: 'p1',
        amount: const Money.fromMinorUnits(90000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 1, 1),
      );

      final detail = unwrap<OccasionDetail>(
        await repository.getOccasionDetail(occasion.id),
      );

      expect(
        detail.participants.single.personOverallStatus,
        RelationshipStatus.theyOweYou,
      );
    });

    test('reports an unknown occasion as not found', () async {
      final result = await repository.getOccasionDetail('nope');

      expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
    });
  });

  group('removeParticipantContribution', () {
    test('surfaces an already-removed row as a participant failure', () async {
      final result = await repository.removeParticipantContribution('nope');

      expect(result.getLeft().toNullable(), isA<ParticipantNotFoundFailure>());
    });
  });

  group('deleteOccasion', () {
    test('soft-deletes every linked contribution and the occasion itself '
        '(FR-013)', () async {
      final occasion = await createOccasion();
      await repository.addParticipantContribution(
        idempotencyKey: 'c1',
        occasionId: occasion.id,
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 10),
      );
      await repository.addParticipantContribution(
        idempotencyKey: 'c2',
        occasionId: occasion.id,
        personId: 'p2',
        amount: const Money.fromMinorUnits(20000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 3, 10),
      );

      final result = await repository.deleteOccasion(occasion.id);
      expect(result.isRight(), isTrue);

      final remaining = await transactionsRepository
          .getContributionsForOccasion(occasion.id);
      expect(unwrap<List<MoneyTransaction>>(remaining), isEmpty);
      expect(
        unwrap<List<MoneyTransaction>>(
          await transactionsRepository.getPersonHistory('p1'),
        ),
        isEmpty,
      );

      final row = await dao.getById(occasion.id);
      expect(row?.deletedAt, isNotNull);
      expect(
        unwrap<List<Occasion>>(
          await repository.getOccasionsList(includeArchived: true),
        ),
        isEmpty,
      );
    });

    test('reports an already-deleted occasion as not found', () async {
      final occasion = await createOccasion();
      await repository.deleteOccasion(occasion.id);

      final again = await repository.deleteOccasion(occasion.id);

      expect(again.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
    });
  });

  group('archive / restore', () {
    test('an archived occasion leaves the default list but keeps its '
        'contributions counting (FR-014)', () async {
      final occasion = await createOccasion();
      await repository.addParticipantContribution(
        idempotencyKey: 'c1',
        occasionId: occasion.id,
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 3, 10),
      );

      await repository.archiveOccasion(occasion.id);

      expect(
        unwrap<List<Occasion>>(await repository.getOccasionsList()),
        isEmpty,
      );
      expect(
        unwrap<List<Occasion>>(
          await repository.getOccasionsList(includeArchived: true),
        ),
        hasLength(1),
      );
      final balance = await transactionsRepository.getPersonBalance('p1');
      expect(unwrap<PersonBalance>(balance).net.minorUnits, 50000);

      await repository.restoreOccasion(occasion.id);
      expect(
        unwrap<List<Occasion>>(await repository.getOccasionsList()),
        hasLength(1),
      );
    });
  });

  group('getOccasionsList', () {
    setUp(() async {
      await createOccasion(
        key: 'k1',
        name: 'Sara wedding',
        date: DateTime(2026, 1, 5),
      );
      await createOccasion(
        key: 'k2',
        name: 'Uncle condolence',
        type: OccasionType.condolence,
        date: DateTime(2026, 6, 20),
      );
      await createOccasion(
        key: 'k3',
        name: 'Omar سبوع',
        type: OccasionType.newbornSebou,
        date: DateTime(2026, 3, 15),
      );
    });

    test('is reverse-chronological by date (FR-015)', () async {
      final list = unwrap<List<Occasion>>(await repository.getOccasionsList());

      expect(list.map((occasion) => occasion.name), [
        'Uncle condolence',
        'Omar سبوع',
        'Sara wedding',
      ]);
    });

    test('filters by a case-insensitive name substring', () async {
      final list = unwrap<List<Occasion>>(
        await repository.getOccasionsList(
          filter: const OccasionFilter(nameQuery: 'WEDD'),
        ),
      );

      expect(list.single.name, 'Sara wedding');
    });

    test('filters by exact type', () async {
      final list = unwrap<List<Occasion>>(
        await repository.getOccasionsList(
          filter: const OccasionFilter(type: OccasionType.condolence),
        ),
      );

      expect(list.single.name, 'Uncle condolence');
    });

    test('filters by an inclusive date range', () async {
      final list = unwrap<List<Occasion>>(
        await repository.getOccasionsList(
          filter: OccasionFilter(
            fromDate: DateTime(2026, 1, 5),
            toDate: DateTime(2026, 3, 15),
          ),
        ),
      );

      expect(list.map((occasion) => occasion.name), [
        'Omar سبوع',
        'Sara wedding',
      ]);
    });

    test('excludes archived occasions unless asked for them', () async {
      final wedding = unwrap<List<Occasion>>(
        await repository.getOccasionsList(
          filter: const OccasionFilter(nameQuery: 'Sara'),
        ),
      ).single;
      await repository.archiveOccasion(wedding.id);

      expect(
        unwrap<List<Occasion>>(await repository.getOccasionsList()),
        hasLength(2),
      );
      expect(
        unwrap<List<Occasion>>(
          await repository.getOccasionsList(includeArchived: true),
        ),
        hasLength(3),
      );
    });
  });

  group('attachments', () {
    test('adds, lists and soft-deletes an attachment (FR-017)', () async {
      final occasion = await createOccasion();

      final added = unwrap<OccasionAttachment>(
        await repository.addOccasionAttachment(
          occasionId: occasion.id,
          filePath: '/app/documents/occasions/photo.jpg',
        ),
      );

      var detail = unwrap<OccasionDetail>(
        await repository.getOccasionDetail(occasion.id),
      );
      expect(detail.attachments, hasLength(1));
      expect(
        detail.attachments.single.filePath,
        '/app/documents/occasions/photo.jpg',
      );

      final removed = await repository.removeOccasionAttachment(added.id);
      expect(removed.isRight(), isTrue);

      detail = unwrap<OccasionDetail>(
        await repository.getOccasionDetail(occasion.id),
      );
      expect(detail.attachments, isEmpty);
    });

    test('reports an unknown attachment as not found', () async {
      final result = await repository.removeOccasionAttachment('nope');

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('person deletion with occasion contributions (T061)', () {
    test(
      'a person whose only history is an occasion contribution is still '
      'protected from deletion — those rows are ordinary transactions',
      () async {
        final occasion = await createOccasion();
        await repository.addParticipantContribution(
          idempotencyKey: 'c1',
          occasionId: occasion.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(50000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 10),
        );

        final result = await peopleRepository.deletePerson('p1');

        expect(
          result.getLeft().toNullable(),
          isA<PersonHasTransactionsFailure>(),
        );
        expect((await peopleRepository.getPersonById('p1')).isRight(), isTrue);
      },
    );

    test('the protection survives the contribution being soft-deleted, so the '
        'audit trail stays attributable', () async {
      final occasion = await createOccasion();
      final row = unwrap<MoneyTransaction>(
        await repository.addParticipantContribution(
          idempotencyKey: 'c1',
          occasionId: occasion.id,
          personId: 'p1',
          amount: const Money.fromMinorUnits(50000),
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 10),
        ),
      );
      await repository.removeParticipantContribution(row.id);

      final result = await peopleRepository.deletePerson('p1');

      expect(
        result.getLeft().toNullable(),
        isA<PersonHasTransactionsFailure>(),
      );
    });

    test('archiving that person instead always succeeds (FR-017)', () async {
      final occasion = await createOccasion();
      await repository.addParticipantContribution(
        idempotencyKey: 'c1',
        occasionId: occasion.id,
        personId: 'p1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 10),
      );

      final result = await peopleRepository.archivePerson('p1');

      expect(result.isRight(), isTrue);
    });
  });
}
