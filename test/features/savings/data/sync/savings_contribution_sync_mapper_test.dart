import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/savings/data/sync/savings_contribution_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = SavingsContributionSyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  // 100 USD typed in, converted once into the goal's 4,850 EGP.
  final row = SavingsContribution(
    id: 'c1',
    idempotencyKey: 'ck1',
    goalId: 'g1',
    type: 'contribution',
    amountMinorUnits: 485000,
    enteredAmountMinorUnits: 10000,
    enteredCurrencyCode: 'USD',
    date: DateTime(2026, 9, 21).millisecondsSinceEpoch,
    note: null,
    createdAt: 1790000000000,
    editedAt: null,
    deletedAt: null,
  );

  test('is the savings_contribution mapper', () {
    expect(mapper.type, SyncEntityType.savingsContribution);
  });

  test('emits both the goal-currency and the entered amount', () {
    final wire = mapper.toWire(row);
    expect(wire['goal_id'], 'g1');
    expect(wire['type'], 'contribution');
    expect(wire['amount_minor_units'], '485000');
    expect(wire['entered_amount_minor_units'], '10000');
    expect(wire['entered_currency_code'], 'USD');
    expect(wire['date'], DateTime(2026, 9, 21).toUtc().toIso8601String());
    expect(wire['edited_at'], null);
    expect(wire['deleted_at'], null);
    expect(wire['client_updated_at'], wire['client_created_at']);
  });

  test('client_updated_at is the latest of create, edit and delete', () {
    final edited = mapper.toWire(
      row.copyWith(editedAt: const Value(1790000100000)),
    );
    expect(edited['client_updated_at'], '2026-09-21T14:15:00.000Z');
    final deleted = mapper.toWire(
      row.copyWith(
        editedAt: const Value(1790000100000),
        deletedAt: const Value(1790000200000),
      ),
    );
    expect(deleted['client_updated_at'], '2026-09-21T14:16:40.000Z');
  });

  test('round-trips losslessly: withdrawals, notes, edits, tombstones and '
      'amounts above 2^53', () {
    for (final r in [
      row,
      row.copyWith(
        type: 'withdrawal',
        amountMinorUnits: 9007199254740993,
        enteredAmountMinorUnits: 9007199254740993,
        enteredCurrencyCode: 'EGP',
        note: const Value('Starting amount'),
        editedAt: const Value(1790000100000),
        deletedAt: const Value(1790000200000),
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
      ..['amount_minor_units'] = 485000
      ..['entered_amount_minor_units'] = 10000;
    expect(mapper.fromWire(pulled), row.toCompanion(false));
  });

  test('rejects an unknown type or a missing entered currency', () {
    expect(
      () => mapper.fromWire(mapper.toWire(row)..['type'] = 'transfer'),
      throwsFormatException,
    );
    expect(
      () =>
          mapper.fromWire(mapper.toWire(row)..remove('entered_currency_code')),
      throwsFormatException,
    );
  });
}
