import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../domain/entities/savings_contribution.dart';
import '../../domain/entities/savings_goal.dart';

enum ContributionFormStatus { loading, editing, submitting, success, failure }

/// Immutable state for `ContributionFormCubit` (constitution Principle IV).
class ContributionFormState extends Equatable {
  ContributionFormState({
    required this.idempotencyKey,
    this.status = ContributionFormStatus.loading,
    this.goalId = '',
    this.goal,
    this.availableMinorUnits = 0,
    this.isEditMode = false,
    this.editingContributionId,
    this.type = ContributionType.contribution,
    this.amountInput = '',
    this.currency = Currency.egp,
    DateTime? date,
    this.note = '',
    this.keepsStartingAmountMarker = false,
    this.amountInvalid = false,
    this.failure,
    this.saved,
  }) : date = date ?? DateTime(2000);

  /// Generated when the form opens and after each successful save, so a
  /// retried save returns the entry already logged (FR-022).
  final String idempotencyKey;
  final ContributionFormStatus status;
  final String goalId;

  /// The goal the entry belongs to: its currency is the default entered
  /// currency (FR-028), and an archived goal refuses new entries (FR-020).
  final SavingsGoal? goal;

  /// The goal's current balance, for the withdrawal form's hint.
  final int availableMinorUnits;
  final bool isEditMode;
  final String? editingContributionId;

  /// Chosen for a new entry; fixed once it exists (FR-009).
  final ContributionType type;
  final String amountInput;

  /// The currency the amount is entered in; the goal's by default.
  final Currency currency;

  /// Date-only; today by default.
  final DateTime date;
  final String note;

  /// Edit only: the entry is the goal's system "starting amount" entry,
  /// whose marker note is kept unless the user writes a note of their own.
  final bool keepsStartingAmountMarker;

  /// Set by the cubit's own "amount must be > 0" check; rendered via l10n.
  final bool amountInvalid;
  final Failure? failure;
  final SavingsContribution? saved;

  bool get isLoading => status == ContributionFormStatus.loading;
  bool get isSubmitting => status == ContributionFormStatus.submitting;
  bool get isSuccess => status == ContributionFormStatus.success;
  bool get isWithdrawal => type == ContributionType.withdrawal;

  /// A new entry on an archived goal is refused (FR-020); edits are not.
  bool get blocksNewEntry => !isEditMode && (goal?.isArchived ?? false);

  /// The amount will be converted into the goal's currency (FR-028).
  bool get needsConversion => goal != null && currency != goal!.currency;

  ContributionFormState copyWith({
    String? idempotencyKey,
    ContributionFormStatus? status,
    ContributionType? type,
    String? amountInput,
    Currency? currency,
    DateTime? date,
    String? note,
    bool? amountInvalid,
    Failure? failure,
    bool clearFailure = false,
    SavingsContribution? saved,
  }) {
    return ContributionFormState(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      goalId: goalId,
      goal: goal,
      availableMinorUnits: availableMinorUnits,
      isEditMode: isEditMode,
      editingContributionId: editingContributionId,
      type: type ?? this.type,
      amountInput: amountInput ?? this.amountInput,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      note: note ?? this.note,
      keepsStartingAmountMarker: keepsStartingAmountMarker,
      amountInvalid: amountInvalid ?? this.amountInvalid,
      failure: clearFailure ? null : (failure ?? this.failure),
      saved: saved ?? this.saved,
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    status,
    goalId,
    goal,
    availableMinorUnits,
    isEditMode,
    editingContributionId,
    type,
    amountInput,
    currency,
    date,
    note,
    keepsStartingAmountMarker,
    amountInvalid,
    failure,
    saved,
  ];
}
