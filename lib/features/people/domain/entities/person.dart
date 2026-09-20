import 'package:equatable/equatable.dart';

/// An individual the app's user has a money relationship with.
class Person extends Equatable {
  const Person({
    required this.id,
    required this.name,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.avatarPath,
    this.relationshipTag,
    this.notes,
  });

  final String id;

  /// Required, non-empty after trim (FR-001).
  final String name;
  final String? phoneNumber;
  final String? avatarPath;
  final String? relationshipTag;
  final String? notes;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Person copyWith({
    String? name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarPath: avatarPath ?? this.avatarPath,
      relationshipTag: relationshipTag ?? this.relationshipTag,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phoneNumber,
    avatarPath,
    relationshipTag,
    notes,
    isArchived,
    createdAt,
    updatedAt,
  ];
}
