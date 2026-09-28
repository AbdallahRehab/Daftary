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
    amount: Money.fromMinorUnits(
      amountMinorUnits,
      Currency.fromCode(currencyCode),
    ),
    direction: direction == 'given'
        ? domain.TransactionDirection.given
        : domain.TransactionDirection.received,
    kind: switch (kind) {
      'initialExchange' => domain.TransactionKind.initialExchange,
      'repayment' => domain.TransactionKind.repayment,
      'occasionContribution' => domain.TransactionKind.occasionContribution,
      _ => throw StateError('Unknown transaction kind: $kind'),
    },
    date: DateTime.fromMillisecondsSinceEpoch(date),
    note: note,
    occasionId: occasionId,
    countsTowardBalance: countsTowardBalance,
    source: switch (source) {
      'manual' => domain.TransactionSource.manual,
      'ocr' => domain.TransactionSource.ocr,
      _ => throw StateError('Unknown transaction source: $source'),
    },
    ocrScanId: ocrScanId,
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
  /// Exhaustive by design: a ternary fallback would silently persist any
  /// future kind as `initialExchange`, quietly corrupting balances. A
  /// `switch` over the enum makes adding a kind a compile error instead.
  String get dbValue => switch (this) {
    domain.TransactionKind.initialExchange => 'initialExchange',
    domain.TransactionKind.repayment => 'repayment',
    domain.TransactionKind.occasionContribution => 'occasionContribution',
  };
}

/// Exhaustive for the same reason [TransactionKindDb] is: a row whose
/// origin silently defaulted to `manual` would be a transaction quietly
/// lying about where it came from (009 FR-012).
extension TransactionSourceDb on domain.TransactionSource {
  String get dbValue => switch (this) {
    domain.TransactionSource.manual => 'manual',
    domain.TransactionSource.ocr => 'ocr',
  };
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
