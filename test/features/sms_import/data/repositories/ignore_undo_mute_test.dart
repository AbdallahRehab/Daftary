import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/usecases/ignore_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/mute_sender.dart';
import 'package:daftary/features/sms_import/domain/usecases/undo_ignore.dart';
import 'package:daftary/features/sms_import/domain/usecases/unmute_sender.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_muted_senders.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_undo_list.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/test_daos.dart';
import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pipeline_harness.dart';

/// T130 — Ignore (single and batch), Undo and Mute against a real
/// in-memory database, the real AES-GCM vault and the real settings
/// repository (FR-064..FR-068, data-model §6, invariant 8), plus the T131
/// use cases over them. Every value is synthetic.
void main() {
  late db.AppDatabase database;
  late FixedClock clock;
  late SmsImportRepositoryImpl repository;
  late SmsImportSettingsRepositoryImpl settings;

  const body = 'Purchase EGP 125.50 at Example Cafe card 4111111111111111';

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    await database.select(database.financeCategories).get();
    clock = FixedClock(DateTime(2026, 3, 4, 12));
    repository = SmsImportRepositoryImpl(
      SmsImportDao(database),
      SmsImportSettingsDao(database),
      AesGcmRawTextVault(FakeSmsKeyStore()),
      const SmsMaskerImpl(),
      FakeBankReferencePolicy(),
      clock,
      TransactionsRepositoryImpl(testTransactionsDao(database), database),
      FinanceRepositoryImpl(testFinanceDao(database)),
    );
    settings = SmsImportSettingsRepositoryImpl(
      SmsImportSettingsDao(database),
      clock,
    );
  });
  tearDown(() => database.close());

  Future<void> stage(PendingSmsImport item) async {
    final result = await repository.insertPending(
      NewPendingImport(item: item, rawMasked: body),
    );
    expect(result.getOrElse((f) => fail('$f')), InsertOutcome.inserted);
  }

  Future<db.PendingSmsImportRow?> row(String id) => (database.select(
    database.pendingSmsImports,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<List<db.SmsImportTombstoneRow>> tombstones() =>
      database.select(database.smsImportTombstones).get();

  Future<int> savedRecords() async =>
      (await database.select(database.financeEntries).get()).length +
      (await database.select(database.moneyTransactions).get()).length;

  PendingSmsImport rich({
    String id = 'pending-1',
    String fingerprint = 'fp-1',
    String? senderId = 'BANKX',
  }) => buildPendingImport(
    id: id,
    fingerprint: fingerprint,
    senderId: senderId,
    counterparty: 'Example Person',
    refHash: 'ref-$id',
    refAmountHash: 'ra-$id',
    suggestedCategoryId: 'seed_food',
    suggestedPersonId: 'person-1',
    warnings: const {SmsWarning.possibleDuplicate},
    candidates: const [12550, 9900],
    foreignAmountText: 'USD 25.00',
  );

  group('ignore', () {
    test('writes an ignored tombstone, nulls the original and keeps only '
        'the six Undo fields', () async {
      await stage(rich());
      expect((await row('pending-1'))!.rawBlob, isNotNull);

      final result = await IgnoreImport(repository)(ids: {'pending-1'});
      expect(result, const Right<Failure, Unit>(unit));

      final r = (await row('pending-1'))!;
      expect(r.status, SmsImportStatus.ignored.dbValue);
      expect(r.decidedAt, clock.now().millisecondsSinceEpoch);
      expect(r.rawBlob, isNull);
      // The six Undo-list fields are kept (data-model §6).
      expect(r.amountMinorUnits, 12550);
      expect(r.currencyCode, 'EGP');
      expect(r.occurredOn, isNotNull);
      expect(r.merchant, 'Example Cafe');
      expect(r.counterparty, 'Example Person');
      expect(r.bankId, 'nbe');
      expect(r.kind, SmsKind.cardPurchase.dbValue);
      // Everything else is cleared.
      expect(r.cardLast4, isNull);
      expect(r.timeMinutes, isNull);
      expect(r.merchantKey, isNull);
      expect(r.senderId, isNull);
      expect(r.suggestedCategoryId, isNull);
      expect(r.suggestedPersonId, isNull);
      expect(r.suggestedAction, 'unset');
      expect(r.confidenceJson, '{}');
      expect(r.warningsJson, '{}');
      // The identity stays for duplicate protection.
      expect(r.fingerprint, 'fp-1');
      expect(r.refHash, 'ref-pending-1');
      expect(r.refAmountHash, 'ra-pending-1');

      final t = (await tombstones()).single;
      expect(t.fingerprint, 'fp-1');
      expect(t.outcome, TombstoneOutcome.ignored.dbValue);
      expect(t.bankId, 'nbe');
      expect(t.refHash, 'ref-pending-1');
      expect(t.refAmountHash, 'ra-pending-1');
      expect(t.savedRecordId, isNull);
      expect(
        t.purgeAfter - t.createdAt,
        greaterThanOrEqualTo(const Duration(days: 97).inMilliseconds),
      );

      final s = (await settings.getSettings()).getOrElse((f) => fail('$f'));
      expect(s.ignoredCount, 1);
      expect(await savedRecords(), 0);
    });

    test('an ignored message never resurfaces on re-ingest', () async {
      await stage(rich());
      await repository.ignore({'pending-1'});
      final again = await repository.insertPending(
        NewPendingImport(
          item: rich(id: 'pending-9', fingerprint: 'fp-1'),
          rawMasked: body,
        ),
      );
      expect(again.getOrElse((f) => fail('$f')), InsertOutcome.alreadyKnown);
      expect(await row('pending-9'), isNull);
    });

    test('batch: every item is ignored in one transaction', () async {
      await stage(rich());
      await stage(rich(id: 'pending-2', fingerprint: 'fp-2'));
      await stage(rich(id: 'pending-3', fingerprint: 'fp-3'));

      final result = await IgnoreImport(repository)(
        ids: {'pending-1', 'pending-2'},
      );
      expect(result.isRight(), isTrue);

      expect((await row('pending-1'))!.status, 'ignored');
      expect((await row('pending-2'))!.status, 'ignored');
      expect((await row('pending-3'))!.status, 'pending');
      expect((await row('pending-3'))!.rawBlob, isNotNull);
      expect((await tombstones()).map((t) => t.fingerprint).toSet(), {
        'fp-1',
        'fp-2',
      });
      final s = (await settings.getSettings()).getOrElse((f) => fail('$f'));
      expect(s.ignoredCount, 2);
    });

    test('batch is all or nothing: one decided item rolls every item '
        'back', () async {
      await stage(rich());
      await stage(rich(id: 'pending-2', fingerprint: 'fp-2'));
      await repository.closeAsDuplicate('pending-2');
      final before = await tombstones();

      final result = await repository.ignore({'pending-1', 'pending-2'});

      expect(
        result,
        const Left<Failure, Unit>(
          ImportAlreadyDecidedFailure(SmsImportStatus.duplicateClosed),
        ),
      );
      final first = (await row('pending-1'))!;
      expect(first.status, 'pending');
      expect(first.rawBlob, isNotNull);
      expect(first.merchantKey, 'example cafe');
      // The duplicate tombstone was not overwritten; no ignored one added.
      expect(
        (await tombstones()).map((t) => (t.fingerprint, t.outcome)).toSet(),
        before.map((t) => (t.fingerprint, t.outcome)).toSet(),
      );
      final s = (await settings.getSettings()).getOrElse((f) => fail('$f'));
      expect(s.ignoredCount, 0);
    });

    test('an added item is never ignored and its tombstone is kept', () async {
      await stage(rich());
      final saved = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: ConfirmedFinanceEntry(
          categoryId: 'seed_rent',
          type: FinanceEntryType.expense,
          amount: const Money.egp(12550),
          date: DateTime(2026, 3, 4),
        ),
      );
      expect(saved.isRight(), isTrue, reason: '$saved');

      final result = await repository.ignore({'pending-1'});

      expect(
        result,
        const Left<Failure, Unit>(
          ImportAlreadyDecidedFailure(SmsImportStatus.added),
        ),
      );
      expect((await row('pending-1'))!.status, 'added');
      expect((await tombstones()).single.outcome, 'added');
    });

    test('a missing id is content-free NotFound and writes nothing', () async {
      await stage(rich());
      final result = await repository.ignore({'pending-1', 'missing'});
      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, isNot(matches(RegExp('[0-9]'))));
      expect((await row('pending-1'))!.status, 'pending');
      expect(await tombstones(), isEmpty);
    });

    test('an empty set is a no-op', () async {
      expect(await repository.ignore({}), const Right<Failure, Unit>(unit));
    });
  });

  group('undo', () {
    test('deletes the row and its tombstone; the message can return on a '
        're-ingest', () async {
      await stage(rich());
      await repository.ignore({'pending-1'});

      final result = await UndoIgnore(repository)('pending-1');
      expect(
        result,
        const Right<Failure, UndoResult>(UndoResult(needsRescan: true)),
      );

      expect(await row('pending-1'), isNull);
      expect(await tombstones(), isEmpty);
      final again = await repository.insertPending(
        NewPendingImport(
          item: rich(id: 'pending-2', fingerprint: 'fp-1'),
          rawMasked: body,
        ),
      );
      expect(again.getOrElse((f) => fail('$f')), InsertOutcome.inserted);
    });

    test('works for an expired item', () async {
      await stage(rich());
      await repository.expireDue(DateTime(2026, 4, 10));
      expect((await row('pending-1'))!.status, 'expired');

      expect(
        await repository.undo('pending-1'),
        const Right<Failure, Unit>(unit),
      );
      expect(await row('pending-1'), isNull);
      expect(await tombstones(), isEmpty);
    });

    test('refuses a pending, added or duplicate-closed item and writes '
        'nothing', () async {
      await stage(rich());
      await stage(rich(id: 'pending-2', fingerprint: 'fp-2'));
      await repository.closeAsDuplicate('pending-2');

      expect(
        await repository.undo('pending-1'),
        const Left<Failure, Unit>(
          ImportAlreadyDecidedFailure(SmsImportStatus.pending),
        ),
      );
      expect(
        await repository.undo('pending-2'),
        const Left<Failure, Unit>(
          ImportAlreadyDecidedFailure(SmsImportStatus.duplicateClosed),
        ),
      );
      expect(await row('pending-1'), isNotNull);
      expect(await row('pending-2'), isNotNull);
      expect((await tombstones()).single.fingerprint, 'fp-2');
    });

    test('a missing id is content-free NotFound', () async {
      final failure = (await repository.undo(
        'missing',
      )).getLeft().toNullable()!;
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, isNot(matches(RegExp('[0-9]'))));
    });

    test('the Undo list shows ignored and expired items within 30 days, '
        'six fields only', () async {
      await stage(rich());
      await stage(rich(id: 'pending-2', fingerprint: 'fp-2'));
      await stage(rich(id: 'pending-3', fingerprint: 'fp-3'));
      await repository.ignore({'pending-1'});
      await repository.closeAsDuplicate('pending-2');

      final list = (await WatchUndoList(
        repository,
      )().first).getOrElse((f) => fail('$f'));
      expect(list.map((i) => i.id), ['pending-1']);
      final item = list.single;
      expect(item.amount, const Money.egp(12550));
      expect(item.merchant, 'Example Cafe');
      expect(item.hasRawText, isFalse);
      expect(item.senderId, isNull);
      expect(item.cardLast4, isNull);
      expect(item.amountCandidates, isEmpty);
      expect(item.foreignAmountText, isNull);
    });
  });

  group('mute', () {
    test('deletes that sender\'s pending rows in the same transaction, '
        'with no tombstones (invariant 8)', () async {
      await stage(rich(senderId: 'BANKX'));
      await stage(
        rich(id: 'pending-2', fingerprint: 'fp-2', senderId: 'BANKX'),
      );
      await stage(
        rich(id: 'pending-3', fingerprint: 'fp-3', senderId: 'OTHER'),
      );
      await stage(rich(id: 'pending-4', fingerprint: 'fp-4', senderId: null));

      final deleted = await MuteSender(settings)(' bankx ');
      expect(deleted, const Right<Failure, int>(2));

      expect(await row('pending-1'), isNull);
      expect(await row('pending-2'), isNull);
      expect(await row('pending-3'), isNotNull);
      expect(await row('pending-4'), isNotNull);
      expect(await tombstones(), isEmpty);
      final remaining = await database.select(database.pendingSmsImports).get();
      expect(remaining.where((r) => r.senderId == 'BANKX'), isEmpty);

      final muted = (await WatchMutedSenders(
        settings,
      )().first).getOrElse((f) => fail('$f'));
      expect(muted, {'BANKX'});
    });

    test('a decided item of that sender is not deleted (its tombstone keeps '
        'protecting against duplicates)', () async {
      await stage(rich());
      await repository.ignore({'pending-1'});
      // The ignored row no longer carries the sender (scrubbed).
      await MuteSender(settings)('BANKX');
      expect((await row('pending-1'))!.status, 'ignored');
      expect((await tombstones()).single.outcome, 'ignored');
    });

    test('a blank sender is refused and nothing is muted', () async {
      final result = await MuteSender(settings)('   ');
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()!.message, 'sms_sender_empty');
      expect(await database.select(database.smsSenderMutes).get(), isEmpty);
    });

    test('unmute removes the mute', () async {
      await MuteSender(settings)('BANKX');
      expect(
        await UnmuteSender(settings)('bankx'),
        const Right<Failure, Unit>(unit),
      );
      expect(await database.select(database.smsSenderMutes).get(), isEmpty);
    });

    test('muted senders are excluded from the inbox allow-list', () async {
      final harness = PipelineHarness();
      await harness.open();
      addTearDown(harness.close);
      await harness.settings.muteSender('NBE');

      const nbe =
          'NBE: Your card ending 4821 was charged EGP 120.00 at Example '
          'Market on 05/03/2026.';
      final muted = await harness.scan([inboxRow(1, nbe)]);
      expect(muted.createdPending, 0);
      expect(await harness.rows(), isEmpty);

      // Control: the same message is staged once the sender is unmuted.
      await harness.settings.unmuteSender('NBE');
      final unmuted = await harness.scan([inboxRow(1, nbe)]);
      expect(unmuted.createdPending, 1);
    });
  });
}
