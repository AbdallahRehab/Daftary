import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/savings_contribution.dart';
import '../../domain/entities/savings_failures.dart';
import '../../domain/usecases/edit_contribution.dart';
import '../../domain/usecases/get_goal_detail.dart';
import '../../domain/usecases/log_contribution.dart';
import '../../domain/usecases/log_withdrawal.dart';
import 'contribution_form_state.dart';

/// Drives the log/edit form for one contribution or withdrawal (FR-005,
/// FR-006, FR-009, FR-028).
///
/// The entered currency defaults to the goal's; any other is converted by
/// the repository at save time, and a missing rate comes back as a
/// `RatesMissingFailure` with nothing written. [submit] ignores re-entrant
/// calls and every save carries this form's idempotency key, so a rapid
/// double-tap logs exactly one entry (FR-022).
@injectable
class ContributionFormCubit extends Cubit<ContributionFormState> {
  ContributionFormCubit(
    this._getGoalDetail,
    this._logContribution,
    this._logWithdrawal,
    this._editContribution,
    this._clock,
  ) : super(ContributionFormState(idempotencyKey: const Uuid().v4()));

  final GetGoalDetail _getGoalDetail;
  final LogContribution _logContribution;
  final LogWithdrawal _logWithdrawal;
  final EditContribution _editContribution;
  final AppClock _clock;

  /// Opens the form for goal [goalId]: a new entry of [type], or — with
  /// [contributionId] — that existing entry, prefilled (FR-009). Call once,
  /// right after construction.
  Future<void> initialize({
    required String goalId,
    ContributionType type = ContributionType.contribution,
    String? contributionId,
  }) async {
    final result = await _getGoalDetail(goalId);
    if (isClosed) return;
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ContributionFormStatus.failure,
          failure: failure,
        ),
      ),
      (detail) {
        final goal = detail.goal;
        final available = detail.progress.currentAmountMinorUnits;
        if (contributionId == null) {
          final now = _clock.now();
          emit(
            ContributionFormState(
              idempotencyKey: state.idempotencyKey,
              status: ContributionFormStatus.editing,
              goalId: goal.id,
              goal: goal,
              availableMinorUnits: available,
              type: type,
              currency: goal.currency,
              date: DateTime(now.year, now.month, now.day),
            ),
          );
          return;
        }
        final entry = detail.history
            .where((e) => e.id == contributionId)
            .firstOrNull;
        if (entry == null) {
          emit(
            state.copyWith(
              status: ContributionFormStatus.failure,
              failure: const GoalNotFoundFailure('Savings entry not found'),
            ),
          );
          return;
        }
        emit(
          ContributionFormState(
            idempotencyKey: state.idempotencyKey,
            status: ContributionFormStatus.editing,
            goalId: goal.id,
            goal: goal,
            availableMinorUnits: available,
            isEditMode: true,
            editingContributionId: entry.id,
            type: entry.type,
            amountInput: CurrencyFormatter(
              currency: entry.enteredCurrency,
            ).format(entry.enteredAmount),
            currency: entry.enteredCurrency,
            date: entry.date,
            note: entry.isStartingAmount ? '' : (entry.note ?? ''),
            keepsStartingAmountMarker: entry.isStartingAmount,
          ),
        );
      },
    );
  }

  /// New entries only — a logged entry's type is fixed (FR-009).
  void typeChanged(ContributionType type) {
    if (state.isEditMode) return;
    emit(state.copyWith(type: type, clearFailure: true));
  }

  void amountChanged(String text) => emit(
    state.copyWith(amountInput: text, amountInvalid: false, clearFailure: true),
  );

  void currencyChanged(Currency currency) =>
      emit(state.copyWith(currency: currency, clearFailure: true));

  void dateChanged(DateTime date) =>
      emit(state.copyWith(date: DateTime(date.year, date.month, date.day)));

  void noteChanged(String note) => emit(state.copyWith(note: note));

  Future<void> submit() async {
    // A rapid double-tap re-enters before the first save resolves; ignoring
    // it keeps the single-flight guarantee (FR-022).
    if (state.isSubmitting || state.isLoading || state.goal == null) return;

    final Money amount;
    try {
      final text = NumeralParser.toWesternDigits(state.amountInput);
      amount = CurrencyFormatter(currency: state.currency).parse(text);
      if (!amount.isPositive) throw const FormatException('not positive');
    } on FormatException {
      emit(state.copyWith(amountInvalid: true));
      return;
    }

    emit(
      state.copyWith(
        status: ContributionFormStatus.submitting,
        clearFailure: true,
      ),
    );

    final typed = state.note.trim();
    final note = typed.isNotEmpty
        ? typed
        : (state.keepsStartingAmountMarker
              ? SavingsContribution.startingAmountNote
              : null);
    final result = state.isEditMode
        ? await _editContribution(
            contributionId: state.editingContributionId!,
            amount: amount,
            date: state.date,
            note: note,
          )
        : state.isWithdrawal
        ? await _logWithdrawal(
            idempotencyKey: state.idempotencyKey,
            goalId: state.goalId,
            amount: amount,
            date: state.date,
            note: note,
          )
        : await _logContribution(
            idempotencyKey: state.idempotencyKey,
            goalId: state.goalId,
            amount: amount,
            date: state.date,
            note: note,
          );

    if (isClosed) return;
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ContributionFormStatus.failure,
          failure: failure,
        ),
      ),
      (entry) => emit(
        state.copyWith(
          idempotencyKey: const Uuid().v4(),
          status: ContributionFormStatus.success,
          saved: entry,
        ),
      ),
    );
  }
}
