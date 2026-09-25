import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';

enum RepaymentFormStatus { editing, submitting, success, failure }

/// Immutable state for [RepaymentFormCubit] (constitution Principle IV).
class RepaymentFormState extends Equatable {
  RepaymentFormState({
    required this.personId,
    required this.idempotencyKey,
    this.status = RepaymentFormStatus.editing,
    DateTime? date,
    this.amountInput = '',
    this.currency = Currency.egp,
    this.currencyChosenByUser = false,
    this.note,
    this.amountInvalid = false,
    this.failure,
  }) : date = date ?? DateTime.now();

  final String personId;
  final String idempotencyKey;
  final RepaymentFormStatus status;
  final DateTime date;
  final String amountInput;

  /// The repayment's currency (018 FR-001). Replaced by the primary
  /// currency once `RepaymentFormCubit.loadDefaultCurrency` resolves.
  final Currency currency;

  /// True once the user picked a currency themselves.
  final bool currencyChosenByUser;
  final String? note;

  /// Set by this cubit's own client-side "amount must be > 0" check — a
  /// flag rather than a message so the page can render it via
  /// `l10n.amountInvalidError` regardless of locale (T105).
  final bool amountInvalid;
  final Failure? failure;

  bool get isSubmitting => status == RepaymentFormStatus.submitting;

  RepaymentFormState copyWith({
    RepaymentFormStatus? status,
    DateTime? date,
    String? amountInput,
    Currency? currency,
    bool? currencyChosenByUser,
    String? note,
    bool? amountInvalid,
    bool clearAmountError = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return RepaymentFormState(
      personId: personId,
      idempotencyKey: idempotencyKey,
      status: status ?? this.status,
      date: date ?? this.date,
      amountInput: amountInput ?? this.amountInput,
      currency: currency ?? this.currency,
      currencyChosenByUser: currencyChosenByUser ?? this.currencyChosenByUser,
      note: note ?? this.note,
      amountInvalid: clearAmountError
          ? false
          : (amountInvalid ?? this.amountInvalid),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    personId,
    idempotencyKey,
    status,
    date,
    amountInput,
    currency,
    currencyChosenByUser,
    note,
    amountInvalid,
    failure,
  ];
}
