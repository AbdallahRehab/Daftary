import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../currency/domain/usecases/get_primary_currency.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/services/savings_calculator.dart';
import '../../domain/usecases/create_savings_goal.dart';
import '../../domain/usecases/edit_savings_goal.dart';
import '../../domain/usecases/get_goal_detail.dart';
import 'goal_form_state.dart';

/// Drives the create/edit-goal form (FR-001-FR-003, FR-027, FR-029).
///
/// A fresh idempotency key is generated when the form opens, and [submit]
/// ignores a re-entrant call while one is in flight — together that is what
/// makes a rapid double-tap create exactly one goal (FR-022).
///
/// The live preview is `SavingsCalculator.progressFor` applied to the goal
/// the form currently describes — the same function the goal page's
/// figures come from, so the preview can never promise a different
/// estimate than the saved goal then shows.
@injectable
class GoalFormCubit extends Cubit<GoalFormState> {
  GoalFormCubit(
    this._createSavingsGoal,
    this._editSavingsGoal,
    this._getGoalDetail,
    this._getPrimaryCurrency,
    this._calculator,
    this._clock,
  ) : super(GoalFormState(idempotencyKey: const Uuid().v4()));

  final CreateSavingsGoal _createSavingsGoal;
  final EditSavingsGoal _editSavingsGoal;
  final GetGoalDetail _getGoalDetail;
  final GetPrimaryCurrency _getPrimaryCurrency;
  final SavingsCalculator _calculator;
  final AppClock _clock;

  /// A new goal defaults to the primary currency (FR-027); a pick the user
  /// already made is never overwritten by this late-arriving default.
  Future<void> loadDefaultCurrency() async {
    if (state.isEditMode || state.currencyChosenByUser) return;
    final result = await _getPrimaryCurrency();
    if (isClosed || state.isEditMode || state.currencyChosenByUser) return;
    result.match(
      // The placeholder default stays; the user can still pick explicitly.
      (_) {},
      (setting) => _update(state.copyWith(currency: setting.currency)),
    );
  }

  /// Switches the form into edit mode, prefilled from goal [goalId]
  /// (FR-029). Call once, right after construction.
  Future<void> loadForEdit(String goalId) async {
    emit(
      GoalFormState(
        idempotencyKey: state.idempotencyKey,
        status: GoalFormStatus.loading,
        isEditMode: true,
        editingGoalId: goalId,
      ),
    );
    final result = await _getGoalDetail(goalId);
    if (isClosed) return;
    result.match(
      (failure) => emit(
        state.copyWith(status: GoalFormStatus.failure, failure: failure),
      ),
      (detail) {
        final goal = detail.goal;
        final formatter = CurrencyFormatter(currency: goal.currency);
        final monthly = goal.monthlyContribution;
        _update(
          GoalFormState(
            idempotencyKey: state.idempotencyKey,
            isEditMode: true,
            editingGoalId: goal.id,
            name: goal.name,
            type: goal.type,
            currency: goal.currency,
            targetInput: formatter.format(goal.targetAmount),
            monthlyInput: monthly == null ? '' : formatter.format(monthly),
            targetDate: goal.targetDate,
            originalTargetDate: goal.targetDate,
            currentAmountMinorUnits: detail.progress.currentAmountMinorUnits,
          ),
        );
      },
    );
  }

  void nameChanged(String name) =>
      _update(state.copyWith(name: name, nameInvalid: false));

  /// `null` picks "no type" (a plain custom-named goal).
  void typeChanged(String? type) =>
      _update(state.copyWith(type: type, clearType: type == null));

  /// Create only — the currency is fixed once the goal exists (FR-027).
  void currencyChanged(Currency currency) {
    if (state.isEditMode) return;
    _update(state.copyWith(currency: currency, currencyChosenByUser: true));
  }

  void targetChanged(String text) =>
      _update(state.copyWith(targetInput: text, targetInvalid: false));

  void startingChanged(String text) =>
      _update(state.copyWith(startingInput: text, startingInvalid: false));

  void monthlyChanged(String text) =>
      _update(state.copyWith(monthlyInput: text, monthlyInvalid: false));

  /// `null` clears the target date.
  void targetDateChanged(DateTime? date) => _update(
    state.copyWith(
      targetDate: date,
      clearTargetDate: date == null,
      targetDateInvalid: false,
    ),
  );

