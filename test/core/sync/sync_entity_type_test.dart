import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every value round-trips through its wire name', () {
    for (final type in SyncEntityType.values) {
      expect(SyncEntityType.fromWire(type.wire), type);
    }
  });

  test('wire names match the cloud entity_type values', () {
    expect(
      {for (final t in SyncEntityType.values) t: t.wire},
      {
        SyncEntityType.person: 'person',
        SyncEntityType.moneyTransaction: 'money_transaction',
        SyncEntityType.transactionAudit: 'transaction_audit',
        SyncEntityType.financeCategory: 'finance_category',
        SyncEntityType.financeEntry: 'finance_entry',
        SyncEntityType.exchangeRate: 'exchange_rate',
        SyncEntityType.primaryCurrency: 'primary_currency',
        SyncEntityType.conflictResolution: 'conflict_resolution',
      },
    );
  });

  test('ranks follow data-model.md depends_on_rank', () {
    expect(
      {for (final t in SyncEntityType.values) t: t.rank},
      {
        SyncEntityType.person: 0,
        SyncEntityType.financeCategory: 0,
        SyncEntityType.moneyTransaction: 1,
        SyncEntityType.financeEntry: 1,
        SyncEntityType.transactionAudit: 2,
        SyncEntityType.conflictResolution: 2,
        SyncEntityType.exchangeRate: 3,
        SyncEntityType.primaryCurrency: 3,
      },
    );
  });

  test('fromWire throws on an unknown value', () {
    expect(() => SyncEntityType.fromWire('budget'), throwsArgumentError);
    expect(() => SyncEntityType.fromWire(''), throwsArgumentError);
  });
}
