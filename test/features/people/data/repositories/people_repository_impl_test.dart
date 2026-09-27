import 'package:daftary/core/database/app_database.dart' hide ExchangeRate;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/entities/people_failures.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../transactions/helpers/currency_test_doubles.dart';
import '../../../../helpers/test_daos.dart';

void main() {
  late AppDatabase db;
  late PeopleRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
    );
  });

  tearDown(() => db.close());

  group('createPerson', () {
    test('creates a person with just a name', () async {
      final result = await repository.createPerson(name: 'Ahmed');

      expect(result.isRight(), isTrue);
      final person = result.getOrElse(
        (_) => throw StateError('expected Right'),
      );
      expect(person.name, 'Ahmed');
      expect(person.isArchived, isFalse);
    });

    test('rejects an empty-after-trim name', () async {
      final result = await repository.createPerson(name: '   ');
      expect(
        result,
        const Left<Failure, Person>(ValidationFailure('Name is required')),
      );
    });

    test(
      'returns PossibleDuplicateFailure instead of inserting on a near-duplicate name',
      () async {
        await repository.createPerson(name: 'Ahmed Ali');

        final result = await repository.createPerson(name: 'Ahmed');

        expect(result.isLeft(), isTrue);
        result.match((failure) {
          expect(failure, isA<PossibleDuplicateFailure>());
          expect(
            (failure as PossibleDuplicateFailure).matches.first.name,
            'Ahmed Ali',
          );
        }, (_) => fail('expected a PossibleDuplicateFailure'));

        final all = await repository.searchActivePeople();
        expect(all.getOrElse((_) => []), hasLength(1));
      },
    );
  });

  group('confirmCreateDespiteDuplicate', () {
    test('bypasses the duplicate check and inserts anyway', () async {
      await repository.createPerson(name: 'Ahmed Ali');

      final result = await repository.confirmCreateDespiteDuplicate(
        name: 'Ahmed',
      );

      expect(result.isRight(), isTrue);
      final all = await repository.searchActivePeople();
      expect(all.getOrElse((_) => []), hasLength(2));
    });
  });

  group('searchActivePeople', () {
    test('excludes archived people', () async {
      final created = await repository.createPerson(name: 'Ahmed');
      final personId = created.getOrElse((_) => throw StateError('x')).id;
      await repository.archivePerson(personId);

      final result = await repository.searchActivePeople();

      expect(result.getOrElse((_) => []), isEmpty);
    });

    test('filters by a name query', () async {
      await repository.createPerson(name: 'Ahmed');
      await repository.confirmCreateDespiteDuplicate(name: 'Sara');

      final result = await repository.searchActivePeople(nameQuery: 'ahm');

      final names = result.getOrElse((_) => []).map((p) => p.name);
      expect(names, ['Ahmed']);
    });
  });

  group('getPersonById', () {
    test('returns NotFoundFailure for an unknown id', () async {
      final result = await repository.getPersonById('missing');
      expect(
        result,
        const Left<Failure, Person>(NotFoundFailure('Person not found')),
      );
    });
  });

  group('hasAnyPerson (006-onboarding-screens FR-010a)', () {
    test('returns Right(false) with no people', () async {
      final result = await repository.hasAnyPerson();
      expect(result, const Right<Object, bool>(false));
    });

    test('returns Right(true) with an active person', () async {
      await repository.createPerson(name: 'Ahmed');
      final result = await repository.hasAnyPerson();
      expect(result, const Right<Object, bool>(true));
    });

    test('returns Right(true) with only an archived person', () async {
      final created = await repository.createPerson(name: 'Ahmed');
      final personId = created
          .getOrElse((_) => throw StateError('expected Right'))
          .id;
      await repository.archivePerson(personId);

      final result = await repository.hasAnyPerson();

      expect(result, const Right<Object, bool>(true));
    });
  });

  group('searchActivePeople status filter (018 multi-currency)', () {
    PeopleRepositoryImpl repositoryWith({
      List<ExchangeRate> rates = const [],
    }) => PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
      getConversionContext: getConversionContextWith(rates: rates),
    );

    Future<void> seed(
      String id,
      String name,
      List<(Money, bool)> entries,
    ) async {
      await testPeopleDao(
        db,
      ).insertPerson(id: id, name: name, createdAt: DateTime(2026));
      final transactions = TransactionsRepositoryImpl(
        testTransactionsDao(db),
        db,
      );
      var i = 0;
      for (final (amount, given) in entries) {
        await transactions.addTransaction(
          idempotencyKey: '$id-${i++}',
          personId: id,
          amount: amount,
          direction: given
              ? TransactionDirection.given
              : TransactionDirection.received,
          date: DateTime(2026),
        );
      }
    }

    Future<List<String>> idsFor(
      PeopleRepositoryImpl repo,
      RelationshipStatus status,
    ) async => (await repo.searchActivePeople(
      statusFilter: status,
    )).getOrElse((_) => throw StateError('x')).map((p) => p.id).toList();

    setUp(() async {
      // Owes you 10 EGP but you owe them 1 USD.
      await seed('mixed', 'Mixed', [
        (const Money.egp(1000), true),
        (const Money.fromMinorUnits(100, Currency.usd), false),
      ]);
      // Only USD lent out.
      await seed('usd', 'Usd', [
        (const Money.fromMinorUnits(100, Currency.usd), true),
      ]);
    });

    test('uses the converted balance when every rate is known', () async {
      final repo = repositoryWith(
        rates: [rate(Currency.usd, Currency.egp, 50)],
      );

      expect(await idsFor(repo, RelationshipStatus.youOweThem), ['mixed']);
      expect(await idsFor(repo, RelationshipStatus.theyOweYou), ['usd']);
    });

    test(
      'a blocked balance keeps a same-direction status, and an '
      'opposite-direction one matches no status filter without failing',
      () async {
        final repo = repositoryWith();

        expect(await idsFor(repo, RelationshipStatus.theyOweYou), ['usd']);
        expect(await idsFor(repo, RelationshipStatus.youOweThem), isEmpty);
        expect(await idsFor(repo, RelationshipStatus.settled), isEmpty);
        final all = (await repo.searchActivePeople()).getOrElse(
          (_) => throw StateError('x'),
        );
        expect(all.map((p) => p.id), containsAll(['mixed', 'usd']));
      },
    );
  });
}
