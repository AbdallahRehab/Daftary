import 'dart:convert';

import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/models/tombstone_mapper.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_tombstone.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/services/raw_text_vault.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_daos.dart';
import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

/// T058 — the core of `SmsImportRepositoryImpl` against a real in-memory
/// database and the real AES-GCM vault. Every value is synthetic.
void main() {
  late db.AppDatabase database;
  late FixedClock clock;
  late FakeSmsKeyStore keys;
  late SmsImportRepositoryImpl repository;

  SmsImportRepositoryImpl build({RawTextVault? vault}) =>
      SmsImportRepositoryImpl(
        SmsImportDao(database),
        SmsImportSettingsDao(database),
        vault ?? AesGcmRawTextVault(keys),
        const SmsMaskerImpl(),
        FakeBankReferencePolicy({'uniquebank'}),
        clock,
        TransactionsRepositoryImpl(testTransactionsDao(database), database),
        FinanceRepositoryImpl(testFinanceDao(database)),
      );

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    clock = FixedClock(DateTime(2026, 3, 4, 12));
    keys = FakeSmsKeyStore();
    repository = build();
  });
  tearDown(() => database.close());

  Future<List<db.PendingSmsImportRow>> rows() =>
      database.select(database.pendingSmsImports).get();

  Future<InsertOutcome> insert(PendingSmsImport item, [String? raw]) async =>
      (await repository.insertPending(
        NewPendingImport(item: item, rawMasked: raw),
      )).getOrElse((f) => fail('unexpected $f'));

  const body = 'Purchase EGP 125.50 at Example Cafe card 4111111111111111';

  group('insertPending', () {
    test('idempotent across origins: one row per fingerprint', () async {
      expect(await insert(buildPendingImport(), body), InsertOutcome.inserted);
      expect(
        await insert(
          buildPendingImport(
            id: 'pending-2',
            source: SmsSource.paste,
            senderId: null,
          ),
          body,
        ),
        InsertOutcome.alreadyKnown,
      );
      expect(
        await insert(
          buildPendingImport(id: 'pending-3', source: SmsSource.share),
        ),
        InsertOutcome.alreadyKnown,
      );
      expect(await rows(), hasLength(1));
    });

    test('a tombstoned fingerprint is already known', () async {
      final created = clock.now();
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
      expect(await insert(buildPendingImport()), InsertOutcome.alreadyKnown);
      expect(await rows(), isEmpty);
    });

    test('tier 2 collapses a unique-reference bank at any date', () async {
      await insert(
        buildPendingImport(bankId: 'uniquebank', refAmountHash: 'ra1'),
      );
      final later = buildPendingImport(
        id: 'pending-2',
        fingerprint: 'fp-2',
        bankId: 'uniquebank',
        refAmountHash: 'ra1',
        occurredOn: DateTime(2026, 3, 20),
      );
      expect(await insert(later), InsertOutcome.alreadyKnown);
    });

    test('tier 2 for any other bank needs a date within one day', () async {
      await insert(buildPendingImport(refAmountHash: 'ra1'));
      expect(
        await insert(
          buildPendingImport(
            id: 'pending-2',
            fingerprint: 'fp-2',
            refAmountHash: 'ra1',
            occurredOn: DateTime(2026, 3, 5),
          ),
        ),
        InsertOutcome.alreadyKnown,
      );
      expect(
        await insert(
          buildPendingImport(
            id: 'pending-3',
            fingerprint: 'fp-3',
            refAmountHash: 'ra1',
            occurredOn: DateTime(2026, 3, 7),
          ),
        ),
        InsertOutcome.inserted,
      );
    });

    test('raw_blob is masked, sealed and never plaintext', () async {
      await insert(buildPendingImport(), body);
      final blob = (await rows()).single.rawBlob!;
      expect(blob.first, 0x01);
      final asText = latin1.decode(blob, allowInvalid: true);
      expect(asText, isNot(contains('Example Cafe')));
      expect(asText, isNot(contains('4111')));
      final original = await repository.openOriginal('pending-1');
      final text = original.getOrElse((f) => fail('unexpected $f'));
      expect(text, isNot(contains('4111111111111111')));
      expect(text, contains('1111'));
      expect(text, contains('Example Cafe'));
    });

    test('a seal failure stores the row with no original', () async {
      final vault = FakeRawTextVault()..failSeal = true;
      repository = build(vault: vault);
      expect(await insert(buildPendingImport(), body), InsertOutcome.inserted);
      expect((await rows()).single.rawBlob, isNull);
      final read = await repository.getById('pending-1');
      expect(read.getOrElse((f) => fail('$f')).hasRawText, isFalse);
    });

    test('a non-pending item is refused', () async {
      final result = await repository.insertPending(
        NewPendingImport(
          item: buildPendingImport(
            status: SmsImportStatus.ignored,
            decidedAt: clock.now(),
          ),
        ),
      );
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(await rows(), isEmpty);
    });
  });

  group('openOriginal', () {
    test('key loss: unavailable, the blob is nulled, fields kept', () async {
      await insert(buildPendingImport(), body);
      await keys.purge();
      final result = await repository.openOriginal('pending-1');
      expect(result.getLeft().toNullable(), isA<OriginalUnavailableFailure>());
      final row = (await rows()).single;
      expect(row.rawBlob, isNull);
      expect(row.merchant, 'Example Cafe');
      expect(row.amountMinorUnits, 12550);
    });

    test('a decided or missing row is unavailable', () async {
      await insert(buildPendingImport(), body);
      await repository.transitionRow('pending-1', SmsImportStatus.ignored);
      expect(
        (await repository.openOriginal('pending-1')).getLeft().toNullable(),
        isA<OriginalUnavailableFailure>(),
      );
      expect(
        (await repository.openOriginal('missing')).getLeft().toNullable(),
        isA<OriginalUnavailableFailure>(),
      );
    });
  });

  group('transition guard (data-model §6)', () {
    test('only pending -> terminal is legal', () {
      for (final from in SmsImportStatus.values) {
        for (final to in SmsImportStatus.values) {
          expect(
            SmsImportRepositoryImpl.canTransition(from, to),
            from == SmsImportStatus.pending && to != SmsImportStatus.pending,
            reason: '${from.name} -> ${to.name}',
          );
        }
      }
    });

    test('an illegal move is refused and writes nothing', () async {
      await insert(buildPendingImport(), body);
      final first = await repository.transitionRow(
        'pending-1',
        SmsImportStatus.ignored,
      );
      expect(first.isRight(), isTrue);
      final row = (await rows()).single;
      expect(row.status, 'ignored');
      expect(row.rawBlob, isNull);
      expect(row.decidedAt, clock.now().millisecondsSinceEpoch);

      for (final to in [
        SmsImportStatus.added,
        SmsImportStatus.pending,
        SmsImportStatus.expired,
      ]) {
        final again = await repository.transitionRow('pending-1', to);
        final failure = again.getLeft().toNullable();
        expect(failure, isA<ImportAlreadyDecidedFailure>());
        expect(
          (failure! as ImportAlreadyDecidedFailure).status,
          SmsImportStatus.ignored,
        );
      }
      expect((await rows()).single.status, 'ignored');
      expect(
        (await repository.transitionRow(
          'missing',
          SmsImportStatus.ignored,
        )).getLeft().toNullable(),
        isA<NotFoundFailure>(),
      );
    });
  });

  group('reading', () {
    test('watchPending: low confidence first, then oldest', () async {
      ParseConfidence level(OverallConfidence overall) =>
          ParseConfidence(fields: const {}, overall: overall);
      await insert(
        buildPendingImport(
          id: 'old-high',
          fingerprint: 'a',
          createdAt: DateTime(2026, 3, 1),
        ),
      );
      await insert(
        buildPendingImport(
          id: 'new-low',
          fingerprint: 'b',
          createdAt: DateTime(2026, 3, 3),
          confidence: level(OverallConfidence.low),
        ),
      );
      await insert(
        buildPendingImport(
          id: 'old-low',
          fingerprint: 'c',
          createdAt: DateTime(2026, 3, 2),
          confidence: level(OverallConfidence.low),
        ),
      );
      final list = (await repository.watchPending().first).getOrElse(
        (f) => fail('$f'),
      );
      expect(list.map((p) => p.id), ['old-low', 'new-low', 'old-high']);
      expect(
        (await repository.watchPendingCount().first).getOrElse((_) => -1),
        3,
      );
    });

    test('findKnown and refHashesForBank read rows and tombstones', () async {
      await insert(buildPendingImport(refHash: 'r1', refAmountHash: 'ra1'));
      final created = clock.now();
      await database
          .into(database.smsImportTombstones)
          .insert(
            tombstoneToCompanion(
              SmsImportTombstone(
                fingerprint: 'fp-t',
                outcome: TombstoneOutcome.added,
                bankId: 'nbe',
                refHash: 'r2',
                refAmountHash: 'ra2',
                createdAt: created,
                purgeAfter: SmsImportTombstone.minimumPurgeAfter(created),
              ),
            ),
          );
      final known = (await repository.findKnown(
        fingerprints: {'fp-1', 'fp-t', 'fp-new'},
        refAmountHashes: {'ra1', 'ra2', 'ra3'},
      )).getOrElse((f) => fail('$f'));
      expect(known.fingerprints, {'fp-1', 'fp-t'});
      expect(known.refAmountHashes, {'ra1', 'ra2'});
      expect((await repository.refHashesForBank('nbe')).getOrElse((_) => {}), {
        'r1',
        'r2',
      });
      expect(
        (await repository.refHashesForBank('cib')).getOrElse((_) => {'x'}),
        isEmpty,
      );
    });
  });

  test(
    'deleteAllPending removes pending rows and writes no tombstone',
    () async {
      await insert(buildPendingImport(), body);
      await insert(buildPendingImport(id: 'pending-2', fingerprint: 'fp-2'));
      await insert(buildPendingImport(id: 'pending-3', fingerprint: 'fp-3'));
      await repository.transitionRow('pending-3', SmsImportStatus.ignored);
      final deleted = await repository.deleteAllPending();
      expect(deleted.getOrElse((_) => -1), 2);
      expect((await rows()).map((r) => r.id), ['pending-3']);
      expect(
        await database.select(database.smsImportTombstones).get(),
        isEmpty,
      );
    },
  );

  test('failure messages carry no digits', () async {
    final failures = <Failure>[
      (await repository.getById('missing')).getLeft().toNullable()!,
      (await repository.openOriginal('missing')).getLeft().toNullable()!,
      (await repository.transitionRow(
        'missing',
        SmsImportStatus.added,
      )).getLeft().toNullable()!,
    ];
    for (final failure in failures) {
      expect(failure.message, isNot(matches(RegExp('[0-9]'))));
    }
  });
}
