import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../domain/entities/goal_progress.dart';
import '../../domain/entities/savings_goal.dart';

enum GoalFormStatus { loading, editing, submitting, success, failure }

/// Immutable state for `GoalFormCubit` (constitution Principle IV —
/// updated exclusively via [copyWith]).
///
/// Amounts are held as the text the user typed; the cubit parses them on
/// every change for the live preview and again, strictly, on submit.
/// Validation problems are flags rather than messages so the page renders
/// them through `l10n` in the active language.
class GoalFormState extends Equatable {
  const GoalFormState({
    required this.idempotencyKey,
    this.status = GoalFormStatus.editing,
    this.isEditMode = false,
    this.editingGoalId,
    this.name = '',
    this.type,
    this.currency = Currency.egp,
    this.currencyChosenByUser = false,
    this.targetInput = '',
    this.startingInput = '',
    this.monthlyInput = '',
    this.targetDate,
    this.originalTargetDate,
    this.currentAmountMinorUnits = 0,
    this.nameInvalid = false,
    this.targetInvalid = false,
    this.startingInvalid = false,
    this.monthlyInvalid = false,
    this.targetDateInvalid = false,
    this.previewGoal,
    this.preview,
    this.failure,
    this.savedGoal,
  });

  /// Generated when the form opens (FR-022): a retried save of this form
  /// returns the goal it already created.
  final String idempotencyKey;
  final GoalFormStatus status;
  final bool isEditMode;
  final String? editingGoalId;
  final String name;

  /// A standard `SavingsGoalType` value, or `null` for no type.
  final String? type;

  /// The goal's currency: the primary currency by default, the user's pick
  /// on create, the goal's own (fixed, FR-027) on edit.
  final Currency currency;
  final bool currencyChosenByUser;
  final String targetInput;

  /// Create only: money already set aside (research.md Decision 3).
  final String startingInput;
  final String monthlyInput;
  final DateTime? targetDate;

  /// Edit only: the stored target date, which may be kept even once it has
  /// passed (FR-003 applies when a date is set).
  final DateTime? originalTargetDate;

  /// Edit only: the goal's saved amount, so the preview shows the real
  /// remaining amount.
  final int currentAmountMinorUnits;

  final bool nameInvalid;
  final bool targetInvalid;
  final bool startingInvalid;
  final bool monthlyInvalid;
  final bool targetDateInvalid;

  /// The goal as the form currently describes it, and its progress by
  /// `SavingsCalculator` — the live estimate preview. `null` until a
  /// positive target has been typed.
  final SavingsGoal? previewGoal;
  final GoalProgress? preview;
  final Failure? failure;
  final SavingsGoal? savedGoal;

  bool get isLoading => status == GoalFormStatus.loading;
  bool get isSubmitting => status == GoalFormStatus.submitting;
  bool get isSuccess => status == GoalFormStatus.success;

  GoalFormState copyWith({
    String? idempotencyKey,
    GoalFormStatus? status,
    String? name,
    String? type,
    bool clearType = false,
    Currency? currency,
    bool? currencyChosenByUser,
    String? targetInput,
    String? startingInput,
    String? monthlyInput,
    DateTime? targetDate,
    bool clearTargetDate = false,
    bool? nameInvalid,
    bool? targetInvalid,
    bool? startingInvalid,
    bool? monthlyInvalid,
    bool? targetDateInvalid,
    SavingsGoal? previewGoal,
    GoalProgress? preview,
    bool clearPreview = false,
    Failure? failure,
    bool clearFailure = false,
    SavingsGoal? savedGoal,
  }) {
    return GoalFormState(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      isEditMode: isEditMode,
      editingGoalId: editingGoalId,
      name: name ?? this.name,
      type: clearType ? null : (type ?? this.type),
      currency: currency ?? this.currency,
      currencyChosenByUser: currencyChosenByUser ?? this.currencyChosenByUser,
      targetInput: targetInput ?? this.targetInput,
      startingInput: startingInput ?? this.startingInput,
      monthlyInput: monthlyInput ?? this.monthlyInput,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      originalTargetDate: originalTargetDate,
      currentAmountMinorUnits: currentAmountMinorUnits,
      nameInvalid: nameInvalid ?? this.nameInvalid,
      targetInvalid: targetInvalid ?? this.targetInvalid,
      startingInvalid: startingInvalid ?? this.startingInvalid,
      monthlyInvalid: monthlyInvalid ?? this.monthlyInvalid,
      targetDateInvalid: targetDateInvalid ?? this.targetDateInvalid,
      previewGoal: clearPreview ? null : (previewGoal ?? this.previewGoal),
      preview: clearPreview ? null : (preview ?? this.preview),
      failure: clearFailure ? null : (failure ?? this.failure),
      savedGoal: savedGoal ?? this.savedGoal,
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    status,
    isEditMode,
    editingGoalId,
    name,
    type,
    currency,
    currencyChosenByUser,
    targetInput,
    startingInput,
    monthlyInput,
    targetDate,
    originalTargetDate,
    currentAmountMinorUnits,
    nameInvalid,
    targetInvalid,
    startingInvalid,
    monthlyInvalid,
    targetDateInvalid,
    previewGoal,
    preview,
    failure,
    savedGoal,
  ];
}
