import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_duplicate_dao.dart';
import 'package:daftary/features/sms_import/data/models/pending_import_mapper.dart';
import 'package:daftary/features/sms_import/data/models/tombstone_mapper.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_tombstone.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';

/// T060 — the batched lookups over both aggregates, against a real
/// in-memory database. Every value is synthetic.
void main() {
  late db.AppDatabase database;
  late SmsDuplicateDao dao;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    dao = SmsDuplicateDao(database);
    await database
        .into(database.people)
        .insert(
          db.PeopleCompanion.insert(
            id: 'person-1',
            name: 'Example Person',
            normalizedName: 'example person',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
  });
  tearDown(() => database.close());

  int day(int d) => DateTime(2026, 3, d).millisecondsSinceEpoch;

  Future<void> transaction(
    String id, {
    String direction = 'given',
    int amount = 12550,
    int date = 4,
    bool deleted = false,
    String? importSource,
  }) => database
      .into(database.moneyTransactions)
      .insert(
        db.MoneyTransactionsCompanion.insert(
          id: id,
          idempotencyKey: 'key-$id',
          personId: 'person-1',
          amountMinorUnits: amount,
          direction: direction,
          kind: 'initialExchange',
          date: day(date),
          createdAt: 0,
          deletedAt: db.Value(deleted ? 1 : null),
          importSource: db.Value(importSource),
        ),
      );

  Future<void> entry(
    String id, {
    String type = 'expense',
    int amount = 12550,
    int date = 4,
    String currency = 'EGP',
    String? note,
  }) => database
      .into(database.financeEntries)
      .insert(
        db.FinanceEntriesCompanion.insert(
          id: id,
          idempotencyKey: 'key-$id',
          categoryId: type == 'expense' ? 'seed_other' : 'seed_other_income',
          type: type,
          amountMinorUnits: amount,
          currencyCode: db.Value(currency),
          date: day(date),
          createdAt: 0,
          note: db.Value(note),
        ),
      );

  Future<void> pending(PendingSmsImport item) => database
      .into(database.pendingSmsImports)
      .insert(pendingImportToCompanion(item));

  test('findSavedMatches: both tables, direction group, ±1 day', () async {
    await transaction('t-given');
    await transaction('t-received', direction: 'received');
    await transaction('t-deleted', deleted: true);
    await transaction('t-far', date: 6);
    await transaction('t-edge', date: 3);
    await entry('e-expense', date: 5, note: 'cafe');
    await entry('e-income', type: 'income');
    await entry('e-other-amount', amount: 999);
    await entry('e-usd', currency: 'USD');

    final refs = (await dao.findSavedMatches(
      amount: const Money.egp(12550),
      date: DateTime(2026, 3, 4),
      type: SuggestedRecordType.expense,
    )).getOrElse((f) => fail('$f'));
    expect(
      refs.map((r) => r.id),
      unorderedEquals(['t-given', 't-edge', 'e-expense']),
    );
    final cafe = refs.singleWhere((r) => r.id == 'e-expense');
    expect(cafe.recordType, SavedRecordType.financeEntry);
    expect(cafe.note, 'cafe');
    expect(cafe.date, DateTime(2026, 3, 5));

    final incoming = (await dao.findSavedMatches(
      amount: const Money.egp(12550),
      date: DateTime(2026, 3, 4),
      type: SuggestedRecordType.received,
    )).getOrElse((f) => fail('$f'));
    expect(
      incoming.map((r) => r.id),
      unorderedEquals(['t-received', 'e-income']),
    );
  });

  test('loadWindow reads both tables in one window', () async {
    await transaction('t1', date: 2);
    await entry('e1', date: 9);
    await entry('e2', date: 12);
    final window = (await dao.loadWindow(
      DateTime(2026, 3, 3),
      DateTime(2026, 3, 10),
    )).getOrElse((f) => fail('$f'));
    expect(window.records.map((r) => r.id), unorderedEquals(['t1', 'e1']));
    expect(window.withAmount(const Money.egp(12550)), hasLength(2));
  });

  test(
    'findPendingPair: same card, merchant, amount within 10 minutes',
    () async {
      final item = buildPendingImport(timeMinutes: 600);
      await pending(item);
      await pending(
        buildPendingImport(id: 'p-near', fingerprint: 'f2', timeMinutes: 609),
      );
      await pending(
        buildPendingImport(id: 'p-far', fingerprint: 'f3', timeMinutes: 611),
      );
      await pending(
        buildPendingImport(
          id: 'p-ref',
          fingerprint: 'f4',
          timeMinutes: 601,
          refHash: 'r1',
        ),
      );
      final pair = (await dao.findPendingPair(
        item,
      )).getOrElse((f) => fail('$f'));
      expect(pair?.id, 'p-near');

      final withRef = buildPendingImport(
        id: 'x',
        fingerprint: 'fx',
        refHash: 'r',
      );
      expect(
        (await dao.findPendingPair(withRef)).getOrElse((_) => null),
        isNull,
      );
    },
  );

  test('findKeyMatches excludes the item itself', () async {
    final item = buildPendingImport(refAmountHash: 'ra1');
    await pending(item);
    await pending(
      buildPendingImport(id: 'p2', fingerprint: 'f2', refAmountHash: 'ra1'),
    );
    final created = DateTime(2026, 3, 4);
    await database
        .into(database.smsImportTombstones)
        .insert(
          tombstoneToCompanion(
            SmsImportTombstone(
              fingerprint: 'fp-1',
              outcome: TombstoneOutcome.ignored,
              bankId: 'nbe',
              createdAt: created,
              purgeAfter: SmsImportTombstone.minimumPurgeAfter(created),
            ),
          ),
        );
    final matches = (await dao.findKeyMatches(
      excludeId: item.id,
      fingerprint: item.fingerprint,
      refAmountHash: 'ra1',
    )).getOrElse((f) => fail('$f'));
    expect(matches.where((m) => m.pendingId == item.id), isEmpty);
    expect(matches.map((m) => m.pendingId), contains('p2'));
    expect(matches.where((m) => m.isTombstone), hasLength(1));
  });

  test('saved-record lookups through the added tombstone', () async {
    await entry('e1', note: 'example');
    final created = DateTime(2026, 3, 4);
    await database
        .into(database.smsImportTombstones)
        .insert(
          tombstoneToCompanion(
            SmsImportTombstone(
              fingerprint: 'fp-added',
              outcome: TombstoneOutcome.added,
              bankId: 'cib',
              refHash: 'r1',
              savedRecordId: 'e1',
              savedRecordType: SavedRecordType.financeEntry,
              createdAt: created,
              purgeAfter: SmsImportTombstone.minimumPurgeAfter(created),
            ),
          ),
        );
    expect(
      (await dao.savedRecordsForRefHash(
        'r1',
      )).getOrElse((_) => []).map((r) => r.id),
      ['e1'],
    );
    expect(
      (await dao.refHashForSavedRecord('e1')).getOrElse((_) => null),
      'r1',
    );
    expect((await dao.bankForSavedRecord('e1')).getOrElse((_) => null), 'cib');
    expect(
      (await dao.bankForSavedRecord('none')).getOrElse((_) => 'x'),
      isNull,
    );
  });

  test('findPendingWithAmount: other pending rows only', () async {
    final item = buildPendingImport();
    await pending(item);
    await pending(buildPendingImport(id: 'p2', fingerprint: 'f2'));
    await pending(
      buildPendingImport(
        id: 'p3',
        fingerprint: 'f3',
        amount: const Money.egp(1),
      ),
    );
    final found = (await dao.findPendingWithAmount(
      const Money.egp(12550),
      excludeId: item.id,
    )).getOrElse((f) => fail('$f'));
    expect(found.map((p) => p.id), ['p2']);
  });
}
