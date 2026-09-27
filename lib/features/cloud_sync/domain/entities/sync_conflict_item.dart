import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// The financial record types that can be in a manual conflict (FR-035).
enum ConflictEntityType {
  moneyTransaction('money_transaction'),
  financeEntry('finance_entry');

  const ConflictEntityType(this.wire);

  /// The sync `entity_type` value.
  final String wire;

  static ConflictEntityType? tryFromWire(String value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

/// The money flow of one version: a transaction is given or received, a
/// finance entry is an expense or an income.
enum ConflictDirection { given, received, expense, income }

/// Which version the user keeps when resolving a conflict.
enum ConflictChoice { keepMine, keepTheirs }

/// The fields of one version the user compares: amount, date, direction and
/// note (plus whether that version deletes the record). Raw values only —
/// the Presentation layer formats them.
class ConflictVersion extends Equatable {
  const ConflictVersion({
    required this.amount,
    required this.date,
    required this.direction,
    this.note,
    this.isDeleted = false,
  });

  final Money amount;
  final DateTime date;
  final ConflictDirection direction;
  final String? note;
  final bool isDeleted;

  @override
  List<Object?> get props => [amount, date, direction, note, isDeleted];
}

/// 021: one open conflict on a financial record, with both versions
/// (contracts/dart-interfaces.md §4).
class SyncConflictItem extends Equatable {
  const SyncConflictItem({
    required this.entityType,
    required this.entityId,
    required this.localSummary,
    required this.serverSummary,
    required this.detectedAt,
  });

  final ConflictEntityType entityType;
  final String entityId;

  /// The version edited on this device ("mine").
  final ConflictVersion localSummary;

  /// The version on the server ("theirs").
  final ConflictVersion serverSummary;
  final DateTime detectedAt;

  @override
  List<Object?> get props => [
    entityType,
    entityId,
    localSummary,
    serverSummary,
    detectedAt,
  ];
}
