import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// Which way the money moved.
enum TransactionDirection { given, received }

/// Whether a transaction is a regular exchange or a repayment against an
/// existing balance. Fixed at creation — never changeable via edit
/// (Clarifications): reclassifying means delete + re-create.
enum TransactionKind { initialExchange, repayment }

/// A single recorded money event between the user and one [Person]. The
/// atomic, immutable-by-default unit of financial truth — edits and
/// deletions are explicit, confirmed, and traceable rather than silent.
class MoneyTransaction extends Equatable {
  const MoneyTransaction({
    required this.id,
    required this.idempotencyKey,
    required this.personId,
    required this.amount,
    required this.direction,
    required this.kind,
    required this.date,
    required this.createdAt,
    this.note,
    this.editedAt,
    this.deletedAt,
  });

  final String id;

  /// Client-generated once per user-initiated save action; a retried insert
  /// with the same key is a no-op that returns the existing row (FR-020).
  final String idempotencyKey;
  final String personId;

  /// Always strictly positive (FR-005).
  final Money amount;
  final TransactionDirection direction;
  final TransactionKind kind;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  /// `null` means never edited. Presence drives the "edited" UI marker
  /// (FR-015).
  final DateTime? editedAt;

  /// Soft-delete tombstone; `null` means active.
  final DateTime? deletedAt;

  bool get isEdited => editedAt != null;
  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
    id,
    idempotencyKey,
    personId,
    amount,
    direction,
    kind,
    date,
    note,
    createdAt,
    editedAt,
    deletedAt,
  ];
}
