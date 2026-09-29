import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/savings/data/sync/savings_goal_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = SavingsGoalSyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  final row = SavingsGoal(
    id: 'g1',
    idempotencyKey: 'gk1',
    name: 'Emergency Fund',
    type: 'emergencyFund',
    currencyCode: 'EGP',
    targetAmountMinorUnits: 10000000,
    monthlyContributionMinorUnits: 500000,
    targetDate: DateTime(2027, 9, 20).millisecondsSinceEpoch,
    isArchived: false,
    createdAt: 1790000000000,
    updatedAt: 1790000100000,
    deletedAt: null,
  );

  test('is the savings_goal mapper', () {
    expect(mapper.type, SyncEntityType.savingsGoal);
  });

  test('emits the 023 wire shape: money as strings, instants as ISO', () {
    final wire = mapper.toWire(row);
    expect(wire['idempotency_key'], 'gk1');
    expect(wire['type'], 'emergencyFund');
    expect(wire['currency_code'], 'EGP');
    expect(wire['target_amount_minor_units'], '10000000');
    expect(wire['monthly_contribution_minor_units'], '500000');
    expect(
      wire['target_date'],
      DateTime(2027, 9, 20).toUtc().toIso8601String(),
    );
    expect(wire['is_archived'], false);
    expect(wire['deleted_at'], null);
    expect(wire['client_created_at'], '2026-09-21T14:13:20.000Z');
    expect(wire['client_updated_at'], '2026-09-21T14:15:00.000Z');
    expect(wire.keys, isNot(contains('owner_id')));
    expect(wire.keys, isNot(contains('revision')));
  });

  test('a delete is a tombstone upsert whose client_updated_at is the '
      'delete', () {
    final wire = mapper.toWire(
      row.copyWith(deletedAt: const Value(1790000200000)),
    );
    expect(wire['deleted_at'], '2026-09-21T14:16:40.000Z');
    expect(wire['client_updated_at'], wire['deleted_at']);
  });

  test('round-trips losslessly, with and without the optional fields', () {
    for (final r in [
      row,
      row.copyWith(
        type: const Value(null),
        currencyCode: 'USD',
        targetAmountMinorUnits: 9007199254740993,
        monthlyContributionMinorUnits: const Value(null),
        targetDate: const Value(null),
        isArchived: true,
      ),
      row.copyWith(
        updatedAt: 1790000300000,
        deletedAt: const Value(1790000300000),
      ),
    ]) {
      expect(
        mapper.fromWire(overTheWire(mapper.toWire(r))),
        r.toCompanion(false),
      );
    }
  });

  test('accepts pulled amounts as JSON integers', () {
    final pulled = overTheWire(mapper.toWire(row))
      ..['target_amount_minor_units'] = 10000000
      ..['monthly_contribution_minor_units'] = 500000;
    expect(mapper.fromWire(pulled), row.toCompanion(false));
  });

  test('falls back to server timestamps when client ones are missing', () {
    final pulled = overTheWire(mapper.toWire(row))
      ..remove('client_created_at')
      ..remove('client_updated_at')
      ..['server_created_at'] = '2026-09-21T14:13:20.000Z'
      ..['server_updated_at'] = '2026-09-21T14:15:00.000Z';
    expect(mapper.fromWire(pulled), row.toCompanion(false));
  });

  test('rejects a malformed amount or a missing name', () {
    expect(
      () => mapper.fromWire(
        mapper.toWire(row)..['target_amount_minor_units'] = 'lots',
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(mapper.toWire(row)..remove('name')),
      throwsFormatException,
    );
  });
}
