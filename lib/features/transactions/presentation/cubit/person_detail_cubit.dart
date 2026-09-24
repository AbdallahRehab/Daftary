import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../currency/domain/usecases/get_primary_currency.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_person_balance.dart';
import '../../domain/usecases/get_person_history.dart';
import 'person_detail_state.dart';

/// Loads a person's balance + full history together (US2) and exposes a
/// single [load] entry point that other flows (repayment, edit, delete)
/// call again to refresh after a mutation (FR-014).
@injectable
class PersonDetailCubit extends Cubit<PersonDetailState> {
  PersonDetailCubit(
    this._peopleRepository,
    this._getPersonBalance,
    this._getPersonHistory,
    this._deleteTransaction,
    this._getPrimaryCurrency,
  ) : super(const PersonDetailState());

  final PeopleRepository _peopleRepository;
  final GetPersonBalance _getPersonBalance;
  final GetPersonHistory _getPersonHistory;
  final DeleteTransaction _deleteTransaction;
  final GetPrimaryCurrency _getPrimaryCurrency;

  String? _personId;

  Future<void> load(String personId) async {
    _personId = personId;
    emit(state.copyWith(status: PersonDetailStatus.loading));

    final personResult = await _peopleRepository.getPersonById(personId);
    final balanceResult = await _getPersonBalance(personId);
    final historyResult = await _getPersonHistory(personId);
    // Only decides which history rows get a currency chip — a failed read
    // keeps the previous value rather than failing the whole page.
    final primaryResult = await _getPrimaryCurrency();
    final primaryCurrency = primaryResult.match(
      (_) => state.primaryCurrency,
      (setting) => setting.currency,
    );

    final failure = personResult.isLeft()
        ? personResult
        : balanceResult.isLeft()
        ? balanceResult
        : historyResult.isLeft()
        ? historyResult
        : null;

    if (failure != null) {
      emit(
        state.copyWith(
          status: PersonDetailStatus.failure,
          errorMessage: failure.match((l) => l.message, (_) => null),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PersonDetailStatus.success,
        person: personResult.getOrElse((_) => throw StateError('unreachable')),
        balance: balanceResult.getOrElse(
          (_) => throw StateError('unreachable'),
        ),
        history: historyResult.getOrElse(
          (_) => throw StateError('unreachable'),
        ),
        primaryCurrency: primaryCurrency,
      ),
    );
  }

  /// Re-runs [load] for the currently displayed person — call after any
  /// transaction mutation so the balance/history stay in sync (FR-014).
  Future<void> refresh() {
    final personId = _personId;
    if (personId == null) return Future.value();
    return load(personId);
  }

  /// Soft-deletes [transactionId] (after the caller has already shown the
  /// "cannot be undone" confirmation, FR-016) and refreshes so the balance
  /// recalculates immediately (US6 Acceptance Scenario 2).
  Future<void> deleteTransaction(String transactionId) async {
    final result = await _deleteTransaction(transactionId);
    await result.match(
      // Deliberately keeps `status` as-is (rather than `failure`) so the
      // already-loaded balance/history stay visible; the page surfaces
      // `errorMessage` via a transient snackbar instead of a full-page error.
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (_) => refresh(),
    );
  }
}