  Future<void> submit() async {
    // A rapid double-tap re-enters here before the first call resolves;
    // ignoring it is what makes the single-flight guarantee hold even
    // before the UI has re-rendered (FR-022).
    if (state.isSubmitting || state.isLoading) return;

    final name = state.name.trim();
    final target = _parse(state.targetInput, state.currency);
    final starting = state.isEditMode
        ? null
        : _parse(state.startingInput, state.currency);
    final monthly = _parse(state.monthlyInput, state.currency);
    final targetDate = state.targetDate;

    final nameInvalid = name.isEmpty;
    final targetInvalid = target.value == null || target.value! <= 0;
    final startingInvalid =
        starting != null &&
        !starting.isEmpty &&
        (starting.value == null || starting.value! < 0);
    final monthlyInvalid =
        !monthly.isEmpty && (monthly.value == null || monthly.value! <= 0);
    final targetDateInvalid =
        targetDate != null &&
        !_sameDay(targetDate, state.originalTargetDate) &&
        !_dateOnly(targetDate).isAfter(_dateOnly(_clock.now()));

    if (nameInvalid ||
        targetInvalid ||
        startingInvalid ||
        monthlyInvalid ||
        targetDateInvalid) {
      emit(
        state.copyWith(
          nameInvalid: nameInvalid,
          targetInvalid: targetInvalid,
          startingInvalid: startingInvalid,
          monthlyInvalid: monthlyInvalid,
          targetDateInvalid: targetDateInvalid,
        ),
      );
      return;
    }

    emit(state.copyWith(status: GoalFormStatus.submitting, clearFailure: true));

    final result = state.isEditMode
        ? await _editSavingsGoal(
            goalId: state.editingGoalId!,
            name: name,
            type: state.type,
            targetAmountMinorUnits: target.value!,
            monthlyContributionMinorUnits: monthly.value,
            targetDate: targetDate,
          )
        : await _createSavingsGoal(
            idempotencyKey: state.idempotencyKey,
            name: name,
            type: state.type,
            currency: state.currency,
            targetAmountMinorUnits: target.value!,
            startingAmountMinorUnits: starting?.value,
            monthlyContributionMinorUnits: monthly.value,
            targetDate: targetDate,
          );

    // The page may have been popped while the save was in flight; the save
    // itself already happened exactly once.
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: GoalFormStatus.failure, failure: failure),
      ),
      (goal) => emit(
        state.copyWith(
          // The save is done: another create from this open form is a
          // deliberate second goal, not a retry to swallow.
          idempotencyKey: const Uuid().v4(),
          status: GoalFormStatus.success,
          savedGoal: goal,
        ),
      ),
    );
  }

  /// Emits [next] with its live preview recomputed.
  void _update(GoalFormState next) {
    final target = _parse(next.targetInput, next.currency).value;
    if (target == null || target <= 0) {
      emit(next.copyWith(clearPreview: true));
      return;
    }
    final monthly = _parse(next.monthlyInput, next.currency).value;
    final starting = next.isEditMode
        ? null
        : _parse(next.startingInput, next.currency).value;
    final current = next.isEditMode
        ? next.currentAmountMinorUnits
        : (starting != null && starting > 0 ? starting : 0);
    final now = _clock.now();
    final goal = SavingsGoal(
      id: next.editingGoalId ?? '',
      idempotencyKey: next.idempotencyKey,
      name: next.name,
      type: next.type,
      currency: next.currency,
      targetAmountMinorUnits: target,
      monthlyContributionMinorUnits: monthly != null && monthly > 0
          ? monthly
          : null,
      targetDate: next.targetDate,
      createdAt: now,
      updatedAt: now,
    );
    emit(
      next.copyWith(
        previewGoal: goal,
        preview: _calculator.progressFor(
          goal,
          currentAmountMinorUnits: current,
          asOf: now,
        ),
      ),
    );
  }

  /// Parses typed text into minor units of the form's currency; Arabic-Indic
  /// digits are accepted like Western ones. Empty text is "not given".
  _Parsed _parse(String input, Currency currency) {
    final text = NumeralParser.toWesternDigits(input).trim();
    if (text.isEmpty) return const _Parsed.empty();
    try {
      return _Parsed(
        CurrencyFormatter(currency: currency).parse(text).minorUnits,
      );
    } on FormatException {
      return const _Parsed(null);
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _sameDay(DateTime a, DateTime? b) =>
      b != null && a.year == b.year && a.month == b.month && a.day == b.day;
}

/// A typed amount: [isEmpty] when nothing was typed, otherwise [value] is
/// the parsed minor units or `null` when the text is not an amount.
class _Parsed {
  const _Parsed(this.value) : isEmpty = false;

  const _Parsed.empty() : value = null, isEmpty = true;

  final int? value;
  final bool isEmpty;
}
