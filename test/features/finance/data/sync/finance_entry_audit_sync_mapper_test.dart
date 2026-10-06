import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/finance/data/sync/finance_entry_audit_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FinanceEntryAuditSyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  final edited = FinanceEntryAudit(
    id: 'a1',
    financeEntryId: 'e1',
    changeType: 'edited',
    previousValuesJson: jsonEncode({
      'amountMinorUnits': 30000,
      'currencyCode': 'EGP',
      'type': 'expense',
      'categoryId': 'seed_groceries',
      'date': 1790000000000,
      'note': null,
    }),
    changedAt: 1790000100000,
  );

  test('is the finance_entry_audit mapper, an append-only rank 2 type', () {
    expect(mapper.type, SyncEntityType.financeEntryAudit);
    expect(SyncEntityType.financeEntryAudit.wire, 'finance_entry_audit');
    expect(SyncEntityType.financeEntryAudit.rank, 2);
  });

  test('sends previous_values as a JSON object and stamps every instant '
      'with changed_at', () {
    final wire = mapper.toWire(edited);
    expect(wire['finance_entry_id'], 'e1');
    expect(wire['change_type'], 'edited');
    final previous = wire['previous_values']! as Map;
    expect(previous['type'], 'expense');
    expect(previous['categoryId'], 'seed_groceries');
    expect(wire['changed_at'], '2026-09-21T14:15:00.000Z');
    expect(wire['client_created_at'], wire['changed_at']);
    expect(wire['client_updated_at'], wire['changed_at']);
    expect(wire['deleted_at'], null);
  });

  test('round-trips all four change types, `created` with no previous '
      'values', () {
    for (final changeType in ['created', 'edited', 'deleted', 'restored']) {
      final row = FinanceEntryAudit(
        id: 'a-$changeType',
        financeEntryId: 'e1',
        changeType: changeType,
        previousValuesJson: changeType == 'created'
            ? null
            : edited.previousValuesJson,
        changedAt: edited.changedAt,
      );
      expect(
        mapper.fromWire(overTheWire(mapper.toWire(row))),
        row.toCompanion(false),
        reason: changeType,
      );
    }
  });

  test('rejects an unknown change type and previous_values that is not an '
      'object', () {
    expect(
      () => mapper.fromWire(mapper.toWire(edited)..['change_type'] = 'moved'),
      throwsFormatException,
    );
    for (final bad in ['{}', 1]) {
      expect(
        () => mapper.fromWire(mapper.toWire(edited)..['previous_values'] = bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });
}
