import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/confirm_email_code.dart';
import '../../domain/usecases/request_email_code.dart';
import 'email_link_state.dart';

/// 021 US6: the email and code form. Linking keeps this device's account;
/// signing in switches to an existing one. A second submit while one is
/// running is ignored (duplicate-submit guard).
@injectable
class EmailLinkCubit extends Cubit<EmailLinkState> {
  EmailLinkCubit(this._requestCode, this._confirmCode)
    : super(const EmailLinkState());

  final RequestEmailCode _requestCode;
  final ConfirmEmailCode _confirmCode;

  /// Starts over in [mode].
  void start(EmailLinkMode mode) {
    if (state.isBusy) return;
    emit(EmailLinkState(mode: mode));
  }

  Future<void> requestCode(String email) async {
    if (state.isBusy) return;
    final trimmed = email.trim();
    emit(state.copyWith(step: EmailLinkStep.sending, email: trimmed));
    final result = await _requestCode(
      trimmed,
      linkCurrent: state.mode == EmailLinkMode.link,
    );
    if (isClosed) return;
    emit(
      result.match(
        (failure) =>
            state.copyWith(step: EmailLinkStep.failure, failure: failure),
        (_) => state.copyWith(step: EmailLinkStep.codeSent, codeSent: true),
      ),
    );
  }

  Future<void> confirmCode(String code) async {
    if (state.isBusy || !state.codeSent) return;
    emit(state.copyWith(step: EmailLinkStep.verifying));
    final result = await _confirmCode(
      state.email,
      code,
      linkCurrent: state.mode == EmailLinkMode.link,
    );
    if (isClosed) return;
    emit(
      result.match(
        (failure) =>
            state.copyWith(step: EmailLinkStep.failure, failure: failure),
        // The address is no longer needed once confirmed.
        (_) => state.copyWith(step: EmailLinkStep.success, email: ''),
      ),
    );
  }
}
