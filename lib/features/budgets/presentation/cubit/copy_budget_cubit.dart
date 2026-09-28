import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/usecases/copy_budget_to_month.dart';
import '../../domain/usecases/get_most_recent_budget_before.dart';
import 'copy_budget_state.dart';

/// Drives the copy-forward offer on a month with no budget (FR-012/FR-018).
///
/// `load(targetMonth)` resolves the most recent earlier month with a budget
/// as the copy source; `copy()` creates [CopyBudgetState.targetMonth]'s
/// budget from it. A fresh idempotency key is generated when the cubit is
/// created, and `copy()` ignores a re-entrant call while one is already in
/// flight — together that is what guarantees a rapid double-tap creates
/// exactly one budget (FR-017).
@injectable
class CopyBudgetCubit extends Cubit<CopyBudgetState> {
  CopyBudgetCubit(this._getMostRecentBudgetBefore, this._copyBudgetToMonth)
    : super(CopyBudgetState(idempotencyKey: const Uuid().v4()));

  final GetMostRecentBudgetBefore _getMostRecentBudgetBefore;
  final CopyBudgetToMonth _copyBudgetToMonth;

  /// Looks up the copy source for [targetMonth] (`'YYYY-MM'`). Call again
  /// whenever the viewed month changes.
  Future<void> load(String targetMonth) async {
    emit(
      CopyBudgetState(
        // A key belongs to one intended copy. Re-loading the same month
        // keeps it (a retry stays a retry); a different month is a
        // different copy, which must never resolve to the previous one.
        idempotencyKey: targetMonth == state.targetMonth
            ? state.idempotencyKey
            : const Uuid().v4(),
        targetMonth: targetMonth,
      ),
    );

    final result = await _getMostRecentBudgetBefore(targetMonth);
    // The month may have changed again (or the page closed) while this
    // lookup was in flight; its answer is then for a month no one is
    // looking at any more.
    if (isClosed || state.targetMonth != targetMonth) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: CopyBudgetStatus.loadFailure, failure: failure),
      ),
      (source) => emit(
        state.copyWith(
          status: CopyBudgetStatus.ready,
          source: source,
          clearSource: source == null,
        ),
      ),
    );
  }

  /// Copies the source budget into the target month. A no-op while a copy
  /// is already in flight, before the source has loaded, or when there is
  /// nothing to copy.
  Future<void> copy() async {
    if (!state.canCopy) return;
    final source = state.source!;
    final targetMonth = state.targetMonth;

    emit(state.copyWith(status: CopyBudgetStatus.copying, clearFailure: true));

    final result = await _copyBudgetToMonth(
      idempotencyKey: state.idempotencyKey,
      sourceBudgetId: source.id,
      targetMonth: targetMonth,
    );

    // The page may have been popped while the copy was in flight — the
    // mutation itself already went through exactly once above, but `emit`
    // after `close()` throws.
    if (isClosed) return;

    result.match(
      (failure) => emit(
        state.copyWith(status: CopyBudgetStatus.copyFailure, failure: failure),
      ),
      (budget) => emit(
        state.copyWith(
          // A brand-new key: the copy that just succeeded is done, so any
          // later copy from this cubit is a deliberate new action, not a
          // retry the repository should swallow.
          idempotencyKey: const Uuid().v4(),
          status: CopyBudgetStatus.success,
          copiedBudget: budget,
        ),
      ),
    );
  }
}
