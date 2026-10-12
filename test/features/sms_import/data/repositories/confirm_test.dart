import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
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
import 'package:daftary/features/transactions/data/models/transaction_mapper.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/test_daos.dart';
import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

/// T070 — `SmsImportRepositoryImpl.confirm`, the single review gate
/// (FR-052, FR-075a), against a real in-memory database, the real
/// transaction and finance repositories and the real AES-GCM vault. Every
/// value is synthetic.
void main() {
  late db.AppDatabase database;
  late FixedClock clock;
  late FakeSmsKeyStore keys;
  late TransactionsRepository transactions;
  late FinanceRepository finance;

  SmsImportRepositoryImpl build({
    TransactionsRepository? transactionsOverride,
    FinanceRepository? financeOverride,
  }) => SmsImportRepositoryImpl(
    SmsImportDao(database),
    SmsImportSettingsDao(database),
    AesGcmRawTextVault(keys),
    const SmsMaskerImpl(),
    FakeBankReferencePolicy(),
    clock,
    transactionsOverride ?? transactions,
    financeOverride ?? finance,
  );

  late SmsImportRepositoryImpl repository;

  /// Outbox rows written by the fixture (the person insert).
  late int baselineOutbox;

  const body = 'Purchase EGP 125.50 at Example Cafe card 0000';
  const groceries = 'seed_groceries';
  const salary = 'seed_salary';

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    // Runs beforeOpen (the first-launch category seed).
    await database.select(database.financeCategories).get();
    clock = FixedClock(DateTime(2026, 3, 4, 12));
    keys = FakeSmsKeyStore();
    transactions = TransactionsRepositoryImpl(
      testTransactionsDao(database),
      database,
    );
    finance = FinanceRepositoryImpl(testFinanceDao(database));
    repository = build();
    await testPeopleDao(
      database,
    ).insertPerson(id: 'person-1', name: 'Mona', createdAt: DateTime(2026));
    baselineOutbox =
        (await database.select(database.syncOutboxEntries).get()).length;
  });
  tearDown(() => database.close());

  Future<void> stage(PendingSmsImport item) async {
    final result = await repository.insertPending(
      NewPendingImport(item: item, rawMasked: body),
    );
    expect(result.getOrElse((f) => fail('$f')), InsertOutcome.inserted);
  }

  ConfirmedFinanceEntry expense({
    String categoryId = groceries,
    Money amount = const Money.egp(9900),
    String? note,
  }) => ConfirmedFinanceEntry(
    categoryId: categoryId,
    type: FinanceEntryType.expense,
    amount: amount,
    date: DateTime(2026, 3, 3),
    note: note,
  );

  ConfirmedPersonTransaction given({String personId = 'person-1'}) =>
      ConfirmedPersonTransaction(
        personId: personId,
        direction: TransactionDirection.given,
        amount: const Money.egp(12550),
        date: DateTime(2026, 3, 4),
      );

  Future<db.PendingSmsImportRow> row([String id = 'pending-1']) =>
      (database.select(
        database.pendingSmsImports,
      )..where((p) => p.id.equals(id))).getSingle();

  Future<int> count(Future<List<Object?>> rows) async => (await rows).length;
  Future<int> entries() =>
      count(database.select(database.financeEntries).get());
  Future<int> moneyRows() =>
      count(database.select(database.moneyTransactions).get());
  Future<int> tombstones() =>
      count(database.select(database.smsImportTombstones).get());
  Future<int> outbox() =>
      count(database.select(database.syncOutboxEntries).get());
  Future<int> addedCount() async {
    final settings = await SmsImportSettingsDao(database).getSettings();
    return settings?.addedCount ?? 0;
  }

  /// Everything an aborted confirm must leave untouched.
  Future<void> expectNothingWritten() async {
    expect(await entries(), 0);
    expect(await moneyRows(), 0);
    expect(await tombstones(), 0);
    expect(await outbox(), baselineOutbox);
    expect(await addedCount(), 0);
    expect(
      await database.select(database.smsMerchantCategoryMappings).get(),
      isEmpty,
    );
    final pending = await row();
    expect(pending.status, 'pending');
    expect(pending.rawBlob, isNotNull);
    expect(pending.merchant, 'Example Cafe');
  }

  group('a successful Add', () {
    test('saves one expense with the edited values and SMS provenance, '
        'a created audit row, and the added tombstone', () async {
      await stage(
        buildPendingImport(suggestedType: SuggestedRecordType.expense),
      );
      final result = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: expense(note: 'edited'),
      );
      final ref = result.getOrElse((f) => fail('$f'));
      expect(ref.type, SavedRecordType.financeEntry);

      final saved = await database.select(database.financeEntries).getSingle();
      expect(saved.id, ref.id);
      expect(saved.amountMinorUnits, 9900);
      expect(saved.note, 'edited');
      expect(saved.categoryId, groceries);
      expect(saved.importSource, 'sms');
      expect(saved.idempotencyKey, 'sms-import:pending-1');
      expect(
        DateTime.fromMillisecondsSinceEpoch(saved.date),
        DateTime(2026, 3, 3),
      );

      final audits = await database.select(database.financeEntryAudits).get();
      expect(audits, hasLength(1));
      expect(audits.single.financeEntryId, saved.id);
      expect(audits.single.changeType, 'created');

      final tomb = await database
          .select(database.smsImportTombstones)
          .getSingle();
      expect(tomb.fingerprint, 'fp-1');
      expect(tomb.outcome, 'added');
      expect(tomb.savedRecordId, saved.id);
      expect(tomb.savedRecordType, 'financeEntry');
      expect(
        tomb.purgeAfter - tomb.createdAt,
        greaterThanOrEqualTo(const Duration(days: 97).inMilliseconds),
      );
      expect(await addedCount(), 1);
    });

    test('marks the row added and leaves only its identity shell', () async {
      await stage(
        buildPendingImport(
          counterparty: 'Mona',
          refHash: 'rh1',
          refAmountHash: 'ra1',
        ),
      );
      final ref = (await repository.confirm(
        pendingId: 'pending-1',
        confirmed: expense(),
      )).getOrElse((f) => fail('$f'));

      final shell = await row();
      expect(shell.status, 'added');
      expect(shell.decidedAt, clock.now().millisecondsSinceEpoch);
      expect(shell.savedRecordId, ref.id);
      expect(shell.savedRecordType, 'financeEntry');
      expect(shell.rawBlob, isNull);
      // Identity kept.
      expect(shell.fingerprint, 'fp-1');
      expect(shell.refHash, 'rh1');
      expect(shell.refAmountHash, 'ra1');
      // Content scrubbed, sender included.
      expect(shell.senderId, isNull);
      expect(shell.merchant, isNull);
      expect(shell.merchantKey, isNull);
      expect(shell.counterparty, isNull);
      expect(shell.cardLast4, isNull);
      expect(shell.amountMinorUnits, isNull);
      expect(shell.currencyCode, isNull);
      expect(shell.occurredOn, isNull);
      expect(shell.timeMinutes, isNull);
      expect(shell.suggestedCategoryId, isNull);
      expect(shell.suggestedPersonId, isNull);
      expect(shell.suggestedAction, 'unset');
      expect(shell.kind, 'unknown');
      expect(shell.direction, 'unknown');
      expect(shell.confidenceJson, '{}');
      expect(shell.warningsJson, '{}');
    });

    test('a people-ledger Add keeps source = manual and sets '
        'import_source = sms (FR-086)', () async {
      await stage(
        buildPendingImport(
          kind: SmsKind.transferOut,
          suggestedType: SuggestedRecordType.given,
        ),
      );
      final ref = (await repository.confirm(
        pendingId: 'pending-1',
        confirmed: given(),
      )).getOrElse((f) => fail('$f'));
      expect(ref.type, SavedRecordType.moneyTransaction);

      final saved = await database
          .select(database.moneyTransactions)
          .getSingle();
      expect(saved.id, ref.id);
      expect(saved.source, 'manual');
      expect(saved.importSource, 'sms');
      expect(saved.kind, TransactionKind.initialExchange.dbValue);
      expect(saved.direction, 'given');
      expect(saved.personId, 'person-1');
      expect(saved.idempotencyKey, 'sms-import:pending-1');

      final audits = await database
          .select(database.transactionAuditEntries)
          .get();
      expect(audits.single.transactionId, saved.id);
      expect(audits.single.changeType, 'created');

      // The domain read path exposes the provenance (FR-057).
      final domain = saved.toDomain();
      expect(domain.source, TransactionSource.manual);
      expect(domain.importSource?.isSms, isTrue);
      expect(await entries(), 0);
    });
  });

  group('sync outbox (FR-086)', () {
    Future<Map<String, Object?>> queued(String entityId) async {
      final rows = await (database.select(
        database.syncOutboxEntries,
      )..where((o) => o.entityId.equals(entityId))).get();
      expect(rows, hasLength(1));
      return jsonDecode(rows.single.payloadJson) as Map<String, Object?>;
    }

    test(
      'the queued finance entry payload carries import_source = sms',
      () async {
        await stage(buildPendingImport());
        final ref = (await repository.confirm(
          pendingId: 'pending-1',
          confirmed: expense(),
        )).getOrElse((f) => fail('$f'));
        expect((await queued(ref.id))['import_source'], 'sms');
      },
    );

    test('the queued transaction payload carries import_source = sms and '
        'source = manual', () async {
      await stage(buildPendingImport(suggestedType: SuggestedRecordType.given));
      final ref = (await repository.confirm(
        pendingId: 'pending-1',
        confirmed: given(),
      )).getOrElse((f) => fail('$f'));
      final payload = await queued(ref.id);
      expect(payload['import_source'], 'sms');
      expect(payload['source'], 'manual');
    });
  });

  group('learned mapping (FR-056)', () {
    Future<List<db.SmsMerchantCategoryMappingRow>> mappings() =>
        database.select(database.smsMerchantCategoryMappings).get();

    test(
      'upserted when the chosen category differs from the suggestion',
      () async {
        await stage(buildPendingImport()); // no suggested category
        await repository.confirm(pendingId: 'pending-1', confirmed: expense());
        final mapping = (await mappings()).single;
        expect(mapping.merchantKey, 'example cafe');
        expect(mapping.entryType, 'expense');
        expect(mapping.categoryId, groceries);
      },
    );

    test('not written when the user kept the suggestion', () async {
      final item = PendingSmsImport(
        id: 'pending-1',
        fingerprint: 'fp-1',
        status: SmsImportStatus.pending,
        source: SmsSource.inboxScan,
        bankId: 'nbe',
        parserId: 'nbe',
        ruleVersion: 'nbe@1',
        kind: SmsKind.cardPurchase,
        direction: SmsDirection.debit,
        suggestedType: SuggestedRecordType.expense,
        confidence: highConfidence(),
        createdAt: kBuilderCreatedAt,
        expiresAt: PendingSmsImport.expiryFor(kBuilderCreatedAt),
        hasRawText: true,
        amount: const Money.egp(9900),
        occurredOn: DateTime(2026, 3, 3),
        merchant: 'Example Cafe',
        merchantKey: 'example cafe',
        suggestedCategoryId: groceries,
      );
      await stage(item);
      await repository.confirm(pendingId: 'pending-1', confirmed: expense());
      expect(await mappings(), isEmpty);
    });

    test('not written for a people-ledger Add', () async {
      await stage(buildPendingImport(suggestedType: SuggestedRecordType.given));
      await repository.confirm(pendingId: 'pending-1', confirmed: given());
      expect(await mappings(), isEmpty);
    });

    test('a rolled-back Add leaves no mapping', () async {
      await stage(buildPendingImport());
      final result = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: expense(categoryId: salary), // income category
      );
      expect(result.isLeft(), isTrue);
      expect(await mappings(), isEmpty);
    });
  });

  group('rollback on an inner Left (_ConfirmAborted)', () {
    test('an inner write followed by a Left is rolled back entirely, and '
        'the failure carries no inner text', () async {
      await stage(buildPendingImport());
      repository = build(financeOverride: _WritesThenFails(finance));
      final result = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: expense(),
      );
      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<CacheFailure>());
      expect(failure.message, isNot(contains('secret')));
      expect(failure.message, isNot(matches(RegExp('[0-9]'))));
      await expectNothingWritten();
    });

    test('a validation Left (category type mismatch) writes nothing', () async {
      await stage(buildPendingImport());
      final result = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: expense(categoryId: salary),
      );
      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<ValidationFailure>());
      // The inner message names the category; it must not pass through.
      expect(failure.message, isNot(contains('Salary')));
      await expectNothingWritten();
    });

    test('an archived category is rejected (SMS-only rule)', () async {
      await stage(buildPendingImport());
      await (database.update(
        database.financeCategories,
      )..where((c) => c.id.equals(groceries))).write(
        const db.FinanceCategoriesCompanion(isArchived: db.Value(true)),
      );
      final result = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: expense(),
      );
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      await expectNothingWritten();
    });

    test('a missing person is refused before any write', () async {
      await stage(buildPendingImport(suggestedType: SuggestedRecordType.given));
      final result = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: given(personId: 'nobody'),
      );
      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      await expectNothingWritten();
    });

    test('a throw inside the transaction (simulated kill before commit) '
        'leaves the item pending', () async {
      await stage(buildPendingImport());
      repository = build(financeOverride: _WritesThenThrows(finance));
      final result = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: expense(),
      );
      expect(result.getLeft().toNullable(), isA<CacheFailure>());
      await expectNothingWritten();
    });
  });

  group('exactly one record', () {
    test(
      'a second confirm returns ImportAlreadyDecided and writes nothing',
      () async {
        await stage(buildPendingImport());
        expect(
          (await repository.confirm(
            pendingId: 'pending-1',
            confirmed: expense(),
          )).isRight(),
          isTrue,
        );
        final outboxAfterFirst = await outbox();
        final second = await repository.confirm(
          pendingId: 'pending-1',
          confirmed: expense(),
        );
        final failure = second.getLeft().toNullable();
        expect(failure, isA<ImportAlreadyDecidedFailure>());
        expect(
          (failure! as ImportAlreadyDecidedFailure).status,
          SmsImportStatus.added,
        );
        expect(await entries(), 1);
        expect(await tombstones(), 1);
        expect(await outbox(), outboxAfterFirst);
        expect(await addedCount(), 1);
      },
    );

    test('two concurrent confirms yield exactly one record', () async {
      await stage(buildPendingImport());
      final results = await Future.wait([
        repository.confirm(pendingId: 'pending-1', confirmed: expense()),
        repository.confirm(pendingId: 'pending-1', confirmed: given()),
      ]);
      expect(results.where((r) => r.isRight()), hasLength(1));
      expect(
        results.where(
          (r) => r.getLeft().toNullable() is ImportAlreadyDecidedFailure,
        ),
        hasLength(1),
      );
      expect(await entries() + await moneyRows(), 1);
      expect(await tombstones(), 1);
      expect(await addedCount(), 1);
    });

    test('two concurrent confirms through two repository instances (one '
        'database) still yield one record', () async {
      await stage(buildPendingImport());
      final other = build();
      final results = await Future.wait([
        repository.confirm(pendingId: 'pending-1', confirmed: expense()),
        other.confirm(pendingId: 'pending-1', confirmed: expense()),
      ]);
      expect(results.where((r) => r.isRight()), hasLength(1));
      expect(await entries(), 1);
    });

    test('retry after a type switch: a failed expense attempt then a given '
        'attempt saves exactly one record, in the people ledger', () async {
      await stage(buildPendingImport());
      final failing = build(financeOverride: _WritesThenFails(finance));
      expect(
        (await failing.confirm(
          pendingId: 'pending-1',
          confirmed: expense(),
        )).isLeft(),
        isTrue,
      );
      final retry = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: given(),
      );
      expect(retry.isRight(), isTrue);
      expect(await entries(), 0);
      expect(await moneyRows(), 1);
    });

    test('retry after a type switch once added: refused, no second record '
        'in the other table', () async {
      await stage(buildPendingImport());
      await repository.confirm(pendingId: 'pending-1', confirmed: expense());
      final retry = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: given(),
      );
      expect(retry.getLeft().toNullable(), isA<ImportAlreadyDecidedFailure>());
      expect(await entries(), 1);
      expect(await moneyRows(), 0);
    });

    test('kill after commit (simulated restart): the item stays added and a '
        're-submit is refused', () async {
      await stage(buildPendingImport());
      await repository.confirm(pendingId: 'pending-1', confirmed: expense());
      // A fresh repository graph over the same database file models the
      // process after a restart.
      final restarted = SmsImportRepositoryImpl(
        SmsImportDao(database),
        SmsImportSettingsDao(database),
        AesGcmRawTextVault(keys),
        const SmsMaskerImpl(),
        FakeBankReferencePolicy(),
        clock,
        TransactionsRepositoryImpl(testTransactionsDao(database), database),
        FinanceRepositoryImpl(testFinanceDao(database)),
      );
      final again = await restarted.confirm(
        pendingId: 'pending-1',
        confirmed: expense(),
      );
      expect(again.getLeft().toNullable(), isA<ImportAlreadyDecidedFailure>());
      expect((await row()).status, 'added');
      expect(await entries(), 1);
    });

    test('a non-pending row is refused and nothing is written', () async {
      await stage(buildPendingImport());
      await repository.transitionRow('pending-1', SmsImportStatus.ignored);
      final result = await repository.confirm(
        pendingId: 'pending-1',
        confirmed: expense(),
      );
      expect(result.getLeft().toNullable(), isA<ImportAlreadyDecidedFailure>());
      expect(await entries(), 0);
      expect(await tombstones(), 0);
    });

    test('an unknown id is NotFound with a fixed token', () async {
      final result = await repository.confirm(
        pendingId: 'missing',
        confirmed: expense(),
      );
      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'sms_import_not_found');
    });
  });

  test('never-added items create no record (US1-6)', () async {
    await stage(buildPendingImport());
    await stage(buildPendingImport(id: 'pending-2', fingerprint: 'fp-2'));
    await repository.confirm(pendingId: 'pending-1', confirmed: expense());
    expect(await entries(), 1);
    expect((await row('pending-2')).status, 'pending');
  });
}

