import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../domain/entities/person_balance.dart';
import '../../domain/services/repayment_preview.dart';

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
    this.balance,
    this.balanceLoaded = false,
    this.personName,
    this.preview,
    this.needsFlipConfirmation = false,
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

  /// The person's live balance, once known (022 A2).
  final PersonBalance? balance;

  /// True once both the balance and the conversion context have emitted;
  /// saving is a no-op before that.
  final bool balanceLoaded;
  final String? personName;

  /// What the typed amount would do to the balance; `null` while nothing
  /// is typed or the data has not loaded.
  final RepaymentPreview? preview;

  /// The typed amount reverses the balance and awaits the user's answer.
  final bool needsFlipConfirmation;

  bool get isSubmitting => status == RepaymentFormStatus.submitting;

  /// Reading the balance or the rates failed, so what is outstanding is
  /// unknown (022 A2). A failed save never matches: it leaves
  /// [balanceLoaded] true.
  bool get balanceLoadFailed => !balanceLoaded && failure != null;

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
    PersonBalance? balance,
    bool? balanceLoaded,
    String? personName,
    RepaymentPreview? preview,
    bool clearPreview = false,
    bool? needsFlipConfirmation,
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
      balance: balance ?? this.balance,
      balanceLoaded: balanceLoaded ?? this.balanceLoaded,
      personName: personName ?? this.personName,
      preview: clearPreview ? null : (preview ?? this.preview),
      needsFlipConfirmation:
          needsFlipConfirmation ?? this.needsFlipConfirmation,
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
    balance,
    balanceLoaded,
    personName,
    preview,
    needsFlipConfirmation,
  ];
}
