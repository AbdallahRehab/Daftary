import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/occasion.dart';

enum OccasionFormStatus { editing, submitting, success, failure }

/// Immutable state for [OccasionFormCubit] (constitution Principle IV —
/// updated exclusively via [copyWith]).
class OccasionFormState extends Equatable {
  OccasionFormState({
    required this.idempotencyKey,
    this.status = OccasionFormStatus.editing,
    this.isEditMode = false,
    this.editingOccasionId,
    this.name = '',
    DateTime? date,
    this.type,
    this.notes,
    this.nameInvalid = false,
    this.typeInvalid = false,
    this.failure,
    this.savedOccasion,
  }) : date = date ?? DateTime.now();

  /// Generated once when the form opens and regenerated after a successful
  /// save, so a retried save resolves to the same occasion (FR-019) while a
  /// deliberate second create is never mistaken for that retry.
  final String idempotencyKey;
  final OccasionFormStatus status;
  final bool isEditMode;
  final String? editingOccasionId;
  final String name;

  /// Defaults to today; future dates are accepted for pre-planned occasions
  /// (spec Edge Cases).
  final DateTime date;

  /// A standard `OccasionType` value or a free-text custom one (FR-002).
  /// `null` until the user picks one.
  final String? type;
  final String? notes;

  /// Set by this cubit's own "name must be non-empty after trim" check
  /// (FR-001) — a flag rather than a message, so the page renders it
  /// through `l10n` regardless of locale.
  final bool nameInvalid;

  /// Set by this cubit's own "a type must be chosen" check (FR-002) — same
  /// localization rationale as [nameInvalid].
  final bool typeInvalid;

  /// The typed failure returned by the use case, kept typed rather than
  /// flattened to a string so the page decides the wording.
  final Failure? failure;
  final Occasion? savedOccasion;

  bool get isSubmitting => status == OccasionFormStatus.submitting;
  bool get isSuccess => status == OccasionFormStatus.success;

  /// Whether Save should be enabled at all — the same rule `submit()`
  /// enforces, exposed so the button can reflect it before it is tapped.
  bool get canSubmit =>
      !isSubmitting &&
      name.trim().isNotEmpty &&
      (type?.trim().isNotEmpty ?? false);

  OccasionFormState copyWith({
    String? idempotencyKey,
    OccasionFormStatus? status,
    String? name,
    DateTime? date,
    String? type,
    String? notes,
    bool? nameInvalid,
    bool clearNameError = false,
    bool? typeInvalid,
    bool clearTypeError = false,
    Failure? failure,
    bool clearFailure = false,
    Occasion? savedOccasion,
  }) {
    return OccasionFormState(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      isEditMode: isEditMode,
      editingOccasionId: editingOccasionId,
      name: name ?? this.name,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      nameInvalid: clearNameError ? false : (nameInvalid ?? this.nameInvalid),
      typeInvalid: clearTypeError ? false : (typeInvalid ?? this.typeInvalid),
      failure: clearFailure ? null : (failure ?? this.failure),
      savedOccasion: savedOccasion ?? this.savedOccasion,
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    status,
    isEditMode,
    editingOccasionId,
    name,
    date,
    type,
    notes,
    nameInvalid,
    typeInvalid,
    failure,
    savedOccasion,
  ];
}
