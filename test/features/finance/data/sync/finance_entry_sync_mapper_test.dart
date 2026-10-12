import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_mapper_registry.dart';
import 'package:daftary/features/finance/data/sync/finance_entry_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FinanceEntrySyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  const row = FinanceEntry(
    id: 'e1',
    idempotencyKey: 'ek1',
    categoryId: 'seed_salary',
    type: 'income',
    amountMinorUnits: 2500000,
    currencyCode: 'EGP',
    date: 1790000000000,
    note: null,
    createdAt: 1790000000500,
    editedAt: null,
    deletedAt: 1790000200000,
  );

  /// B1: a date is a calendar day, so a download restores local midnight.
  int dayOf(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
  }

  test('is the finance_entry mapper', () {
    expect(mapper.type, SyncEntityType.financeEntry);
  });

  test('emits money as a string, category_id and the occurrence fields', () {
    final wire = mapper.toWire(row);
    final local = DateTime.fromMillisecondsSinceEpoch(row.date);
    expect(wire['amount_minor'], '2500000');
    expect(wire['category_id'], 'seed_salary');
    expect(wire['occurred_at'], '2026-09-21T14:13:20.000Z');
    expect(wire['occurred_on'], SyncWire.localDay(local));
    expect(wire['tz_offset_minutes'], local.timeZoneOffset.inMinutes);
    expect(wire['deleted_at'], '2026-09-21T14:16:40.000Z');
    expect(wire['edited_at'], null);
    expect(wire['client_updated_at'], wire['deleted_at']);
  });

  test('round-trips losslessly, including an amount above 2^53', () {
    for (final r in [
      row,
      row.copyWith(
        amountMinorUnits: 9007199254740993,
        note: const Value('Bonus'),
        editedAt: const Value(1790000100000),
        deletedAt: const Value(null),
      ),
    ]) {
      expect(
        mapper.fromWire(overTheWire(mapper.toWire(r))),
        r.copyWith(date: dayOf(r.date)).toCompanion(false),
      );
    }
  });

  test('B1: fromWire builds the date from occurred_on, in any device time '
      'zone', () {
    final wire = {
      ...overTheWire(mapper.toWire(row)),
      'occurred_on': '2026-10-01',
      'occurred_at': '2026-09-30T21:00:00.000Z',
      'tz_offset_minutes': 180,
    };
    expect(
      DateTime.fromMillisecondsSinceEpoch(mapper.fromWire(wire).date.value),
      DateTime(2026, 10, 1),
    );
  });

  test('B1: without occurred_on the date comes from occurred_at', () {
    final wire = {
      ...overTheWire(mapper.toWire(row)),
      'occurred_at': '2026-09-30T21:00:00.000Z',
    }..remove('occurred_on');
    expect(
      mapper.fromWire(wire).date.value,
      DateTime.utc(2026, 9, 30, 21).millisecondsSinceEpoch,
    );
  });

  group('import_source (023, sync-wire-027 §3)', () {
    final sms = row.copyWith(importSource: const Value('sms'));

    /// The wire of a pre-027 server row of [r]: the key is absent.
    Map<String, Object?> withoutKey(FinanceEntry r) =>
        overTheWire(mapper.toWire(r))..remove('import_source');

    test('toWire omits the key when the entry has no provenance', () {
      expect(mapper.toWire(row).containsKey('import_source'), isFalse);
    });

    test("toWire adds exactly the key when the entry is 'sms'", () {
      expect(mapper.toWire(sms), {
        ...mapper.toWire(row),
        'import_source': 'sms',
      });
    });

    test("an 'sms' entry round-trips losslessly", () {
      expect(
        mapper.fromWire(overTheWire(mapper.toWire(sms))),
        sms.copyWith(date: dayOf(sms.date)).toCompanion(false),
      );
    });

    test('with no local row, an absent or null key reads as null', () {
      expect(mapper.fromWire(withoutKey(row)).importSource, const Value(null));
      expect(
        mapper.fromWire({
          ...withoutKey(row),
          'import_source': null,
        }).importSource,
        const Value(null),
      );
    });

    test("a pull with the key absent keeps a local 'sms'", () {
      expect(
        mapper.fromWire(withoutKey(row), existingLocal: sms).importSource,
        const Value('sms'),
      );
    });

    test("a pull with the key present and null keeps a local 'sms'", () {
      expect(
        mapper.fromWire({
          ...withoutKey(row),
          'import_source': null,
        }, existingLocal: sms).importSource,
        const Value('sms'),
      );
    });

    test("a pull with 'sms' sets it over a local entry without provenance", () {
      expect(
        mapper
            .fromWire(overTheWire(mapper.toWire(sms)), existingLocal: row)
            .importSource,
        const Value('sms'),
      );
    });

    test('an unknown string is stored as-is, never rejected', () {
      expect(
        mapper.fromWire({
          ...withoutKey(row),
          'import_source': 'wallet',
        }).importSource,
        const Value('wallet'),
      );
    });

    test('a non-string value is a FormatException like every other field', () {
      expect(
        () => mapper.fromWire({...withoutKey(row), 'import_source': 1}),
        throwsFormatException,
      );
    });
  });
}
