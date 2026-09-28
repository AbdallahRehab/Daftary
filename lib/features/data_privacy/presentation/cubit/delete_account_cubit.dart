import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../domain/usecases/delete_all_user_data.dart';
import 'delete_account_state.dart';

/// Drives `DeleteDataConfirmationPage`: the typed-phrase gate (FR-015), the
/// wipe itself, and — on success — the onboarding reset (research.md
/// Decision 6). The page reacts to [DeleteStatus.success] by navigating to
/// `/`, where the router's existing redirect sends the user to onboarding.
@injectable
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit(this._deleteAllUserData, this._onboardingCubit)
    : super(const DeleteAccountState());

  final DeleteAllUserData _deleteAllUserData;
  final OnboardingCubit _onboardingCubit;

  /// Set synchronously on entry to [confirmDelete], before any `await`, so
  /// a second tap in the same frame sees it (FR-021). Stays set after a
  /// success: there is nothing left to delete, and a second wipe would
  /// only race the navigation away from this page.
  bool _isDeleting = false;

  /// Supplies the localized phrase the user must type. Called by the page
  /// whenever its localizations change, so a language switch mid-screen
  /// re-targets the gate instead of leaving it on the old phrase.
  void setExpectedPhrase(String phrase) {
    emit(state.copyWith(input: state.input.copyWith(expectedPhrase: phrase)));
  }

  void updateTypedPhrase(String typed) {
    emit(state.copyWith(input: state.input.copyWith(typedPhrase: typed)));
  }

  Future<void> confirmDelete() async {
    if (_isDeleting || !state.canConfirm) return;
    _isDeleting = true;

    emit(state.copyWith(status: DeleteStatus.inProgress, clearFailure: true));
    final result = await _deleteAllUserData();

    await result.match(
      (failure) async {
        _isDeleting = false;
        // The wipe is one transaction: a failure means nothing was
        // removed (FR-018), which the page states explicitly.
        if (isClosed) return;
        emit(state.copyWith(status: DeleteStatus.error, failure: failure));
      },
      (_) async {
        // Re-resolved even if the page has gone away meanwhile: the data
        // is gone either way, and the app-wide gate must reflect that.
        await _onboardingCubit.initialize();
        if (isClosed) return;
        emit(state.copyWith(status: DeleteStatus.success));
      },
    );
  }
}
