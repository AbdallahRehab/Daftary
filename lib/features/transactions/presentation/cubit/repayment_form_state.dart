import 'package:equatable/equatable.dart';

enum RepaymentFormStatus { editing, submitting, success, failure }

/// Immutable state for [RepaymentFormCubit] (constitution Principle IV).
class RepaymentFormState extends Equatable {
  RepaymentFormState({
    required this.personId,
    required this.idempotencyKey,
    this.status = RepaymentFormStatus.editing,
    DateTime? date,
    this.amountInput = '',
    this.note,
    this.amountInvalid = false,
    this.errorMessage,
  }) : date = date ?? DateTime.now();

  final String personId;
  final String idempotencyKey;
  final RepaymentFormStatus status;
  final DateTime date;
  final String amountInput;
  final String? note;

  /// Set by this cubit's own client-side "amount must be > 0" check — a
  /// flag rather than a message so the page can render it via
  /// `l10n.amountInvalidError` regardless of locale (T105).
  final bool amountInvalid;
  final String? errorMessage;

  bool get isSubmitting => status == RepaymentFormStatus.submitting;

  RepaymentFormState copyWith({
    RepaymentFormStatus? status,
    DateTime? date,
    String? amountInput,
    String? note,
    bool? amountInvalid,
    bool clearAmountError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RepaymentFormState(
      personId: personId,
      idempotencyKey: idempotencyKey,
      status: status ?? this.status,
      date: date ?? this.date,
      amountInput: amountInput ?? this.amountInput,
      note: note ?? this.note,
      amountInvalid: clearAmountError
          ? false
          : (amountInvalid ?? this.amountInvalid),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    personId,
    idempotencyKey,
    status,
    date,
    amountInput,
    note,
    amountInvalid,
    errorMessage,
  ];
}
