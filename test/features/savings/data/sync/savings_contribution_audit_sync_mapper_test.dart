import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/savings/data/sync/savings_contribution_audit_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = SavingsContributionAuditSyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  final edited = SavingsContributionAudit(
    id: 'a1',
    contributionId: 'c1',
    changeType: 'edited',
    previousValuesJson: jsonEncode({
      'amountMinorUnits': 9007199254740993,
      'enteredAmountMinorUnits': 10000,
      'enteredCurrencyCode': 'USD',
      'date': 1790000000000,
      'note': null,
    }),
    changedAt: 1790000100000,
  );

  test('is the savings_contribution_audit mapper', () {
    expect(mapper.type, SyncEntityType.savingsContributionAudit);
  });

  test('sends previous_values as a JSON object and stamps every instant '
      'with changed_at', () {
    final wire = mapper.toWire(edited);
    expect(wire['contribution_id'], 'c1');
    expect(wire['change_type'], 'edited');
    expect(wire['previous_values'], isA<Map<String, Object?>>());
    expect(
      (wire['previous_values']! as Map)['amountMinorUnits'],
      9007199254740993,
    );
    expect(wire['changed_at'], '2026-09-21T14:15:00.000Z');
    expect(wire['client_created_at'], wire['changed_at']);
    expect(wire['client_updated_at'], wire['changed_at']);
    expect(wire.containsKey('deleted_at'), isTrue);
    expect(wire['deleted_at'], null);
  });

  test('round-trips both change types', () {
    for (final changeType in ['edited', 'deleted']) {
      final row = edited.copyWith(changeType: changeType);
      expect(
        mapper.fromWire(overTheWire(mapper.toWire(row))),
        row.toCompanion(false),
        reason: changeType,
      );
    }
  });

  test('rejects an unknown change type, and previous_values that is not an '
      'object', () {
    expect(
      () => mapper.fromWire(mapper.toWire(edited)..['change_type'] = 'created'),
      throwsFormatException,
    );
    for (final bad in [null, '{}', 1]) {
      expect(
        () => mapper.fromWire(mapper.toWire(edited)..['previous_values'] = bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });
}
