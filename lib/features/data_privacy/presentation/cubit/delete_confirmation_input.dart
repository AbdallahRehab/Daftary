import 'package:equatable/equatable.dart';

/// The typed-confirmation gate's local state (data-model.md "Entity:
/// DeleteConfirmationInput", research.md Decision 8) — in-memory only,
/// never persisted.
class DeleteConfirmationInput extends Equatable {
  const DeleteConfirmationInput({
    this.typedPhrase = '',
    this.expectedPhrase = '',
  });

  /// What the user has typed so far.
  final String typedPhrase;

  /// The localized phrase the user must type (`l10n.deleteDataConfirmPhrase`).
  /// Empty until the page has supplied it, which keeps confirmation
  /// disabled rather than matching an empty field.
  final String expectedPhrase;

  /// Derived, never stored (constitution Principle IV): the destructive
  /// action unlocks only on an exact match, ignoring surrounding whitespace.
  bool get isConfirmationEnabled =>
      expectedPhrase.isNotEmpty && typedPhrase.trim() == expectedPhrase;

  DeleteConfirmationInput copyWith({
    String? typedPhrase,
    String? expectedPhrase,
  }) {
    return DeleteConfirmationInput(
      typedPhrase: typedPhrase ?? this.typedPhrase,
      expectedPhrase: expectedPhrase ?? this.expectedPhrase,
    );
  }

  @override
  List<Object?> get props => [typedPhrase, expectedPhrase];
}