/// Writes a real entry through the real repository (inside the confirm
/// transaction), then reports a failure whose message carries text that
/// must never surface.
class _WritesThenFails implements FinanceRepository {
  _WritesThenFails(this._inner);

  final FinanceRepository _inner;

  @override
  Future<Either<Failure, FinanceEntry>> addSmsSourcedEntry({
    required String idempotencyKey,
    required String categoryId,
    required FinanceEntryType type,
    required Money amount,
    required DateTime date,
    String? note,
  }) async {
    final written = await _inner.addSmsSourcedEntry(
      idempotencyKey: idempotencyKey,
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: date,
      note: note,
    );
    expect(written.isRight(), isTrue);
    return const Left(CacheFailure('boom: secret 12345 parameters'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Writes a real entry, then throws: a crash before commit.
class _WritesThenThrows implements FinanceRepository {
  _WritesThenThrows(this._inner);

  final FinanceRepository _inner;

  @override
  Future<Either<Failure, FinanceEntry>> addSmsSourcedEntry({
    required String idempotencyKey,
    required String categoryId,
    required FinanceEntryType type,
    required Money amount,
    required DateTime date,
    String? note,
  }) async {
    await _inner.addSmsSourcedEntry(
      idempotencyKey: idempotencyKey,
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: date,
      note: note,
    );
    throw StateError('simulated crash secret 12345');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
