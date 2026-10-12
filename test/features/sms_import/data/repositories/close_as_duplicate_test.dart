import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/usecases/close_as_duplicate.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/test_daos.dart';
import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

/// T100 — `SmsImportRepositoryImpl.closeAsDuplicate` and the
/// `CloseAsDuplicate` use case against a real in-memory database and the
/// real AES-GCM vault (FR-061, data-model §6). Every value is synthetic.
void main() {
  late db.AppDatabase database;
  late FixedClock clock;
  late SmsImportRepositoryImpl repository;
  late FinanceRepository finance;
  late CloseAsDuplicate closeAsDuplicate;

  const body = 'Purchase EGP 125.50 at Example Cafe card 4111111111111111';

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    // Runs beforeOpen (the first-launch category seed).
    await database.select(database.financeCategories).get();
    clock = FixedClock(DateTime(2026, 3, 4, 12));
    finance = FinanceRepositoryImpl(testFinanceDao(database));
    repository = SmsImportRepositoryImpl(
      SmsImportDao(database),
      SmsImportSettingsDao(database),
      AesGcmRawTextVault(FakeSmsKeyStore()),
      const SmsMaskerImpl(),
      FakeBankReferencePolicy(),
      clock,
      TransactionsRepositoryImpl(testTransactionsDao(database), database),
      finance,
    );
    closeAsDuplicate = CloseAsDuplicate(repository);
  });
  tearDown(() => database.close());

  Future<void> stage(PendingSmsImport item) async {
    final result = await repository.insertPending(
      NewPendingImport(item: item, rawMasked: body),
    );
    expect(result.getOrElse((f) => fail('$f')), InsertOutcome.inserted);
  }

  Future<db.PendingSmsImportRow> row([String id = 'pending-1']) =>
      (database.select(
        database.pendingSmsImports,
      )..where((p) => p.id.equals(id))).getSingle();

  Future<List<db.SmsImportTombstoneRow>> tombstones() =>
      database.select(database.smsImportTombstones).get();

  test('writes a duplicate tombstone, nulls the original and scrubs the '
      'row to its identity shell', () async {
    await stage(
      buildPendingImport(
        refHash: 'ref-1',
        refAmountHash: 'ra-1',
        warnings: const {SmsWarning.possibleDuplicate},
        suggestedCategoryId: 'seed_groceries',
      ),
    );
    expect((await row()).rawBlob, isNotNull);

    final result = await closeAsDuplicate('pending-1');
    expect(result, const Right<Failure, Unit>(unit));

    final closed = await row();
    expect(closed.status, SmsImportStatus.duplicateClosed.dbValue);
    expect(closed.decidedAt, clock.now().millisecondsSinceEpoch);
    expect(closed.rawBlob, isNull);
    // Identity kept: id, fingerprint, bank, hashes, origin.
    expect(closed.fingerprint, 'fp-1');
    expect(closed.bankId, 'nbe');
    expect(closed.refHash, 'ref-1');
    expect(closed.refAmountHash, 'ra-1');
    // Content scrubbed.
    expect(closed.amountMinorUnits, isNull);
    expect(closed.currencyCode, isNull);
    expect(closed.occurredOn, isNull);
    expect(closed.timeMinutes, isNull);
    expect(closed.merchant, isNull);
    expect(closed.merchantKey, isNull);
    expect(closed.counterparty, isNull);
    expect(closed.cardLast4, isNull);
    expect(closed.senderId, isNull);
    expect(closed.suggestedCategoryId, isNull);
    expect(closed.suggestedPersonId, isNull);
    expect(closed.confidenceJson, '{}');
    expect(closed.warningsJson, '{}');
    // No saved record link: nothing was added.
    expect(closed.savedRecordId, isNull);

    final tombstone = (await tombstones()).single;
    expect(tombstone.fingerprint, 'fp-1');
    expect(tombstone.outcome, TombstoneOutcome.duplicate.dbValue);
    expect(tombstone.bankId, 'nbe');
    expect(tombstone.refHash, 'ref-1');
    expect(tombstone.refAmountHash, 'ra-1');
    expect(tombstone.savedRecordId, isNull);
    expect(tombstone.savedRecordType, isNull);
  });

  test('touches no saved record, no outbox row and no counter', () async {
    // The record the user already has (a manual expense).
    final existing = (await finance.addEntry(
      idempotencyKey: 'manual-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amount: const Money.egp(12550),
      date: DateTime(2026, 3, 4),
      note: 'Example Cafe',
    )).getOrElse((f) => fail('$f'));
    final entriesBefore = await database.select(database.financeEntries).get();
    final outboxBefore = await database
        .select(database.syncOutboxEntries)
        .get();
    await stage(buildPendingImport());

    expect((await closeAsDuplicate('pending-1')).isRight(), isTrue);

    final entriesAfter = await database.select(database.financeEntries).get();
    expect(entriesAfter, entriesBefore);
    expect(entriesAfter.single.id, existing.id);
    expect(await database.select(database.moneyTransactions).get(), isEmpty);
    expect(
      await database.select(database.syncOutboxEntries).get(),
      outboxBefore,
    );
    final settings = await SmsImportSettingsDao(database).getSettings();
    expect(settings?.addedCount ?? 0, 0);
    expect(settings?.ignoredCount ?? 0, 0);
  });

  test('the same message never comes back after closing', () async {
    await stage(buildPendingImport());
    await closeAsDuplicate('pending-1');
    final again = await repository.insertPending(
      NewPendingImport(
        item: buildPendingImport(id: 'pending-2', source: SmsSource.paste),
        rawMasked: body,
      ),
    );
    expect(again.getOrElse((f) => fail('$f')), InsertOutcome.alreadyKnown);
    expect(
      await database.select(database.pendingSmsImports).get(),
      hasLength(1),
    );
  });

  test('a closed item is no longer pending and its original is gone', () async {
    await stage(buildPendingImport());
    await closeAsDuplicate('pending-1');
    final item = (await repository.getById(
      'pending-1',
    )).getOrElse((f) => fail('$f'));
    expect(item.status, SmsImportStatus.duplicateClosed);
    expect(item.hasRawText, isFalse);
    expect(
      await repository.openOriginal('pending-1'),
      const Left<Failure, String>(OriginalUnavailableFailure()),
    );
    final pending = await repository.watchPending().first;
    expect(pending.getOrElse((f) => fail('$f')), isEmpty);
    // Not on the Undo list (ui-contract §3.8).
    final undo = await repository.watchUndoList().first;
    expect(undo.getOrElse((f) => fail('$f')), isEmpty);
  });

  test('a second close answers ImportAlreadyDecided and writes nothing '
      'more', () async {
    await stage(buildPendingImport());
    await closeAsDuplicate('pending-1');
    final first = await row();
    clock.advance(const Duration(minutes: 5));

    final second = await closeAsDuplicate('pending-1');
    expect(
      second,
      const Left<Failure, Unit>(
        ImportAlreadyDecidedFailure(SmsImportStatus.duplicateClosed),
      ),
    );
    expect(await row(), first);
    expect(await tombstones(), hasLength(1));
  });

  test('an added item cannot be closed as a duplicate', () async {
    await stage(buildPendingImport());
    final added = await repository.confirm(
      pendingId: 'pending-1',
      confirmed: ConfirmedFinanceEntry(
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
        amount: const Money.egp(12550),
        date: DateTime(2026, 3, 4),
      ),
    );
    expect(added.isRight(), isTrue);
    final tombstoneBefore = (await tombstones()).single;

    final result = await closeAsDuplicate('pending-1');
    expect(
      result,
      const Left<Failure, Unit>(
        ImportAlreadyDecidedFailure(SmsImportStatus.added),
      ),
    );
    expect((await row()).status, SmsImportStatus.added.dbValue);
    expect((await tombstones()).single, tombstoneBefore);
    expect(await database.select(database.financeEntries).get(), hasLength(1));
  });

  test('an unknown id is NotFound; failure messages carry no digits or '
      'content', () async {
    final result = await closeAsDuplicate('missing-42');
    final failure = result.getLeft().toNullable()!;
    expect(failure, isA<NotFoundFailure>());
    expect(failure.message, isNot(matches(RegExp('[0-9]'))));
    expect(await tombstones(), isEmpty);
  });

  test('a store failure rolls back and is a fixed token', () async {
    await stage(buildPendingImport());
    // Break the tombstone table so the insert throws inside the
    // transaction.
    await database.customStatement('DROP TABLE sms_import_tombstones');
    final result = await closeAsDuplicate('pending-1');
    final failure = result.getLeft().toNullable()!;
    expect(failure, isA<CacheFailure>());
    expect(failure.message, 'sms_import_store_failed');
    final unchanged = await row();
    expect(unchanged.status, SmsImportStatus.pending.dbValue);
    expect(unchanged.rawBlob, isNotNull);
  });
}
