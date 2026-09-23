import 'package:equatable/equatable.dart';

/// A named social event the user tracks money around — a wedding, a سبوع, a
/// condolence visit. It carries no money of its own: an occasion's totals are
/// always derived from the `MoneyTransaction` rows linked to it
/// (`kind = occasionContribution`), never stored here (research.md Decision 4).
class Occasion extends Equatable {
  const Occasion({
    required this.id,
    required this.idempotencyKey,
    required this.name,
    required this.date,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.isArchived = false,
    this.deletedAt,
  });

  final String id;

  /// Client-generated once per creation save action; a retried insert with
  /// the same key is a no-op that returns the existing row (FR-019).
  final String idempotencyKey;

  /// Required, non-empty after trim (FR-001).
  final String name;

  /// Date-only. May be in the future — pre-planned occasions are supported
  /// (spec Edge Cases).
  final DateTime date;

  /// One of [OccasionType.standardValues] or a free-text custom value
  /// (FR-002).
  final String type;
  final String? notes;

  /// `true` hides the occasion from the default list while preserving its
  /// detail, attachments, and contributions untouched (FR-014).
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft-delete tombstone; `null` means active. Set only by
  /// `DeleteOccasion`'s confirmed cascade (FR-013).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Occasion copyWith({
    String? name,
    DateTime? date,
    String? type,
    String? notes,
    bool? isArchived,
    DateTime? updatedAt,
  }) => Occasion(
    id: id,
    idempotencyKey: idempotencyKey,
    name: name ?? this.name,
    date: date ?? this.date,
    type: type ?? this.type,
    notes: notes ?? this.notes,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt,
  );

  @override
  List<Object?> get props => [
    id,
    idempotencyKey,
    name,
    date,
    type,
    notes,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
