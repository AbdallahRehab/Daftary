import 'dart:typed_data';

import 'package:daftary/core/confidence/field_confidence.dart';
import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/sms_import/data/models/pending_import_mapper.dart';
import 'package:daftary/features/sms_import/data/models/settings_mapper.dart';
import 'package:daftary/features/sms_import/data/models/tombstone_mapper.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_tombstone.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';

/// T057 — round trips through a real in-memory database; every value is
/// synthetic.
void main() {
  late db.AppDatabase database;

  setUp(() => database = db.AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<db.PendingSmsImportRow> roundTrip(
    db.PendingSmsImportsCompanion row,
  ) async {
    await database.into(database.pendingSmsImports).insert(row);
    return database.select(database.pendingSmsImports).getSingle();
  }

  group('pending import mapper', () {
    test('a full item survives the round trip', () async {
      final item = buildPendingImport(
        foreignAmount: Money.fromMinorUnits(2500, Currency.usd),
        warnings: {SmsWarning.genericParser, SmsWarning.dateInferred},
        refHash: 'r1',
        refAmountHash: 'ra1',
        counterparty: 'Example Person',
        parentImportId: 'parent-1',
        confidence: ParseConfidence(
          fields: {
            SmsField.amount: FieldConfidence.read(FieldConfidenceLevel.high),
            SmsField.date: const FieldConfidence.inferred(),
            SmsField.currency: FieldConfidence.read(FieldConfidenceLevel.low),
          },
          overall: OverallConfidence.medium,
        ),
        hasRawText: false,
      );
      final row = await roundTrip(pendingImportToCompanion(item));
      expect(row.toDomain(), item);
    });

    test('amount candidates and foreign text survive the round trip', () async {
      final base = buildPendingImport(amount: null, hasRawText: false);
      final item = buildPendingImport(amount: null, hasRawText: false);
      final row = await roundTrip(
        pendingImportToCompanion(item).copyWith(
          warningsJson: db.Value(
            encodeWarningsJson(
              amountCandidates: [100, 200],
              foreignAmountText: 'USD 25.00',
            ),
          ),
        ),
      );
      final read = row.toDomain();
      expect(read.amountCandidates, [100, 200]);
      expect(read.foreignAmountText, 'USD 25.00');
      expect(read.id, base.id);
    });

    test(
      'hasRawText is derived from the blob; the blob never enters',
      () async {
        final item = buildPendingImport(hasRawText: false);
        final row = await roundTrip(
          pendingImportToCompanion(
            item,
          ).copyWith(rawBlob: db.Value(Uint8List.fromList([1, 2, 3]))),
        );
        expect(row.toDomain().hasRawText, isTrue);
        expect(pendingImportToCompanion(item).rawBlob.present, isFalse);
      },
    );

    test('malformed JSON and unknown enum strings never throw', () async {
      final item = buildPendingImport(hasRawText: false);
      final row = await roundTrip(
        pendingImportToCompanion(item).copyWith(
          confidenceJson: const db.Value('not json'),
          warningsJson: const db.Value('{"warnings":["nope", 3],"x":1}'),
          kind: const db.Value('future_kind'),
          status: const db.Value('future_status'),
        ),
      );
      final read = row.toDomain();
      expect(read.confidence.overall, OverallConfidence.low);
      expect(read.confidence.fields, isEmpty);
      expect(read.warnings, isEmpty);
      expect(read.kind, SmsKind.unknown);
      expect(read.status, SmsImportStatus.duplicateClosed);
    });

    test('the scrubbed neutral values decode', () {
      expect(decodeConfidenceJson('{}').overall, OverallConfidence.low);
      expect(decodeWarningsJson('{}').warnings, isEmpty);
      expect(encodeWarningsJson(), '{}');
    });

    test('confidence JSON uses the read:<level>/inferred tokens', () {
      final json = encodeConfidenceJson(
        ParseConfidence(
          fields: {
            SmsField.amount: FieldConfidence.read(FieldConfidenceLevel.high),
            SmsField.date: const FieldConfidence.inferred(),
          },
          overall: OverallConfidence.high,
        ),
      );
      expect(
        json,
        '{"overall":"high","fields":{"amount":"read:high","date":"inferred"}}',
      );
    });
  });

  group('tombstone mapper', () {
    test('round trip', () async {
      final created = DateTime(2026, 3, 4, 10);
      final tombstone = SmsImportTombstone(
        fingerprint: 'fp-1',
        outcome: TombstoneOutcome.added,
        bankId: 'nbe',
        refHash: 'r1',
        refAmountHash: 'ra1',
        savedRecordId: 'rec-1',
        savedRecordType: SavedRecordType.financeEntry,
        createdAt: created,
        purgeAfter: SmsImportTombstone.minimumPurgeAfter(created),
      );
      await database
          .into(database.smsImportTombstones)
          .insert(tombstoneToCompanion(tombstone));
      final row = await database
          .select(database.smsImportTombstones)
          .getSingle();
      expect(row.toDomain(), tombstone);
    });
  });

  group('settings mapper', () {
    test('an id-only row reads as the fresh-install defaults', () async {
      await database
          .into(database.smsImportSettings)
          .insert(
            const db.SmsImportSettingsCompanion(id: db.Value('singleton')),
          );
      final row = await database.select(database.smsImportSettings).getSingle();
      expect(row.toDomain(), const SmsImportSettings());
    });

    test('an out-of-range window reads as the default', () async {
      await database
          .into(database.smsImportSettings)
          .insert(
            const db.SmsImportSettingsCompanion(
              id: db.Value('singleton'),
              scanWindowDays: db.Value(45),
            ),
          );
      final row = await database.select(database.smsImportSettings).getSingle();
      expect(row.toDomain().scanWindow, ScanWindow.days30);
    });

    test('rules seen JSON is total', () {
      expect(decodeRulesSeen(encodeRulesSeen({'nbe': 2})), {'nbe': 2});
      expect(decodeRulesSeen('[1]'), isEmpty);
      expect(decodeRulesSeen('{"a":"x","b":1}'), {'b': 1});
      expect(decodeRulesSeen('broken'), isEmpty);
    });

    test('a mapping with an unknown entry type is skipped', () {
      const row = db.SmsMerchantCategoryMappingRow(
        merchantKey: 'example cafe',
        entryType: 'transfer',
        categoryId: 'cat-1',
        updatedAt: 0,
      );
      expect(row.toDomain(), isNull);
      const good = db.SmsMerchantCategoryMappingRow(
        merchantKey: 'example cafe',
        entryType: 'income',
        categoryId: 'cat-1',
        updatedAt: 0,
      );
      expect(good.toDomain()?.entryType, FinanceEntryType.income);
    });
  });
}
