import 'package:equatable/equatable.dart';

import '../../domain/entities/person.dart';

enum PersonFormStatus {
  idle,
  submitting,
  success,
  failure,
  deleteBlocked,
  deleted,
  archived,
}

/// Immutable state for [PersonFormCubit] (constitution Principle IV). Drives
/// both create mode (US1/US5) and edit mode (US5), including the delete/
/// archive actions available only in edit mode.
class PersonFormState extends Equatable {
  const PersonFormState({
    this.status = PersonFormStatus.idle,
    this.isEditMode = false,
    this.editingPersonId,
    this.name = '',
    this.phoneNumber,
    this.relationshipTag,
    this.notes,
    this.nameInvalid = false,
    this.errorMessage,
    this.duplicateMatches = const [],
    this.savedPerson,
  });

  final PersonFormStatus status;
  final bool isEditMode;
  final String? editingPersonId;
  final String name;
  final String? phoneNumber;
  final String? relationshipTag;
  final String? notes;

  /// Set by this cubit's own client-side "name required" check (FR-001) —
  /// a flag rather than a message so the page can render it via
  /// `l10n.nameRequiredError` regardless of locale (T105).
  final bool nameInvalid;
  final String? errorMessage;
  final List<Person> duplicateMatches;
  final Person? savedPerson;

  bool get isSubmitting => status == PersonFormStatus.submitting;

  PersonFormState copyWith({
    PersonFormStatus? status,
    bool? isEditMode,
    String? editingPersonId,
    String? name,
    String? phoneNumber,
    String? relationshipTag,
    String? notes,
    bool? nameInvalid,
    bool clearNameError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<Person>? duplicateMatches,
    Person? savedPerson,
  }) {
    return PersonFormState(
      status: status ?? this.status,
      isEditMode: isEditMode ?? this.isEditMode,
      editingPersonId: editingPersonId ?? this.editingPersonId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationshipTag: relationshipTag ?? this.relationshipTag,
      notes: notes ?? this.notes,
      nameInvalid: clearNameError ? false : (nameInvalid ?? this.nameInvalid),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      duplicateMatches: duplicateMatches ?? this.duplicateMatches,
      savedPerson: savedPerson ?? this.savedPerson,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isEditMode,
    editingPersonId,
    name,
    phoneNumber,
    relationshipTag,
    notes,
    nameInvalid,
    errorMessage,
    duplicateMatches,
    savedPerson,
  ];
}
