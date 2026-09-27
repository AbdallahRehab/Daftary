import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/transactions/data/sync/transaction_audit_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TransactionAuditSyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  final edited = TransactionAuditEntry(
    id: 'a1',
    transactionId: 't1',
    changeType: 'edited',
    previousValuesJson: jsonEncode({
      'amountMinorUnits': 9007199254740993,
      'note': null,
      'date': 1790000000000,
    }),
    changedAt: 1790000100000,
  );

  test('is the transaction_audit mapper', () {
    expect(mapper.type, SyncEntityType.transactionAudit);
  });

  test('carries change_type unchanged and previous_values as an object', () {
    final wire = mapper.toWire(edited);
    expect(wire['change_type'], 'edited');
    expect(wire['previous_values'], isA<Map<String, Object?>>());
    expect(
      (wire['previous_values']! as Map)['amountMinorUnits'],
      9007199254740993,
    );
    expect(wire['changed_at'], '2026-09-21T14:15:00.000Z');
  });

  test('round-trips every change type, with and without previous values', () {
    for (final changeType in ['created', 'edited', 'deleted']) {
      for (final previous in [null, edited.previousValuesJson]) {
        final row = edited.copyWith(
          changeType: changeType,
          previousValuesJson: Value(previous),
        );
        expect(
          mapper.fromWire(overTheWire(mapper.toWire(row))),
          row.toCompanion(false),
          reason: '$changeType / $previous',
        );
      }
    }
  });

  test('rejects an unknown change type or a non-object previous_values', () {
    expect(
      () => mapper.fromWire(mapper.toWire(edited)..['change_type'] = 'moved'),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(mapper.toWire(edited)..['previous_values'] = '[1]'),
      throwsFormatException,
    );
  });
}
