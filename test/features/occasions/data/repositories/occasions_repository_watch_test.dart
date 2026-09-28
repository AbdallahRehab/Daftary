import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/occasions/data/repositories/occasions_repository_impl.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/stream_recorder.dart';
import '../../../../helpers/test_daos.dart';

/// 021 FR-031: the occasions list and an occasion's detail are live — a
/// write made anywhere (or a rate change, for the converted totals) shows
/// up with no reload.
void main() {
  late AppDatabase db;
  late CurrencyRepositoryImpl currency;
  late TransactionsRepositoryImpl transactions;
  late PeopleRepositoryImpl people;
  late OccasionsRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    final context = GetConversionContext(currency);
    transactions = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: context,
    );
    people = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
      getConversionContext: context,
    );
    repository = OccasionsRepositoryImpl(
      testOccasionsDao(db),
      transactions,
      people,
      db,
      context,
      const CurrencyConverterImpl(),
    );
    await testPeopleDao(
      db,
    ).insertPerson(id: 'p1', name: 'Ahmed', createdAt: DateTime(2026));
  });

  tearDown(() => db.close());

  Future<Occasion> createOccasion(String key, String name) async =>
      (await repository.createOccasion(
        idempotencyKey: key,
        name: name,
        date: DateTime(2026, 3, 10),
        type: OccasionType.wedding,
      )).getOrElse((failure) => throw StateError('$failure'));

  Future<void> contribute(String occasionId, Money amount, String key) async {
    final result = await repository.addParticipantContribution(
      idempotencyKey: key,
      occasionId: occasionId,
      personId: 'p1',
      amount: amount,
      direction: TransactionDirection.received,
      date: DateTime(2026, 3, 10),
    );
    expect(result.isRight(), isTrue);
  }

  group('watchOccasionsList', () {
    test('a created occasion appears, and an archived one leaves the '
        'default list for the archived one', () async {
      final active = StreamRecorder(repository.watchOccasionsList());
      final withArchived = StreamRecorder(
        repository.watchOccasionsList(includeArchived: true),
      );
      addTearDown(active.cancel);
      addTearDown(withArchived.cancel);
      await active.waitFor((r) => rightOf(r).isEmpty);

      final occasion = await createOccasion('k1', 'Sara wedding');
      await active.waitFor(
        (r) => rightOf(r).map((o) => o.id).toList().contains(occasion.id),
      );

      await repository.archiveOccasion(occasion.id);
      await active.waitForNext((r) => rightOf(r).isEmpty);
      await withArchived.waitFor(
        (r) => rightOf(r).any((o) => o.id == occasion.id && o.isArchived),
      );
    });
  });

  group('watchOccasionDetail', () {
    test('a contribution added elsewhere recalculates the totals', () async {
      final occasion = await createOccasion('k1', 'Sara wedding');
      final detail = StreamRecorder(
        repository.watchOccasionDetail(occasion.id),
      );
      addTearDown(detail.cancel);
      await detail.waitFor((r) => rightOf(r).participants.isEmpty);

      await contribute(occasion.id, const Money.egp(50000), 't1');

      final updated = rightOf(
        await detail.waitFor((r) => rightOf(r).participants.isNotEmpty),
      );
      expect(updated.summary.totalReceived, const Money.egp(50000));
      expect(updated.participants.single.personName, 'Ahmed');
    });

    test('renaming a participant relabels the row', () async {
      final occasion = await createOccasion('k1', 'Sara wedding');
      await contribute(occasion.id, const Money.egp(50000), 't1');
      final detail = StreamRecorder(
        repository.watchOccasionDetail(occasion.id),
      );
      addTearDown(detail.cancel);
      await detail.waitFor(
        (r) => rightOf(r).participants.single.personName == 'Ahmed',
      );

      await people.editPerson(personId: 'p1', name: 'Ahmed Ali');

      await detail.waitFor(
        (r) => rightOf(r).participants.single.personName == 'Ahmed Ali',
      );
    });

    test('changing a rate re-converts the totals (018)', () async {
      await currency.setExchangeRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rate: 50,
      );
      final occasion = await createOccasion('k1', 'Sara wedding');
      await contribute(
        occasion.id,
        const Money.fromMinorUnits(100, Currency.usd),
        't1',
      );
      final detail = StreamRecorder(
        repository.watchOccasionDetail(occasion.id),
      );
      addTearDown(detail.cancel);
      await detail.waitFor(
        (r) => rightOf(r).summary.totalReceived == const Money.egp(5000),
      );

      await currency.setExchangeRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rate: 60,
      );

      await detail.waitFor(
        (r) => rightOf(r).summary.totalReceived == const Money.egp(6000),
      );
    });

    test('an attached photo appears, and a deleted occasion reads as not '
        'found', () async {
      final occasion = await createOccasion('k1', 'Sara wedding');
      final detail = StreamRecorder(
        repository.watchOccasionDetail(occasion.id),
      );
      addTearDown(detail.cancel);
      await detail.waitFor((r) => rightOf(r).attachments.isEmpty);

      await repository.addOccasionAttachment(
        occasionId: occasion.id,
        filePath: '/docs/a1.jpg',
      );
      await detail.waitFor((r) => rightOf(r).attachments.length == 1);

      await repository.deleteOccasion(occasion.id);
      await detail.waitFor(
        (r) => r.getLeft().toNullable() is OccasionNotFoundFailure,
      );
    });
  });
}
