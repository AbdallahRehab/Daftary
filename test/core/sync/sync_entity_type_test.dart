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
        SyncEntityType.occasion: 'occasion',
        SyncEntityType.budget: 'budget',
        SyncEntityType.budgetAllocation: 'budget_allocation',
        SyncEntityType.savingsGoal: 'savings_goal',
        SyncEntityType.savingsContribution: 'savings_contribution',
        SyncEntityType.savingsContributionAudit: 'savings_contribution_audit',
        SyncEntityType.financeEntryAudit: 'finance_entry_audit',
      },
    );
  });

  test('ranks follow data-model.md depends_on_rank', () {
    expect(
      {for (final t in SyncEntityType.values) t: t.rank},
      {
        SyncEntityType.person: 0,
        SyncEntityType.financeCategory: 0,
        SyncEntityType.occasion: 0,
        SyncEntityType.budget: 0,
        SyncEntityType.savingsGoal: 0,
        SyncEntityType.moneyTransaction: 1,
        SyncEntityType.budgetAllocation: 1,
        SyncEntityType.financeEntry: 1,
        SyncEntityType.savingsContribution: 1,
        SyncEntityType.transactionAudit: 2,
        SyncEntityType.conflictResolution: 2,
        SyncEntityType.savingsContributionAudit: 2,
        SyncEntityType.financeEntryAudit: 2,
        SyncEntityType.exchangeRate: 3,
        SyncEntityType.primaryCurrency: 3,
      },
    );
  });

  test('fromWire throws on an unknown value', () {
    expect(
      () => SyncEntityType.fromWire('recurring_bill'),
      throwsArgumentError,
    );
    expect(() => SyncEntityType.fromWire(''), throwsArgumentError);
  });
}
