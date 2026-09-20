import 'package:equatable/equatable.dart';

/// The kind of change an audit entry records — never updated or removed
/// once written (append-only), one row per create/edit/delete.
enum AuditChangeType { created, edited, deleted }

/// One append-only row in a [MoneyTransaction]'s audit trail, satisfying
/// the constitution's Financial Domain Override ("every financial mutation
/// MUST be traceable via IDs, timestamps, audit metadata") and SC-007.
class TransactionAuditEntry extends Equatable {
  const TransactionAuditEntry({
    required this.id,
    required this.transactionId,
    required this.changeType,
    required this.changedAt,
    this.previousValuesJson,
  });

  final String id;
  final String transactionId;
  final AuditChangeType changeType;

  /// JSON snapshot of the fields as they were *before* this change. `null`
  /// for [AuditChangeType.created].
  final String? previousValuesJson;
  final DateTime changedAt;

  @override
  List<Object?> get props => [
    id,
    transactionId,
    changeType,
    previousValuesJson,
    changedAt,
  ];
}
