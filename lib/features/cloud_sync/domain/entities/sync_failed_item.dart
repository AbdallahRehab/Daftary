import 'package:equatable/equatable.dart';

/// The kind of record a failed item is, for its label.
enum SyncItemKind {
  person,
  transaction,
  transactionHistory,
  financeCategory,
  financeEntry,
  exchangeRate,
  primaryCurrency,
  conflictResolution,
}

/// Why the cloud refused a record.
enum SyncFailedReason {
  /// The person was deleted here but has transactions on another device.
  personHasTransactions,

  /// The category's type no longer matches its entries.
  categoryTypeMismatch,

  /// The record did not pass the cloud's checks.
  invalid,

  /// Anything else.
  other,
}

/// 021 US6: one change the cloud refused; it stays on this device until the
/// user retries it (FR-040).
class SyncFailedItem extends Equatable {
  const SyncFailedItem({
    required this.kind,
    required this.entityId,
    required this.reason,
  });

  final SyncItemKind kind;
  final String entityId;
  final SyncFailedReason reason;

  @override
  List<Object?> get props => [kind, entityId, reason];
}
