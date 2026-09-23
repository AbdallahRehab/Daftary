import 'package:equatable/equatable.dart';

import 'finance_entry_type.dart';

/// A user-facing label grouping finance entries — the shared vocabulary
/// Budgets (V2) is specified to read from as well.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.isArchived = false,
  });

  final String id;

  /// Required, non-empty after trim.
  final String name;

  /// Immutable after creation (data-model.md): changing it would silently
  /// reclassify every entry already referencing this category, so it is not
  /// offered as an edit operation.
  final CategoryType type;

  /// A `CategoryIconRegistry` key, never a raw `IconData` codepoint or a hex
  /// color (research.md Decision 10).
  final String icon;

  /// `true` for the seeded starter set. Carries no special protection — a
  /// default category is renameable and removable like any other (FR-009/
  /// FR-010).
  final bool isDefault;

  /// Hidden from the entry-creation picker (FR-011) while still resolving
  /// for the existing entries that reference it.
  final bool isArchived;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => !isArchived;

  Category copyWith({
    String? name,
    String? icon,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type,
      icon: icon ?? this.icon,
      isDefault: isDefault,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    icon,
    isDefault,
    isArchived,
    createdAt,
    updatedAt,
  ];
}
