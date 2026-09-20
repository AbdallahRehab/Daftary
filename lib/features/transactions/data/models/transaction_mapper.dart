import '../../../../core/database/app_database.dart' as db;
import '../../../../core/money/money.dart';
import '../../domain/entities/money_transaction.dart' as domain;
import '../../domain/entities/transaction_audit_entry.dart' as domain;

/// Maps between `drift` rows and the domain entities. `direction`/`kind`/
/// `changeType` are stored as plain text columns — these extensions are the
/// single place that string ⇄ enum conversion happens.
extension MoneyTransactionMapper on db.MoneyTransaction {
  domain.MoneyTransaction toDomain() => domain.MoneyTransaction(
    id: id,
    idempotencyKey: idempotencyKey,
    personId: personId,
    amount: Money.fromMinorUnits(amountMinorUnits),
    direction: direction == 'given'
        ? domain.TransactionDirection.given
        : domain.TransactionDirection.received,
    kind: kind == 'repayment'
        ? domain.TransactionKind.repayment
        : domain.TransactionKind.initialExchange,
    date: DateTime.fromMillisecondsSinceEpoch(date),
    note: note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    editedAt: editedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(editedAt!),
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}

extension TransactionDirectionDb on domain.TransactionDirection {
  String get dbValue =>
      this == domain.TransactionDirection.given ? 'given' : 'received';
}

extension TransactionKindDb on domain.TransactionKind {
  String get dbValue => this == domain.TransactionKind.repayment
      ? 'repayment'
      : 'initialExchange';
}

extension TransactionAuditEntryMapper on db.TransactionAuditEntry {
  domain.TransactionAuditEntry toDomain() => domain.TransactionAuditEntry(
    id: id,
    transactionId: transactionId,
    changeType: switch (changeType) {
      'created' => domain.AuditChangeType.created,
      'edited' => domain.AuditChangeType.edited,
      'deleted' => domain.AuditChangeType.deleted,
      _ => throw StateError('Unknown audit changeType: $changeType'),
    },
    previousValuesJson: previousValuesJson,
    changedAt: DateTime.fromMillisecondsSinceEpoch(changedAt),
  );
}

extension AuditChangeTypeDb on domain.AuditChangeType {
  String get dbValue => switch (this) {
    domain.AuditChangeType.created => 'created',
    domain.AuditChangeType.edited => 'edited',
    domain.AuditChangeType.deleted => 'deleted',
  };
}
