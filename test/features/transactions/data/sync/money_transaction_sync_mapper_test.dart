import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_mapper_registry.dart';
import 'package:daftary/features/transactions/data/sync/money_transaction_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = MoneyTransactionSyncMapper();

  const date = 1790000000000;
  final row = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'k1',
    personId: 'p1',
    amountMinorUnits: 150000,
    currencyCode: 'USD',
    direction: 'given',
    kind: 'initialExchange',
    date: date,
    note: 'Lunch',
    createdAt: 1790000003120,
    editedAt: 1790000100000,
    deletedAt: null,
  );

  /// Encode → JSON text → decode, as a real push/pull would.
  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  test('is the money_transaction mapper', () {
    expect(mapper.type, SyncEntityType.moneyTransaction);
  });

  test('emits the contract wire shape', () {
    final wire = mapper.toWire(row);
    final local = DateTime.fromMillisecondsSinceEpoch(date);
    expect(wire, {
      'id': 't1',
      'idempotency_key': 'k1',
      'person_id': 'p1',
      'amount_minor': '150000',
      'currency_code': 'USD',
      'direction': 'given',
      'kind': 'initialExchange',
      'occurred_at': DateTime.fromMillisecondsSinceEpoch(
        date,
        isUtc: true,
      ).toIso8601String(),
      'occurred_on': SyncWire.localDay(local),
      'tz_offset_minutes': local.timeZoneOffset.inMinutes,
      'note': 'Lunch',
      'edited_at': '2026-09-21T14:15:00.000Z',
      'deleted_at': null,
      'client_created_at': '2026-09-21T14:13:23.120Z',
      'client_updated_at': '2026-09-21T14:15:00.000Z',
    });
    expect(wire['occurred_at'], endsWith('Z'));
    expect(wire['occurred_on'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  test('round-trips losslessly', () {
    expect(
      mapper.fromWire(overTheWire(mapper.toWire(row))),
      row.toCompanion(false),
    );
  });

  test('an amount above 2^53 round-trips losslessly as a string', () {
    final big = row.copyWith(amountMinorUnits: 9007199254740993);
    final wire = overTheWire(mapper.toWire(big));
    expect(wire['amount_minor'], '9007199254740993');
    expect(
      mapper.fromWire(wire).amountMinorUnits,
      const Value(9007199254740993),
    );
  });

  test('also accepts an integer amount (jsonb bigint on pull)', () {
    final wire = mapper.toWire(row)..['amount_minor'] = 9007199254740993;
    expect(
      mapper.fromWire(wire).amountMinorUnits,
      const Value(9007199254740993),
    );
  });

  test('a soft-deleted repayment round-trips with deleted_at', () {
    final deleted = row.copyWith(
      kind: 'repayment',
      direction: 'received',
      deletedAt: const Value(1790000200000),
    );
    final wire = overTheWire(mapper.toWire(deleted));
    expect(wire['deleted_at'], '2026-09-21T14:16:40.000Z');
    expect(wire['client_updated_at'], wire['deleted_at']);
    expect(mapper.fromWire(wire), deleted.toCompanion(false));
  });

  test('rejects unknown direction or kind values', () {
    expect(
      () => mapper.fromWire(mapper.toWire(row)..['direction'] = 'lent'),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(mapper.toWire(row)..['kind'] = 'initial_exchange'),
      throwsFormatException,
    );
  });
}
