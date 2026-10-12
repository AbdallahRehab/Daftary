import 'package:daftary/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'v101_mappers.dart';

/// 023 T149 — the compatibility gate for migration 027
/// (specs/023-bank-sms-import/contracts/sync-wire-027.md §4, §6).
///
/// After 027 the server's `to_jsonb(t)` rows carry `import_source`
/// (`'sms'` or `null`). The installed v1.0.1 app must still pull them: its
/// frozen `fromWire` (see `v101_mappers.dart`, copied from `c86e2df`) must not
/// throw, and must read exactly the business values it read before 027. An
/// invented future key (`future_field`) proves the mappers read named keys
/// only, so later additive columns are equally safe.
void main() {
  const transactions = V101MoneyTransactionSyncMapper();
  const entries = V101FinanceEntrySyncMapper();

  // A `to_jsonb(t)` row of public.money_transactions as the server stored it
  // before 027 (money is a JSON number, instants are timestamptz text).
  Map<String, Object?> transactionRow() => {
    'owner_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'id': 't1',
    'revision': 42,
    'client_created_at': '2026-10-06T09:12:03.12+00:00',
    'client_updated_at': '2026-10-06T09:12:03.12+00:00',
    'server_created_at': '2026-10-06T09:12:04.551203+00:00',
    'server_updated_at': '2026-10-06T09:12:04.551203+00:00',
    'deleted_at': null,
    'last_device_id': 'd0d0d0d0-0000-4000-8000-000000000001',
    'person_id': 'p1',
    'idempotency_key': 'sms-import:7f3c',
    'amount_minor': 12550,
    'currency_code': 'EGP',
    'direction': 'given',
    'kind': 'initialExchange',
    'occurred_at': '2026-10-06T09:12:00+00:00',
    'occurred_on': '2026-10-06',
    'tz_offset_minutes': 180,
    'note': 'lunch',
    'edited_at': null,
    'occasion_id': null,
    'counts_toward_balance': true,
    'source': 'manual',
    'ocr_scan_id': null,
  };

  // A `to_jsonb(t)` row of public.finance_entries before 027.
  Map<String, Object?> entryRow() => {
    'owner_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'id': 'e1',
    'revision': 43,
    'client_created_at': '2026-10-06T09:12:03.12+00:00',
    'client_updated_at': '2026-10-06T10:00:00+00:00',
    'server_created_at': '2026-10-06T09:12:04.551203+00:00',
    'server_updated_at': '2026-10-06T10:00:01.1+00:00',
    'deleted_at': null,
    'last_device_id': 'd0d0d0d0-0000-4000-8000-000000000001',
    'category_id': 'c1',
    'idempotency_key': 'sms-import:9a1b',
    'type': 'expense',
    'amount_minor': 13000,
    'currency_code': 'EGP',
    'occurred_at': '2026-10-06T09:12:00+00:00',
    'occurred_on': '2026-10-06',
    'tz_offset_minutes': 180,
    'note': null,
    'edited_at': '2026-10-06T10:00:00+00:00',
  };

  // The same rows after 027, plus a key no app knows yet.
  Map<String, Object?> post027(Map<String, Object?> row, Object? value) => {
    ...row,
    'import_source': value,
    'future_field': 1,
  };

  group('v1.0.1 money_transaction fromWire', () {
    test('accepts a post-027 row with import_source sms and a future key', () {
      expect(
        () => transactions.fromWire(post027(transactionRow(), 'sms')),
        returnsNormally,
      );
    });

    test('accepts a post-027 row with import_source null', () {
      expect(
        () => transactions.fromWire(post027(transactionRow(), null)),
        returnsNormally,
      );
    });

    test('reads the same business values as before 027', () {
      final before = transactions.fromWire(transactionRow());
      final afterSms = transactions.fromWire(post027(transactionRow(), 'sms'));
      final afterNull = transactions.fromWire(post027(transactionRow(), null));

      expect(afterSms, before);
      expect(afterNull, before);
    });

    test('the business values are the pulled ones', () {
      final c = transactions.fromWire(post027(transactionRow(), 'sms'));

      expect(c.id, const Value('t1'));
      expect(c.idempotencyKey, const Value('sms-import:7f3c'));
      expect(c.personId, const Value('p1'));
      expect(c.amountMinorUnits, const Value(12550));
      expect(c.currencyCode, const Value('EGP'));
      expect(c.direction, const Value('given'));
      expect(c.kind, const Value('initialExchange'));
      expect(
        c.date,
        Value(DateTime.utc(2026, 10, 6, 9, 12).millisecondsSinceEpoch),
      );
      expect(c.note, const Value<String?>('lunch'));
      expect(c.occasionId, const Value<String?>(null));
      expect(c.countsTowardBalance, const Value(true));
      // Provenance is NOT a new `source` value: v1.0.1 reads `source` with
      // oneOf and would throw on anything but manual/ocr.
      expect(c.source, const Value('manual'));
      expect(c.ocrScanId, const Value<String?>(null));
      expect(
        c.createdAt,
        Value(DateTime.utc(2026, 10, 6, 9, 12, 3, 120).millisecondsSinceEpoch),
      );
      expect(c.editedAt, const Value<int?>(null));
      expect(c.deletedAt, const Value<int?>(null));
    });

    test('still throws on an unknown source value (why 027 adds a column)', () {
      expect(
        () => transactions.fromWire({...transactionRow(), 'source': 'sms'}),
        throwsFormatException,
      );
    });
  });

  group('v1.0.1 finance_entry fromWire', () {
    test('accepts a post-027 row with import_source sms and a future key', () {
      expect(
        () => entries.fromWire(post027(entryRow(), 'sms')),
        returnsNormally,
      );
    });

    test('accepts a post-027 row with import_source null', () {
      expect(
        () => entries.fromWire(post027(entryRow(), null)),
        returnsNormally,
      );
    });

    test('reads the same business values as before 027', () {
      final before = entries.fromWire(entryRow());
      final afterSms = entries.fromWire(post027(entryRow(), 'sms'));
      final afterNull = entries.fromWire(post027(entryRow(), null));

      expect(afterSms, before);
      expect(afterNull, before);
    });

    test('the business values are the pulled ones', () {
      final c = entries.fromWire(post027(entryRow(), 'sms'));

      expect(c.id, const Value('e1'));
      expect(c.idempotencyKey, const Value('sms-import:9a1b'));
      expect(c.categoryId, const Value('c1'));
      expect(c.type, const Value('expense'));
      expect(c.amountMinorUnits, const Value(13000));
      expect(c.currencyCode, const Value('EGP'));
      expect(
        c.date,
        Value(DateTime.utc(2026, 10, 6, 9, 12).millisecondsSinceEpoch),
      );
      expect(c.note, const Value<String?>(null));
      expect(
        c.createdAt,
        Value(DateTime.utc(2026, 10, 6, 9, 12, 3, 120).millisecondsSinceEpoch),
      );
      expect(
        c.editedAt,
        Value<int?>(DateTime.utc(2026, 10, 6, 10).millisecondsSinceEpoch),
      );
      expect(c.deletedAt, const Value<int?>(null));
    });
  });
}
